# LibHub Deployment Guide

## Backend Deployment (Vercel)

### Step 1: GitHub Repository Setup

```bash
# Terminal mein yeh commands run karo:
cd /Users/vanshikasoni/LibHub
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/LibHub.git
git push -u origin main
```

### Step 2: Vercel Setup

1. https://vercel.com pe jao
2. GitHub se login karo
3. "Add New" → "Project" click karo
4. Apna GitHub repository select karo
5. Configure:
   - Root Directory: `backend`
   - Framework Preset: "Other"
   - Build Command: (blank)
   - Output Directory: (blank)
6. "Deploy" click karo

### Step 3: Environment Variables

Vercel dashboard → Project Settings → Environment Variables:

```
NEXT_PUBLIC_SUPABASE_URL=https://iilkumajcmsuftojisdl.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=LibHub <your-email@gmail.com>
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_T0FDfxHZBaya5Q
RAZORPAY_KEY_SECRET=your-razorpay-secret
OPENAI_API_KEY=sk-xxxxx
```

### Step 4: Update Frontend Constants

Deployment ke baad Vercel URL copy karo aur frontend mein update karo:

File: `/Users/vanshikasoni/LibHub/frontend/lib/constants.dart`

```dart
static const String backendBaseUrl = 'https://your-vercel-app.vercel.app';
```

## Frontend Deployment (Flutter)

### Option 1: Google Play Store (Android)

```bash
cd /Users/vanshikasoni/LibHub/frontend

# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

1. **Google Play Console Account:**
   - https://play.google.com/console pe jao
   - $25 (one-time) fee pay karo
   - Developer account create karo

2. **App Create:**
   - "Create app" click karo
   - App details fill karo
   - Store listing prepare karo

3. **App Upload:**
   - `build/app/outputs/bundle/release/app-release.aab` upload karo
   - Screenshots add karo
   - Privacy policy add karo
   - Submit for review

### Option 2: Apple App Store (iOS)

```bash
cd /Users/vanshikasoni/LibHub/frontend

# Build iOS
flutter build ios --release
```

1. **Apple Developer Account:**
   - $99/year fee
   - https://developer.apple.com pe jao
   - Enroll karo

2. **Xcode Setup:**
   - `ios/Runner.xcworkspace` open karo
   - Signing & Capabilities configure karo
   - Bundle identifier set karo

3. **App Store Connect:**
   - App create karo
   - Metadata fill karo
   - Submit for review

### Option 3: Web Deployment (Vercel)

```bash
cd /Users/vanshikasoni/LibHub/frontend

# Build web version
flutter build web
```

1. Vercel pe new project create karo
2. Root Directory: `frontend`
3. Framework Preset: "Other"
4. Build Command: `flutter build web`
5. Output Directory: `build/web`
6. Deploy karo

## Important Notes

1. **Supabase:** Supabase already hosted hai, kuch karna nahi
2. **Environment Variables:** Secure rakhna, kabhi share mat karo
3. **Testing:** Production deploy se pehle properly test karo
4. **Backend URL:** Frontend mein backend URL update karna mat bhoolna
