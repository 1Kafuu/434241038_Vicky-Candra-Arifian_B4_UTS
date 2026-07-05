import nodemailer from 'nodemailer';
import * as dotenv from 'dotenv';

dotenv.config({ path: require('path').resolve(__dirname, '../../.env') });

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST!,
  port: parseInt(process.env.MAIL_PORT || '2525'),
  auth: {
    user: process.env.MAIL_USERNAME!,
    pass: process.env.MAIL_PASSWORD!,
  },
});

export async function sendOtpEmail(email: string, otp: string): Promise<void> {
  console.log(`[EMAIL] Sending OTP to ${email}`);

  try {
    const info = await transporter.sendMail({
      from: `"${process.env.MAIL_FROM_NAME}" <${process.env.MAIL_FROM_ADDRESS}>`,
      to: email,
      subject: 'Reset Password OTP - E-Ticketing',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <div style="background: #003D7C; padding: 24px; text-align: center;">
            <h1 style="color: white; margin: 0;">E-Ticketing</h1>
          </div>
          <div style="padding: 32px 24px; background: #f9fafb;">
            <h2 style="color: #0A1F44; margin: 0 0 16px;">Reset Password</h2>
            <p style="color: #555; font-size: 16px;">
              Kami menerima permintaan reset password untuk akun Anda.
            </p>
            <div style="background: white; border: 2px dashed #003D7C; border-radius: 8px; padding: 24px; text-align: center; margin: 24px 0;">
              <p style="color: #757F91; font-size: 14px; margin: 0 0 8px;">Kode OTP Anda:</p>
              <p style="color: #003D7C; font-size: 36px; font-weight: bold; letter-spacing: 8px; margin: 0;">
                ${otp}
              </p>
            </div>
            <p style="color: #757F91; font-size: 13px;">
              Kode ini berlaku selama <strong>15 menit</strong>. Jangan bagikan kode ini kepada siapapun.
            </p>
          </div>
        </div>
      `,
    });

    console.log(`[EMAIL] Sent: ${info.messageId}`);
  } catch (err) {
    console.error('[EMAIL] Failed to send:', err);
    throw new Error('Failed to send email');
  }
}