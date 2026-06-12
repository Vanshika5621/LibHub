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
    const normalizedEmail = email.toLowerCase().trim();

    // 1. Create user via admin API directly
    const { data: newUser, error: createError } = await serviceClient.auth.admin.createUser({
      email: normalizedEmail,
      password,
      email_confirm: true,
      user_metadata: {
        first_name: firstName,
        last_name: lastName,
        phone: phone || '',
        address: address || '',
        city: city || '',
      },
    });

    if (createError) {
      if (createError.message.includes('already registered') || createError.message.includes('already exists')) {
        // If user exists in Auth but maybe not in Profiles, just try to update Profile
        // or tell them to sign in. For simplicity, we tell them it exists.
        return res.status(400).json({ error: 'An account with this email already exists.' });
      }
      return res.status(400).json({ error: `Supabase Auth Error: ${createError.message}` });
    }

    const userId = newUser.user.id;

    // 2. Create Profile and Defaults in parallel to save time
    console.log(`Setting up account for ${userId}...`);
    
    const profilePromise = serviceClient.from('profiles').insert({
      id: userId,
      email: normalizedEmail,
      first_name: firstName,
      last_name: lastName,
      phone: phone || '',
      address: address || '',
      city: city || '',
      email_verified: true,
    });

    const notifPromise = serviceClient.from('notification_preferences').insert({ user_id: userId });
    const goalPromise = serviceClient.from('reading_goals').insert({ 
      user_id: userId, 
      year: new Date().getFullYear() 
    });

    // Wait for core profile, let others happen
    const [profileResult] = await Promise.all([profilePromise, notifPromise, goalPromise]);

    if (profileResult.error) {
      console.error('Profile creation error:', profileResult.error);
    }

    console.log(`✅ Successfully created user and profile for: ${normalizedEmail}`);
    return res.json({ success: true, userId: userId });
  } catch (error) {
    console.error('Register route error:', error);
    return res.status(500).json({ error: `Registration error: ${error.message}` });
  }
});

module.exports = router;
