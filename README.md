# LibHub - Digital Library App

A full-featured digital library mobile application built with **Flutter**, **Supabase**, and **Razorpay**.
The backend API server runs on **Next.js**.

## Architecture

```
LibHub/
├── lib/                  ← Flutter mobile app
│   ├── main.dart         ← App entry point
│   ├── constants.dart    ← Config (Supabase URL, backend URL, Razorpay key)
│   ├── models/           ← Data models (Book, Profile, Borrow, Reserve, ...)
│   ├── services/         ← SupabaseService, PaymentService
│   ├── providers/        ← AppState (global state management)
│   ├── theme/            ← AppTheme (light & dark)
│   └── screens/
│       ├── auth/         ← Login, Register, OTP, ForgotPassword
│       └── main/         ← Home, Catalog, BookDetail, Borrowed, AIChat, Profile
├── android/              ← Android platform files
├── src/                  ← Next.js backend API server
│   ├── app/api/          ← REST API endpoints for Flutter
│   └── lib/              ← Shared utilities, Supabase client, types
├── supabase/migrations/  ← Database schema SQL files
└── pubspec.yaml          ← Flutter dependencies
```

## Features

### Authentication
- Email & password registration (name, phone, address, city)
- 4-digit OTP email verification (5 min expiry, max 3 attempts)
- JWT login via Supabase Auth
- Password reset via email

### Book Catalog
- Browse all books with grid view
- Search by title/author, filter by genre & availability
- Sort by rating or newest
- Book details with cover, description, metadata

### Borrowing & Returns
- One-click borrow with real-time inventory
- Due dates by plan (Free: 7d, Premium: 21d, VIP: 30d)
- Borrow limits (Free: 2, Premium: 5, VIP: Unlimited)
- Return, renew (max 2), overdue tracking
- Auto fine calculation (₹10/day)

### Reserve & Wishlist
- Reserve unavailable books with queue position
- Wishlist add/remove from any book

### Membership & Payments
- Free / Premium (₹299) / VIP (₹599) plans
- Razorpay integration (Card, UPI, Wallet, Net Banking)
- Payment history

### AI Assistant
- Multi-turn chat with history saved to Supabase
- FAQ & policy answers
- Book recommendations via OpenAI

### Reading Goals
- Yearly & monthly goals with progress indicators
- Reading history tracking

### Notifications
- Notification preferences (due alerts, reserve alerts, etc.)

### UI
- Premium dark & light theme
- Google Fonts (Inter)
- Glassmorphic design system

---

## Setup

### 1. Supabase
1. Create a project at [supabase.com](https://supabase.com)
2. Run migrations in order:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_seed_books.sql`
3. Copy your project URL and anon key from **Settings → API**

### 2. Environment Variables
```bash
cp .env.example .env.local
```
Fill in your values in `.env.local`.

### 3. Flutter App Configuration
Edit `lib/constants.dart`:
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
static const String backendBaseUrl = 'http://localhost:3000'; // or production URL
static const String razorpayKeyId = 'rzp_test_xxxxx';
```

### 4. Install Backend Dependencies & Run Backend Server
```bash
npm install
npm run dev
```
This runs the Next.js API server on `http://localhost:3000`.

> **Android Emulator:** Use `http://10.0.2.2:3000` instead of `localhost:3000`
> **Physical devices:** Use your computer's local IP, e.g. `http://192.168.x.x:3000`

### 5. Flutter Setup
```bash
flutter pub get
flutter run
```

### 6. Email (OTP)
For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833).
Without SMTP config, OTP is printed to the backend terminal.

### 7. Razorpay
Create a test account at [razorpay.com](https://razorpay.com) and add test API keys.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3.x, Dart |
| State Management | Provider |
| Backend API | Next.js 16 (API routes only) |
| Database | Supabase (PostgreSQL + Auth + RLS) |
| Payments | Razorpay Flutter SDK |
| Email | Nodemailer (OTP) |
| AI | OpenAI GPT-4o-mini (optional) |
| Typography | Google Fonts (Inter) |

## License

MIT
