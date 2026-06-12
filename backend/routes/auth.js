const express = require('express');
const { createServiceClient } = require('../utils/supabase');

const router = express.Router();

// POST /api/auth/register
// Uses Admin API to create user with email pre-confirmed so signIn works immediately
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, phone, address, city } = req.body;

    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ error: 'Email, password, first name and last name are required.' });
    }

    const serviceClient = createServiceClient();

    // Check if user already exists
    const { data: existingUsers } = await serviceClient.auth.admin.listUsers();
    const alreadyExists = existingUsers?.users?.some(u => u.email === email);
    if (alreadyExists) {
      return res.status(400).json({ error: 'An account with this email already exists. Please sign in.' });
    }

    // Create user via admin API - email is auto-confirmed (no confirmation email needed)
    const { data: newUser, error: createError } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // This bypasses the "Confirm email" requirement
      user_metadata: {
        first_name: firstName,
        last_name: lastName,
        phone: phone || '',
        address: address || '',
        city: city || '',
      },
    });

    if (createError) {
      console.error('Admin createUser error:', createError);
      return res.status(400).json({ error: createError.message });
    }

    return res.json({ success: true, userId: newUser.user.id });
  } catch (error) {
    console.error('Register route error:', error);
    return res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

module.exports = router;
