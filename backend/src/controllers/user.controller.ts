import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/db';
import { createError } from '../middleware/errorHandler';
import {
  User,
  UserRole,
  ListUsersQuery,
  PaginatedUsersResponse,
  CreateUserRequest,
  UpdateUserRequest,
  ProfileRow,
} from '../models/user.model';
import { mapToUser } from '../models/user.model';

const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 10;
const MAX_LIMIT = 100;

// GET /api/admin/users
export async function getUsers(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const query = req.query as unknown as ListUsersQuery;
    const page = Math.max(1, parseInt(String(query.page || DEFAULT_PAGE), 10));
    const limit = Math.min(MAX_LIMIT, Math.max(1, parseInt(String(query.limit || DEFAULT_LIMIT), 10)));
    const offset = (page - 1) * limit;
    const search = (query.search || '').trim();
    const role = query.role as UserRole | undefined;

    // Build count query
    let countQuery = supabaseAdmin.from('profiles').select('*', { count: 'exact', head: true });

    if (role) {
      countQuery = countQuery.eq('role', role);
    }
    if (search) {
      countQuery = countQuery.or(`name.ilike.%${search}%`);
    }

    const { count, error: countError } = await countQuery;
    if (countError) return next(createError(500, 'Failed to count users'));

    const total = count || 0;
    const totalPages = Math.ceil(total / limit);

    // Build data query
    let dataQuery = supabaseAdmin
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (role) {
      dataQuery = dataQuery.eq('role', role);
    }
    if (search) {
      dataQuery = dataQuery.or(`name.ilike.%${search}%`);
    }

    const { data: profiles, error: dataError } = await dataQuery;
    if (dataError) return next(createError(500, 'Failed to fetch users'));

    // Fetch auth users for email
    const userIds = (profiles as ProfileRow[]).map(p => p.id);
    const { data: authUsers, error: authError } = await supabaseAdmin.auth.admin.listUsers();
    const authUserMap = new Map(
      (authUsers?.users || [])
        .filter(u => userIds.includes(u.id))
        .map(u => [u.id, u.email || ''])
    );

    const users: User[] = (profiles as ProfileRow[]).map(profile => ({
      id: profile.id,
      email: authUserMap.get(profile.id) || '',
      name: profile.name,
      role: profile.role,
      profileImage: profile.profile_image,
      createdAt: profile.created_at,
    }));

    const response: PaginatedUsersResponse = { users, total, page, limit, totalPages };
    res.status(200).json({ success: true, data: response });
  } catch (err) {
    next(err);
  }
}

// GET /api/admin/users/:id
export async function getUserById(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { id } = req.params;

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (profileError || !profile) {
      return next(createError(404, 'User not found'));
    }

    const { data: authUsers } = await supabaseAdmin.auth.admin.listUsers();
    const authUser = authUsers?.users.find(u => u.id === id);
    const email = authUser?.email || '';

    const user: User = {
      id: profile.id,
      email,
      name: profile.name,
      role: profile.role,
      profileImage: profile.profile_image,
      createdAt: profile.created_at,
    };

    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

// POST /api/admin/users
export async function createUser(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { name, email, password, role }: CreateUserRequest = req.body;

    if (!name || !email || !password || !role) {
      return next(createError(400, 'Name, email, password, and role are required'));
    }

    if (!['admin', 'helpdesk', 'user'].includes(role)) {
      return next(createError(400, 'Invalid role'));
    }

    if (password.length < 6) {
      return next(createError(400, 'Password must be at least 6 characters'));
    }

    // Check if email already exists
    const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
    if (existingUsers?.users.some(u => u.email?.toLowerCase() === email.toLowerCase())) {
      return next(createError(400, 'Email already in use'));
    }

    // Create auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, role },
    });

    if (authError) return next(createError(400, authError.message));
    if (!authData.user) return next(createError(500, 'Failed to create user'));

    // Profile is auto-created by DB trigger, but ensure it exists
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', authData.user.id)
      .single();

    if (profileError || !profile) {
      return next(createError(500, 'Failed to fetch created profile'));
    }

    const user: User = {
      id: profile.id,
      email,
      name: profile.name,
      role: profile.role,
      profileImage: profile.profile_image,
      createdAt: profile.created_at,
    };

    res.status(201).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

// PATCH /api/admin/users/:id
export async function updateUser(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { id } = req.params;
    const { name, role }: UpdateUserRequest = req.body;

    if (!name && !role) {
      return next(createError(400, 'At least name or role must be provided'));
    }

    if (role && !['admin', 'helpdesk', 'user'].includes(role)) {
      return next(createError(400, 'Invalid role'));
    }

    // Check user exists
    const { data: existingProfile, error: fetchError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !existingProfile) {
      return next(createError(404, 'User not found'));
    }

    // Build update payload
    const updateData: { name?: string; role?: UserRole } = {};
    if (name !== undefined) updateData.name = name;
    if (role !== undefined) updateData.role = role;

    const { data: updatedProfile, error: updateError } = await supabaseAdmin
      .from('profiles')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) return next(createError(500, 'Failed to update user'));

    // Get auth user email
    const { data: authUsers } = await supabaseAdmin.auth.admin.listUsers();
    const authUser = authUsers?.users.find(u => u.id === id);
    const email = authUser?.email || '';

    const user: User = {
      id: updatedProfile.id,
      email,
      name: updatedProfile.name,
      role: updatedProfile.role,
      profileImage: updatedProfile.profile_image,
      createdAt: updatedProfile.created_at,
    };

    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/admin/users/:id
export async function deleteUser(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { id } = req.params;

    // Prevent self-deletion
    if (req.user?.id === id) {
      return next(createError(400, 'Cannot delete your own account'));
    }

    // Check user exists
    const { data: profile, error: fetchError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !profile) {
      return next(createError(404, 'User not found'));
    }

    // Delete auth user (cascades to profiles via FK)
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(id);
    if (deleteAuthError) return next(createError(500, 'Failed to delete user'));

    res.status(200).json({ success: true, message: 'User deleted successfully' });
  } catch (err) {
    next(err);
  }
}
