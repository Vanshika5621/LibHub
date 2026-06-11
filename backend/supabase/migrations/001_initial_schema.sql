-- LibHub Digital Library - Supabase Schema
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Membership tier enum
CREATE TYPE membership_tier AS ENUM ('free', 'premium', 'vip');
CREATE TYPE borrow_status AS ENUM ('active', 'returned', 'overdue');
CREATE TYPE reserve_status AS ENUM ('waiting', 'ready', 'fulfilled', 'cancelled', 'expired');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE payment_type AS ENUM ('membership', 'fine');
CREATE TYPE notification_type AS ENUM (
  'due_7_days', 'due_3_days', 'due_1_day', 'overdue',
  'reserve_ready', 'reserve_reminder', 'reserve_expiry',
  'payment_confirmation', 'membership_renewal', 'system'
);

-- Profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  phone TEXT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  membership_tier membership_tier NOT NULL DEFAULT 'free',
  membership_expires_at TIMESTAMPTZ,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- OTP Verifications (4-digit, 5 min expiry, max 3 attempts)
CREATE TABLE otp_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  max_attempts INT NOT NULL DEFAULT 3,
  expires_at TIMESTAMPTZ NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Books catalog
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  publisher TEXT,
  description TEXT,
  cover_image TEXT,
  genre TEXT NOT NULL,
  language TEXT DEFAULT 'English',
  pages INT,
  published_year INT,
  isbn TEXT,
  total_copies INT NOT NULL DEFAULT 1,
  available_copies INT NOT NULL DEFAULT 1,
  rating DECIMAL(3,2) DEFAULT 0,
  rating_count INT DEFAULT 0,
  is_trending BOOLEAN DEFAULT FALSE,
  is_new_arrival BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_books_title ON books USING gin(to_tsvector('english', title));
CREATE INDEX idx_books_author ON books USING gin(to_tsvector('english', author));
CREATE INDEX idx_books_genre ON books(genre);
CREATE INDEX idx_books_rating ON books(rating DESC);

-- Borrows
CREATE TABLE borrows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  borrowed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  due_date TIMESTAMPTZ NOT NULL,
  returned_at TIMESTAMPTZ,
  status borrow_status NOT NULL DEFAULT 'active',
  renewal_count INT NOT NULL DEFAULT 0,
  max_renewals INT NOT NULL DEFAULT 2,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_borrows_user ON borrows(user_id);
CREATE INDEX idx_borrows_status ON borrows(status);

-- Reserves / Holds
CREATE TABLE reserves (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  queue_position INT NOT NULL DEFAULT 1,
  status reserve_status NOT NULL DEFAULT 'waiting',
  estimated_date DATE,
  notified BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reserves_user ON reserves(user_id);
CREATE UNIQUE INDEX idx_reserves_active ON reserves(user_id, book_id) WHERE status IN ('waiting', 'ready');

-- Wishlist
CREATE TABLE wishlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- Fines
CREATE TABLE fines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  borrow_id UUID NOT NULL REFERENCES borrows(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  days_overdue INT NOT NULL DEFAULT 0,
  rate_per_day DECIMAL(10,2) NOT NULL DEFAULT 10.00,
  paid BOOLEAN NOT NULL DEFAULT FALSE,
  paid_at TIMESTAMPTZ,
  waived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- VIP fine waivers tracking
CREATE TABLE fine_waivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fine_id UUID NOT NULL REFERENCES fines(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  payment_type payment_type NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  membership_tier membership_tier,
  fine_id UUID REFERENCES fines(id),
  receipt_url TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Reading goals
CREATE TABLE reading_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  year INT NOT NULL,
  yearly_goal INT NOT NULL DEFAULT 12,
  monthly_goal INT NOT NULL DEFAULT 1,
  books_read_year INT NOT NULL DEFAULT 0,
  books_read_month INT NOT NULL DEFAULT 0,
  current_month INT NOT NULL DEFAULT EXTRACT(MONTH FROM NOW())::INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, year)
);

-- Reading history
CREATE TABLE reading_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  borrow_id UUID REFERENCES borrows(id),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, read);

-- Notification preferences
CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  due_alerts BOOLEAN DEFAULT TRUE,
  reserve_alerts BOOLEAN DEFAULT TRUE,
  payment_alerts BOOLEAN DEFAULT TRUE,
  system_alerts BOOLEAN DEFAULT TRUE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI Chat history
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_user ON chat_messages(user_id, created_at);

-- Membership plans reference
CREATE TABLE membership_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tier membership_tier NOT NULL UNIQUE,
  name TEXT NOT NULL,
  price_monthly DECIMAL(10,2) NOT NULL,
  borrow_limit INT,
  borrow_days INT NOT NULL,
  description TEXT,
  features JSONB
);

INSERT INTO membership_plans (tier, name, price_monthly, borrow_limit, borrow_days, description, features) VALUES
  ('free', 'Free Plan', 0, 2, 7, 'Basic library access', '["2 books at a time", "7-day borrow period", "Basic search"]'),
  ('premium', 'Premium Plan', 299, 5, 21, 'Enhanced reading experience', '["5 books at a time", "21-day borrow period", "Priority reserves", "No ads"]'),
  ('vip', 'VIP Plan', 599, NULL, 30, 'Ultimate library experience', '["Unlimited books", "30-day borrow period", "2 fine waivers/month", "AI recommendations", "Priority support"]');

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, first_name, last_name, phone, address, city)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'address',
    NEW.raw_user_meta_data->>'city'
  );
  INSERT INTO notification_preferences (user_id) VALUES (NEW.id);
  INSERT INTO reading_goals (user_id, year) VALUES (NEW.id, EXTRACT(YEAR FROM NOW())::INT);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER reading_goals_updated_at BEFORE UPDATE ON reading_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Borrow limit helper
CREATE OR REPLACE FUNCTION get_borrow_limit(tier membership_tier)
RETURNS INT AS $$
BEGIN
  RETURN CASE tier
    WHEN 'free' THEN 2
    WHEN 'premium' THEN 5
    WHEN 'vip' THEN 999999
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION get_borrow_days(tier membership_tier)
RETURNS INT AS $$
BEGIN
  RETURN CASE tier
    WHEN 'free' THEN 7
    WHEN 'premium' THEN 21
    WHEN 'vip' THEN 30
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrows ENABLE ROW LEVEL SECURITY;
ALTER TABLE reserves ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE fine_waivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_plans ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Books - public read
CREATE POLICY "Anyone can view books" ON books FOR SELECT USING (true);

-- Borrows
CREATE POLICY "Users can view own borrows" ON borrows FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own borrows" ON borrows FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own borrows" ON borrows FOR UPDATE USING (auth.uid() = user_id);

-- Reserves
CREATE POLICY "Users can manage own reserves" ON reserves FOR ALL USING (auth.uid() = user_id);

-- Wishlist
CREATE POLICY "Users can manage own wishlist" ON wishlist FOR ALL USING (auth.uid() = user_id);

-- Fines
CREATE POLICY "Users can view own fines" ON fines FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own fines" ON fines FOR UPDATE USING (auth.uid() = user_id);

-- Payments
CREATE POLICY "Users can view own payments" ON payments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own payments" ON payments FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Reading goals & history
CREATE POLICY "Users can manage own goals" ON reading_goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own history" ON reading_history FOR ALL USING (auth.uid() = user_id);

-- Notifications
CREATE POLICY "Users can manage own notifications" ON notifications FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own preferences" ON notification_preferences FOR ALL USING (auth.uid() = user_id);

-- Chat
CREATE POLICY "Users can manage own chat" ON chat_messages FOR ALL USING (auth.uid() = user_id);

-- Membership plans - public read
CREATE POLICY "Anyone can view plans" ON membership_plans FOR SELECT USING (true);

-- OTP - service role only (handled via API)
CREATE POLICY "Users can view own otp" ON otp_verifications FOR SELECT USING (auth.uid() = user_id);
