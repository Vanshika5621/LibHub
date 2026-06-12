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

    // 1. Check if user already exists in Auth
    const { data: existingUsers, error: listError } = await serviceClient.auth.admin.listUsers();
    if (listError) {
      console.error('List users error:', listError);
    }

    const existingUser = existingUsers?.users?.find(u => u.email?.toLowerCase() === normalizedEmail);
    
    if (existingUser) {
      // Check if they have a profile
      const { data: profile } = await serviceClient
        .from('profiles')
        .select('id')
        .eq('id', existingUser.id)
        .maybeSingle();

      if (profile) {
        return res.status(400).json({ error: 'An account with this email already exists. Please sign in.' });
      } else {
        // User exists in Auth but has no Profile (partial registration from previous failure)
        console.log(`Cleaning up ghost user for ${normalizedEmail}...`);
        await serviceClient.auth.admin.deleteUser(existingUser.id);
        // Wait 1 second for deletion to propagate
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    // 2. Create user via admin API
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
      console.error('Admin createUser error:', createError);
      if (createError.message.includes('already registered') || createError.message.includes('already exists')) {
        return res.status(400).json({ error: 'An account with this email already exists and is fully verified.' });
      }
      return res.status(400).json({ error: `Supabase Auth Error: ${createError.message}` });
    }

    const userId = newUser.user.id;

    // 3. Manually Create Profile (since we disabled the DB trigger for debugging)
    console.log(`Creating profile for ${userId}...`);
    const { error: profileError } = await serviceClient
      .from('profiles')
      .insert({
        id: userId,
        email: normalizedEmail,
        first_name: firstName,
        last_name: lastName,
        phone: phone || '',
        address: address || '',
        city: city || '',
        email_verified: true,
      });

    if (profileError) {
      console.error('Manual profile creation error:', profileError);
    }

    // 4. Create other defaults (in background, but with proper safety)
    try {
      await serviceClient.from('notification_preferences').insert({ user_id: userId });
      await serviceClient.from('reading_goals').insert({ 
        user_id: userId, 
        year: new Date().getFullYear() 
      });
    } catch (err) {
      console.warn('Silent warning creating default user settings:', err.message);
    }

    console.log(`✅ Successfully created user and profile for: ${normalizedEmail}`);
    return res.json({ success: true, userId: userId });
  } catch (error) {
    console.error('Register route error:', error);
    return res.status(500).json({ error: `Registration error: ${error.message}` });
  }
});

module.exports = router;
