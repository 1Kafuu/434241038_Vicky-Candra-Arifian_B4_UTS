import { Request, Response, NextFunction } from 'express';
import { supabase, supabaseAdmin } from '../config/db';
import { createError } from '../middleware/errorHandler';
import { sendOtpEmail } from '../config/email';
import {
  LoginRequest,
  RegisterRequest,
  ForgotPasswordRequest,
  VerifyOtpRequest,
  ResetPasswordRequest,
  mapToUser,
  ProfileRow,
  PasswordResetOtpRow,
} from '../models/user.model';

// ─── OTP Helper ────────────────────────────────────────────────────────────────
function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ─── Forgot Password — Send OTP ────────────────────────────────────────────────
// POST /api/auth/forgot-password
export async function forgotPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email }: ForgotPasswordRequest = req.body;

    if (!email) {
      return next(createError(400, 'Email is required'));
    }

    // Check if user exists in Supabase Auth
    const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
    
    if (listError) {
      console.error('[AUTH] listUsers error:', listError);
      return next(createError(500, 'Failed to verify user'));
    }

    const user = users?.users.find(u => u.email?.toLowerCase() === email.toLowerCase());

    if (!user) {
      res.status(200).json({
        success: true,
        message: 'If that email exists, an OTP has been sent',
      });
      return;
    }

    // Generate 6-digit OTP
    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

    console.log(`[AUTH] OTP untuk ${email}: ${otp}`);

    // Store OTP in database
    await supabaseAdmin
      .from('password_reset_otps')
      .insert([{ email, otp, expires_at: expiresAt }]);

    // Send via Mailtrap
    await sendOtpEmail(email, otp);

    res.status(200).json({
      success: true,
      message: 'OTP sent to email',
      data: { email },
    });
  } catch (err) {
    next(err);
  }
}

// ─── Verify OTP ────────────────────────────────────────────────────────────────
// POST /api/auth/verify-otp
export async function verifyOtp(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, otp }: VerifyOtpRequest = req.body;

    if (!email || !otp) {
      return next(createError(400, 'Email and OTP are required'));
    }

    const { data: record, error } = await supabaseAdmin
      .from('password_reset_otps')
      .select('*')
      .eq('email', email)
      .eq('otp', otp)
      .is('used_at', null)
      .gte('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (error || !record) {
      return next(createError(400, 'Invalid or expired OTP'));
    }

    res.status(200).json({
      success: true,
      message: 'OTP verified',
      data: { email, verified: true },
    });
  } catch (err) {
    next(err);
  }
}

// ─── Reset Password — Uses Supabase updateUserById ─────────────────────────────
// POST /api/auth/reset-password
export async function resetPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, otp, newPassword }: ResetPasswordRequest = req.body;

    if (!email || !otp || !newPassword) {
      return next(createError(400, 'Email, OTP, and new password are required'));
    }

    if (newPassword.length < 6) {
      return next(createError(400, 'Password must be at least 6 characters'));
    }

    // Verify OTP from database
    const { data: record, error } = await supabaseAdmin
      .from('password_reset_otps')
      .select('*')
      .eq('email', email)
      .eq('otp', otp)
      .is('used_at', null)
      .gte('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (error || !record) {
      return next(createError(400, 'Invalid or expired OTP'));
    }

    // Get user from Supabase Auth
    const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
    
    if (listError) {
      console.error('[AUTH] listUsers error:', listError);
      return next(createError(500, 'Failed to find user'));
    }

    const user = users?.users.find(u => u.email?.toLowerCase() === email.toLowerCase());

    if (!user) {
      return next(createError(500, 'User not found'));
    }

    // Use Supabase built-in updateUserById for password reset (architecture consistency)
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user.id, {
      password: newPassword,
    });

    if (updateError) {
      console.error('[AUTH] updateUserById error:', updateError);
      return next(createError(500, 'Failed to update password'));
    }

    // Mark OTP as used
    await supabaseAdmin
      .from('password_reset_otps')
      .update({ used_at: new Date().toISOString() })
      .eq('id', (record as PasswordResetOtpRow).id);

    res.status(200).json({
      success: true,
      message: 'Password updated successfully',
    });
  } catch (err) {
    next(err);
  }
}

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
        data: { name, role },
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

// ─── Login ─────────────────────────────────────────────────────────────────────
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

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) return next(createError(401, 'Invalid email or password'));
    if (!data.user || !data.session) {
      return next(createError(401, 'Login failed'));
    }

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
// GET /api/auth/me (protected)
export async function me(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
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
// POST /api/auth/logout (protected)
export async function logout(
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
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

// ─── Helpdesks ────────────────────────────────────────────────────────────────
// GET /api/auth/helpdesks (protected)
export async function getHelpdesks(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { data: profiles, error } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('role', 'helpdesk');

    if (error) return next(createError(500, error.message));

    const helpdesks = (profiles as ProfileRow[]).map(profile => ({
      id: profile.id,
      name: profile.name,
      role: profile.role,
      profileImage: profile.profile_image,
      createdAt: profile.created_at,
    }));

    res.status(200).json({
      success: true,
      data: helpdesks,
    });
  } catch (err) {
    next(err);
  }
}
