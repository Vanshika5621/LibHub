const express = require('express');
const { createServiceClient, requireAuth } = require('../utils/supabase');
const { generateOTP } = require('../utils/helpers');
const { sendOTPEmail } = require('../utils/email');

const router = express.Router();
const OTP_EXPIRY_MINUTES = 5;

// POST /api/otp/send
router.post('/send', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const serviceClient = createServiceClient();

    // Check if user exists
    const { data: existingUsers } = await serviceClient.auth.admin.listUsers();
    const user = existingUsers?.users?.find(u => u.email === email);

    if (!user) {
      return res.status(400).json({ error: 'No account found with this email. Please register first.' });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

    // Delete existing OTPs
    await serviceClient.from('otp_verifications').delete().eq('user_id', user.id);

    const { error: insertError } = await serviceClient.from('otp_verifications').insert({
      user_id: user.id,
      email: user.email,
      otp_code: otp,
      expires_at: expiresAt.toISOString(),
      attempts: 0,
      max_attempts: 3,
    });

    if (insertError) {
      return res.status(500).json({ error: insertError.message });
    }

    const firstName = user.user_metadata?.first_name || 'User';

    if (process.env.SMTP_USER && process.env.SMTP_PASS) {
      await sendOTPEmail(user.email, otp, firstName);
    } else {
      console.log(`[DEV] OTP for ${user.email}: ${otp}`);
    }

    return res.json({ success: true, message: 'OTP sent to your email' });
  } catch (error) {
    console.error('OTP send error:', error);
    return res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// POST /api/otp/verify
router.post('/verify', async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ error: 'Email and OTP are required' });
    }

    if (typeof otp !== 'string' || otp.length !== 4) {
      return res.status(400).json({ error: 'Invalid OTP format. Must be 4 digits.' });
    }

    const serviceClient = createServiceClient();

    // Check if user exists
    const { data: existingUsers } = await serviceClient.auth.admin.listUsers();
    const user = existingUsers?.users?.find(u => u.email === email);

    if (!user) {
      return res.status(400).json({ error: 'No account found with this email. Please register first.' });
    }

    const { data: record, error: fetchError } = await serviceClient
      .from('otp_verifications')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (fetchError || !record) {
      return res.status(400).json({ error: 'No OTP requested or OTP expired' });
    }

    if (new Date(record.expires_at) < new Date()) {
      await serviceClient.from('otp_verifications').delete().eq('user_id', user.id);
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (record.attempts >= record.max_attempts) {
      await serviceClient.from('otp_verifications').delete().eq('user_id', user.id);
      return res.status(400).json({ error: 'Maximum attempts reached. Request a new OTP.' });
    }

    if (record.otp_code !== otp) {
      await serviceClient
        .from('otp_verifications')
        .update({ attempts: record.attempts + 1 })
        .eq('id', record.id);
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Success! Update auth user
    const { error: updateError } = await serviceClient.auth.admin.updateUserById(user.id, {
      user_metadata: { email_verified: true }
    });

    if (updateError) {
      return res.status(500).json({ error: 'Failed to update user status' });
    }

    // Delete OTP record
    await serviceClient.from('otp_verifications').delete().eq('user_id', user.id);

    return res.json({ success: true, message: 'Email verified successfully' });
  } catch (error) {
    console.error('OTP verify error:', error);
    return res.status(500).json({ error: 'Failed to verify OTP' });
  }
});

module.exports = router;
