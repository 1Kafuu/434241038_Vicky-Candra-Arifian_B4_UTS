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
