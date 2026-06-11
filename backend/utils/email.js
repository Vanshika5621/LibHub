const nodemailer = require('nodemailer');

async function sendOTPEmail(to, otp, name) {
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  await transporter.sendMail({
    from: `"LibHub" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
    to,
    subject: 'LibHub - Email Verification OTP',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
        <h2 style="color: #4F46E5;">LibHub Email Verification</h2>
        <p>Hi ${name || 'User'},</p>
        <p>Your 4-digit verification code is:</p>
        <div style="background: #F3F4F6; padding: 16px; text-align: center; border-radius: 12px; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #4F46E5;">
          ${otp}
        </div>
        <p style="color: #6B7280; font-size: 14px;">This code expires in 5 minutes. Max 3 attempts allowed.</p>
        <p style="color: #6B7280; font-size: 12px;">If you didn't request this, please ignore this email.</p>
      </div>
    `,
  });
}

module.exports = {
  sendOTPEmail
};
