import { Request, Response, NextFunction } from 'express';
import { supabase, supabaseAdmin } from '../config/db';
import { createError } from './errorHandler';
import { User } from '../models/user.model';

// Extend Express Request to include the authenticated user
declare global {
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}

export async function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // 1. Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(createError(401, 'No token provided'));
    }

    const token = authHeader.split(' ')[1];

    // 2. Verify token with Supabase
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data.user) {
      return next(createError(401, 'Invalid or expired token'));
    }

    // 3. Fetch user profile to get name and role
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (profileError || !profile) {
      return next(createError(401, 'User profile not found'));
    }

    // 4. Attach user to request so controllers can access it
    req.user = {
      id: data.user.id,
      email: data.user.email!,
      name: profile.name,
      role: profile.role,
      profileImage: profile.profile_image,
      createdAt: profile.created_at,
    };

    next();
  } catch (err) {
    next(createError(500, 'Authentication error'));
  }
}

// Role guard — use after authMiddleware
// Usage: router.delete('/:id', authMiddleware, requireRole('admin'), controller)
export function requireRole(...roles: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(createError(403, 'Forbidden: insufficient permissions'));
    }
    next();
  };
}
