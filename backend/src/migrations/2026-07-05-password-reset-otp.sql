-- Password Reset OTP table for forgot password flow
-- OTP sent to email, verified, then used to reset password

CREATE TABLE IF NOT EXISTS password_reset_otps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  otp TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT email_unique_pending CHECK (email IS NOT NULL)
);

-- Index for fast lookup during verification
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_email ON password_reset_otps(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_otp ON password_reset_otps(otp);

-- Auto-delete expired OTPs older than 24 hours (run periodically via cron or pg_cron)
-- Or add a cleanup function:
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
  DELETE FROM password_reset_otps WHERE expires_at < NOW() OR used_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;
