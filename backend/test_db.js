require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing Supabase URL or Anon Key in backend/.env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkBooks() {
  console.log('Fetching books from Supabase:', supabaseUrl);
  try {
    const { data, error } = await supabase.from('books').select('*');
    if (error) {
      console.error('❌ Error fetching books:', error);
    } else {
      console.log('✅ Books fetched successfully. Count:', data.length);
      if (data.length > 0) {
        console.log('First book title:', data[0].title);
      } else {
        console.log('⚠️ No books found in the "books" table.');
      }
    }
  } catch (err) {
    console.error('❌ Unexpected exception:', err);
  }
}

checkBooks();
