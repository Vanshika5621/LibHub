const { createClient } = require('@supabase/supabase-js');

function createServiceClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Missing Supabase URL or Key. Please check your .env file.');
  }

  return createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
}

// Function to create a client authenticated with the user's JWT
function createAuthClient(req) {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Missing Supabase URL or Anon Key. Please check your .env file.');
  }

  // Get the auth header (Bearer token)
  const authHeader = req.headers.authorization;
  
  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: authHeader ? { Authorization: authHeader } : {},
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });

  return client;
}

// Middleware to extract user from the JWT token
async function requireAuth(req, res, next) {
  const supabase = createAuthClient(req);
  
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    
    if (error || !user) {
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }
    
    // Attach user to request object
    req.user = user;
    req.supabase = supabase;
    next();
  } catch (error) {
    console.error('Auth error:', error);
    return res.status(401).json({ error: 'Unauthorized: Authentication failed' });
  }
}

module.exports = {
  createServiceClient,
  createAuthClient,
  requireAuth
};
