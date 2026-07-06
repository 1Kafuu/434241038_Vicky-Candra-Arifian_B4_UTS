// Mirrors Flutter's UserRole enum
export type UserRole = 'admin' | 'helpdesk' | 'user';

// Mirrors Flutter's UserEntity
export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  profileImage?: string | null;
  createdAt?: string;
}

// Shape of the profiles table row in Supabase
export interface ProfileRow {
  id: string;
  name: string;
  role: UserRole;
  profile_image: string | null;
  created_at: string;
}

// What we return to Flutter after login/register/me
export interface AuthResponse {
  token: string;
  user: User;
}

// Request body for POST /api/auth/register
export interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  role?: UserRole; // optional, defaults to 'user'
}

// Request body for POST /api/auth/login
export interface LoginRequest {
  email: string;
  password: string;
}

// Request body for POST /api/auth/forgot-password (send OTP)
export interface ForgotPasswordRequest {
  email: string;
}

// Request body for POST /api/auth/verify-otp
export interface VerifyOtpRequest {
  email: string;
  otp: string;
}

// Request body for POST /api/auth/reset-password
export interface ResetPasswordRequest {
  email: string;
  otp: string;
  newPassword: string;
}

// Row shape of password_reset_otps table
export interface PasswordResetOtpRow {
  id: string;
  email: string;
  otp: string;
  expires_at: string;
  used_at: string | null;
  created_at: string;
}

// Helper — maps a Supabase auth user + profile row to our User interface
export function mapToUser(
  id: string,
  email: string,
  profile: ProfileRow
): User {
  return {
    id,
    email,
    name: profile.name,
    role: profile.role,
    profileImage: profile.profile_image,
    createdAt: profile.created_at,
  };
}

// Query params for GET /api/admin/users
export interface ListUsersQuery {
  page?: number;
  limit?: number;
  search?: string;
  role?: UserRole;
}

// Paginated response shape
export interface PaginatedUsersResponse {
  users: User[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Request body for POST /api/admin/users
export interface CreateUserRequest {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

// Request body for PATCH /api/admin/users/:id
export interface UpdateUserRequest {
  name?: string;
  role?: UserRole;
}
