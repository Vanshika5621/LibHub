require('dotenv').config({ path: '.env.local' });
require('dotenv').config(); // Fallback to .env

const express = require('express');
const cors = require('cors');

const otpRoutes = require('./routes/otp');
const booksRoutes = require('./routes/books');
const razorpayRoutes = require('./routes/razorpay');
const aiRoutes = require('./routes/ai');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Basic health check route
app.get('/', (req, res) => {
  res.json({ message: 'LibHub Node.js API is running smoothly!' });
});

// Register routes
app.use('/api/otp', otpRoutes);
app.use('/api/books', booksRoutes);
app.use('/api/razorpay', razorpayRoutes);
app.use('/api/ai', aiRoutes);

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong on the server!' });
});

app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
});
