const express = require('express');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { requireAuth, createServiceClient } = require('../utils/supabase');

const router = express.Router();

let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
}

// POST /api/razorpay/create-order
router.post('/create-order', requireAuth, async (req, res) => {
  try {
    if (!razorpay) {
      return res.status(500).json({ error: 'Razorpay is not configured' });
    }

    const { amount, purpose, metadata } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid amount is required' });
    }

    const options = {
      amount: Math.round(amount * 100), // convert to paise
      currency: 'INR',
      receipt: `rcpt_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
      notes: {
        userId: req.user.id,
        purpose: purpose || 'general',
        ...metadata,
      },
    };

    const order = await razorpay.orders.create(options);
    
    return res.json({ 
      success: true, 
      orderId: order.id,
      amount: order.amount,
      currency: order.currency
    });
  } catch (error) {
    console.error('Razorpay create error:', error);
    return res.status(500).json({ error: 'Failed to create payment order' });
  }
});

// POST /api/razorpay/verify
router.post('/verify', requireAuth, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, amount, purpose, metadata } = req.body;
    const user = req.user;

    // Verify signature
    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(body.toString())
      .digest("hex");

    const isAuthentic = expectedSignature === razorpay_signature;

    if (!isAuthentic) {
      return res.status(400).json({ error: 'Payment signature verification failed' });
    }

    const serviceClient = createServiceClient();

    // Record payment
    const { data: payment, error: paymentError } = await serviceClient
      .from('payments')
      .insert({
        user_id: user.id,
        amount: amount,
        payment_method: 'razorpay',
        transaction_id: razorpay_payment_id,
        purpose: purpose,
        status: 'completed'
      })
      .select()
      .single();

    if (paymentError) return res.status(500).json({ error: 'Payment verified but failed to record' });

    // Handle specific purposes
    if (purpose === 'membership_upgrade' && metadata?.tier) {
      await serviceClient
        .from('profiles')
        .update({ membership_tier: metadata.tier })
        .eq('id', user.id);
    } else if (purpose === 'fine_payment' && metadata?.fineId) {
      await serviceClient
        .from('fines')
        .update({ status: 'paid', payment_id: payment.id })
        .eq('id', metadata.fineId);
    }

    return res.json({ success: true, payment });
  } catch (error) {
    console.error('Razorpay verify error:', error);
    return res.status(500).json({ error: 'Failed to verify payment' });
  }
});

module.exports = router;
