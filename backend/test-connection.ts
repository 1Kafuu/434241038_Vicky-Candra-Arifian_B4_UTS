import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_ANON_KEY!;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
  console.log('🔄 Testing Supabase connection...');
  console.log(`   URL: ${supabaseUrl}`);

  const { data, error } = await supabase.auth.getSession();

  if (error) {
    console.error('❌ Connection failed:', error.message);
    process.exit(1);
  }

  console.log('✅ Supabase connected successfully!');
  console.log('   Session:', data.session ?? 'No active session (expected)');
}

testConnection();
