import { Request, Response, NextFunction } from 'express';
import { supabase, supabaseAdmin } from '../config/db';
import { createError } from '../middleware/errorHandler';
import {
  LoginRequest,
  RegisterRequest,
  mapToUser,
  ProfileRow,
} from '../models/user.model';

// ─── Register ─────────────────────────────────────────────────────────────────
// POST /api/auth/register
export async function register(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { name, email, password, role = 'user' }: RegisterRequest = req.body;

    if (!name || !email || !password) {
      return next(createError(400, 'Name, email and password are required'));
    }

    // 1. Create user in Supabase Auth
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { name, role }, // passed to the trigger that creates the profile row
      },
    });

    if (error) return next(createError(400, error.message));
    if (!data.user) return next(createError(400, 'Registration failed'));

    // 2. Fetch the auto-created profile (created by DB trigger)
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (profileError || !profile) {
      return next(createError(500, 'Failed to fetch user profile'));
    }

    const user = mapToUser(data.user.id, email, profile as ProfileRow);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        token: data.session?.access_token ?? null,
        user,
      },
    });
  } catch (err) {
    next(err);
  }
}

// ─── Login ────────────────────────────────────────────────────────────────────
// POST /api/auth/login
export async function login(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, password }: LoginRequest = req.body;

    if (!email || !password) {
      return next(createError(400, 'Email and password are required'));
    }

    // 1. Sign in with Supabase Auth
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) return next(createError(401, 'Invalid email or password'));
    if (!data.user || !data.session) {
      return next(createError(401, 'Login failed'));
    }

    // 2. Fetch profile to get name and role
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (profileError || !profile) {
      return next(createError(500, 'Failed to fetch user profile'));
    }

    const user = mapToUser(data.user.id, email, profile as ProfileRow);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token: data.session.access_token,
        user,
      },
    });
  } catch (err) {
    next(err);
  }
}

// ─── Me ───────────────────────────────────────────────────────────────────────
// GET /api/auth/me  (protected)
export async function me(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // req.user is already set by authMiddleware
    if (!req.user) {
      return next(createError(401, 'Not authenticated'));
    }

    res.status(200).json({
      success: true,
      data: { user: req.user },
    });
  } catch (err) {
    next(err);
  }
}

// ─── Logout ───────────────────────────────────────────────────────────────────
// POST /api/auth/logout  (protected)
export async function logout(
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // Supabase JWT is stateless — client just discards the token
    // signOut() here invalidates the refresh token server-side
    const { error } = await supabase.auth.signOut();

    if (error) return next(createError(500, error.message));

    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (err) {
    next(err);
  }
}
