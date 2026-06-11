class AppConstants {
  // Supabase Configuration
  // If running on local emulator, update URL/Key accordingly.
  static const String supabaseUrl = 'https://iilkumajcmsuftojisdl.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpbGt1bWFqY21zdWZ0b2ppc2RsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MjYwNTIsImV4cCI6MjA5NjUwMjA1Mn0.lzfpzBe2eNkIbUFqDajj8d1kcCgH7AIkKcf5lfHQFwA';
  // Backend API URL (Next.js server)
  // For iOS Simulator: http://localhost:3000
  // For Android Emulator: http://10.0.2.2:3000
  // For real devices: http://<your-computer-ip>:3000 or production URL
  static const String backendBaseUrl = 'http://10.0.2.2:3000';

  // Razorpay Test Key
  static const String razorpayKeyId = 'rzp_test_T0FDfxHZBaya5Q';
}
