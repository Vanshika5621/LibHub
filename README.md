# LibHub - Digital Library App 📚

A premium, full-featured digital library mobile application built with **Flutter**, **Node.js (Express)**, **Supabase**, and **Razorpay**.

## 🏗️ Architecture

```
LibHub/
├── frontend/             ← Flutter mobile application
│   ├── lib/
│   │   ├── main.dart     ← App entry point
│   │   ├── constants.dart ← Production URLs & Keys
│   │   ├── models/       ← Book, Profile, Borrow models
│   │   ├── services/     ← Supabase & Payment services
│   │   └── screens/      ← Auth & Library interfaces
├── backend/              ← Node.js Express API Server (Deployed on Vercel)
│   ├── routes/           ← Auth, Books, AI, Razorpay endpoints
│   ├── utils/            ← Supabase Admin client
│   └── server.js         ← Main server entry point
├── supabase/
│   └── migrations/       ← Database schema & RLS policies
└── README.md
```

## 🌟 Key Features

### 🔐 Authentication & Security
- **Admin-level Registration**: Custom Node.js flow to handle instant user verification.
- **Role-Based Access**: Free, Premium, and VIP membership tiers.
- **Secure Auth**: Powered by Supabase Auth with JWT.
- **Row Level Security (RLS)**: Database-level protection for user data.

### 📚 Library Catalog
- **Smart Search**: Real-time filtering by genre, author, and availability.
- **Real-time Inventory**: Borrow/Return/Reserve logic with instant updates.
- **Premium UI**: Glassmorphic design with support for Dark & Light modes.

### 🤖 AI Assistant
- **AI Librarian**: Powered by OpenAI (via Node.js backend) for book recommendations.
- **Chat History**: Full multi-turn conversation history saved to the cloud.

### 💳 Payments & Goals
- **Razorpay Integration**: Native payment gateway for membership upgrades and fine payments.
- **Reading Goals**: Track your yearly and monthly reading progress visually.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter (Dart) |
| **State Management** | Provider |
| **Backend API** | Node.js (Express) |
| **hosting** | Vercel |
| **Database/Auth** | Supabase (PostgreSQL) |
| **Payments** | Razorpay SDK |
| **AI Engine** | OpenAI API |

---

## 🚀 Deployment Status

- **API Server**: Live on Vercel (`https://lib-hub-one.vercel.app`)
- **Database**: Live on Supabase
- **App**: Flutter Production Build (APK available in Releases)

## 📄 License
MIT License - Created with ❤️ by Vanshika
