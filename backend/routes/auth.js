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

    // 2. IMPORTANT: Return response IMMEDIATELY so the user doesn't wait
    console.log(`🚀 Returning immediate success for: ${normalizedEmail}`);
    res.json({ success: true, userId: userId });

    // 3. Setup everything else in the background (Async)
    (async () => {
      try {
        console.log(`🛠️ Setting up background data for ${userId}...`);
        
        await Promise.all([
          serviceClient.from('profiles').insert({
            id: userId,
            email: normalizedEmail,
            first_name: firstName,
            last_name: lastName,
            phone: phone || '',
            address: address || '',
            city: city || '',
            email_verified: true,
          }),
          serviceClient.from('notification_preferences').insert({ user_id: userId }),
          serviceClient.from('reading_goals').insert({ 
            user_id: userId, 
            year: new Date().getFullYear() 
          })
        ]);
        
        console.log(`✅ Background setup complete for: ${normalizedEmail}`);
      } catch (err) {
        console.error('❌ Background setup error:', err);
      }
    })();

  } catch (error) {
    console.error('Register route error:', error);
    if (!res.headersSent) {
      return res.status(500).json({ error: `Registration error: ${error.message}` });
    }
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const serviceClient = createServiceClient();
    const { data, error } = await serviceClient.auth.signInWithPassword({
      email: email.toLowerCase().trim(),
      password,
    });

    if (error) {
      return res.status(401).json({ error: error.message });
    }

    return res.json({
      success: true,
      session: data.session,
      user: data.user,
    });
  } catch (error) {
    console.error('Login route error:', error);
    return res.status(500).json({ error: 'Internal server error during login.' });
  }
});

module.exports = router;
