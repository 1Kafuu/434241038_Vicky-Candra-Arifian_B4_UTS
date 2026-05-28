import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
  throw new Error('Missing Supabase environment variables. Check your .env file.');
}

// Regular client — uses anon key, respects RLS policies
export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Admin client — uses service role key, bypasses RLS
// Only use this for server-side operations that need elevated access
// e.g. creating users with custom roles, reading all tickets as admin
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);
