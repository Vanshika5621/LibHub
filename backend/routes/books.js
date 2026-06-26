const express = require('express');
const { requireAuth, createServiceClient } = require('../utils/supabase');
const { getBorrowLimit, calculateDueDate, calculateFine, FINE_RATE_PER_DAY } = require('../utils/helpers');

const router = express.Router();

// POST /api/books/borrow
router.post('/borrow', requireAuth, async (req, res) => {
  try {
    const { bookId } = req.body;
    if (!bookId) return res.status(400).json({ error: 'Book ID is required' });

    const user = req.user;
    const supabase = req.supabase;
    const serviceClient = createServiceClient();

    // 1. Get user profile (for membership tier)
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('membership_tier')
      .eq('id', user.id)
      .single();

    if (profileError) return res.status(500).json({ error: 'Failed to fetch profile' });
    const membershipTier = profile.membership_tier;
    const borrowLimit = getBorrowLimit(membershipTier);

    // 2. Check current active borrows
    const { count: activeBorrows, error: countError } = await supabase
      .from('borrows')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .is('returned_at', null);

    if (countError) return res.status(500).json({ error: 'Failed to check active borrows' });
    if (activeBorrows !== null && activeBorrows >= borrowLimit) {
      return res.status(400).json({ error: `Borrow limit reached for your ${membershipTier} plan` });
    }

    // 3. Check if already borrowing THIS book
    const { data: existingBorrow } = await supabase
      .from('borrows')
      .select('id')
      .eq('user_id', user.id)
      .eq('book_id', bookId)
      .is('returned_at', null)
      .single();

    if (existingBorrow) {
      return res.status(400).json({ error: 'You are already borrowing this book' });
    }

    // 4. Check book availability
    const { data: book, error: bookError } = await supabase
      .from('books')
      .select('available_copies')
      .eq('id', bookId)
      .single();

    if (bookError || !book) return res.status(404).json({ error: 'Book not found' });
    if (book.available_copies <= 0) {
      return res.status(400).json({ error: 'Book is currently out of stock' });
    }

    // 5. Calculate due date based on tier
    const dueDate = calculateDueDate(membershipTier);

    // 6. Transaction: Insert borrow & update copies
    const { data: borrowData, error: borrowError } = await serviceClient
      .from('borrows')
      .insert({
        user_id: user.id,
        book_id: bookId,
        due_date: dueDate.toISOString(),
      })
      .select()
      .single();

    if (borrowError) return res.status(500).json({ error: borrowError.message });

    const { error: updateError } = await serviceClient
      .from('books')
      .update({ available_copies: book.available_copies - 1 })
      .eq('id', bookId);

    if (updateError) return res.status(500).json({ error: 'Failed to update inventory' });

    // Try resolving any reserves if necessary
    await serviceClient.from('reserves')
      .update({ status: 'fulfilled' })
      .eq('user_id', user.id)
      .eq('book_id', bookId)
      .eq('status', 'active');

    return res.json({ success: true, borrow: borrowData });
  } catch (error) {
    console.error('Borrow error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/books/return
router.post('/return', requireAuth, async (req, res) => {
  try {
    const { borrowId } = req.body;
    if (!borrowId) return res.status(400).json({ error: 'Borrow ID is required' });

    const user = req.user;
    const supabase = req.supabase;
    const serviceClient = createServiceClient();

    // 1. Get borrow record
    const { data: borrow, error: borrowError } = await supabase
      .from('borrows')
      .select('*')
      .eq('id', borrowId)
      .eq('user_id', user.id)
      .single();

    if (borrowError || !borrow) return res.status(404).json({ error: 'Borrow record not found' });
    if (borrow.returned_at) return res.status(400).json({ error: 'Book already returned' });

    // 2. Check for fine
    const fineAmount = calculateFine(borrow.due_date);
    let fineRecord = null;

    if (fineAmount > 0) {
      const { data: fineData, error: fineError } = await serviceClient
        .from('fines')
        .insert({
          user_id: user.id,
          borrow_id: borrow.id,
          amount: fineAmount,
          status: 'unpaid',
          reason: `Late return by ${fineAmount / FINE_RATE_PER_DAY} days`
        })
        .select()
        .single();

      if (!fineError) fineRecord = fineData;
    }

    // 3. Update borrow record
    const returnedAt = new Date().toISOString();
    const { error: updateBorrowError } = await serviceClient
      .from('borrows')
      .update({ returned_at: returnedAt })
      .eq('id', borrow.id);

    if (updateBorrowError) return res.status(500).json({ error: 'Failed to update borrow status' });

    // 4. Update book copies
    const { data: book } = await serviceClient
      .from('books')
      .select('available_copies, total_copies')
      .eq('id', borrow.book_id)
      .single();


    if (book) {
      await serviceClient
        .from('books')
        .update({ available_copies: Math.min(book.available_copies + 1, book.total_copies) })
        .eq('id', borrow.book_id);
    }

    // 5. Add to reading history
    await serviceClient
      .from('reading_history')
      .insert({
        user_id: user.id,
        book_id: borrow.book_id,
        borrow_id: borrow.id,
        completed_at: returnedAt
      });

    return res.json({ 
      success: true, 
      message: 'Book returned successfully',
      fine: fineRecord 
    });
  } catch (error) {
    console.error('Return error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/books/renew
router.post('/renew', requireAuth, async (req, res) => {
  try {
    const { borrowId } = req.body;
    if (!borrowId) return res.status(400).json({ error: 'Borrow ID is required' });

    const user = req.user;
    const supabase = req.supabase;
    const serviceClient = createServiceClient();

    // 1. Get borrow & profile
    const { data: borrow, error: borrowError } = await supabase
      .from('borrows')
      .select('*')
      .eq('id', borrowId)
      .eq('user_id', user.id)
      .single();

    if (borrowError || !borrow) return res.status(404).json({ error: 'Borrow record not found' });
    if (borrow.returned_at) return res.status(400).json({ error: 'Book already returned' });

    // Check renew limit
    const MAX_RENEWALS = 2;
    if (borrow.renewal_count >= MAX_RENEWALS) {
      return res.status(400).json({ error: 'Maximum renewal limit reached for this book' });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('membership_tier')
      .eq('id', user.id)
      .single();

    const newDueDate = calculateDueDate(profile?.membership_tier || 'free', new Date(borrow.due_date));

    // Update
    const { error: updateError } = await serviceClient
      .from('borrows')
      .update({
        due_date: newDueDate.toISOString(),
        renewal_count: borrow.renewal_count + 1
      })
      .eq('id', borrow.id);

    if (updateError) return res.status(500).json({ error: 'Failed to renew book' });

    return res.json({ success: true, message: 'Book renewed successfully', newDueDate });
  } catch (error) {
    console.error('Renew error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/books/reserve
router.post('/reserve', requireAuth, async (req, res) => {
  try {
    const { bookId } = req.body;
    if (!bookId) return res.status(400).json({ error: 'Book ID is required' });

    const user = req.user;
    const supabase = req.supabase;
    const serviceClient = createServiceClient();

    // Check if currently borrowing
    const { data: existingBorrow } = await supabase
      .from('borrows')
      .select('id')
      .eq('user_id', user.id)
      .eq('book_id', bookId)
      .is('returned_at', null)
      .single();

    if (existingBorrow) return res.status(400).json({ error: 'You are currently borrowing this book' });

    // Check existing reserve
    const { data: existingReserve } = await supabase
      .from('reserves')
      .select('id')
      .eq('user_id', user.id)
      .eq('book_id', bookId)
      .eq('status', 'active')
      .single();

    if (existingReserve) return res.status(400).json({ error: 'You already have an active reservation for this book' });

    // Get queue position
    const { count: currentQueueLength } = await supabase
      .from('reserves')
      .select('*', { count: 'exact', head: true })
      .eq('book_id', bookId)
      .eq('status', 'active');

    const queuePosition = (currentQueueLength || 0) + 1;

    // Create reserve
    const { data: reserveData, error: reserveError } = await serviceClient
      .from('reserves')
      .insert({
        user_id: user.id,
        book_id: bookId,
        queue_position: queuePosition,
        status: 'active'
      })
      .select()
      .single();

    if (reserveError) {
      console.error('Reservation DB Error:', reserveError);
      return res.status(500).json({ error: `Reservation failed: ${reserveError.message}` });
    }

    return res.json({ success: true, reserve: reserveData });
  } catch (error) {
    console.error('Reserve error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/books/cancel-reserve
router.post('/cancel-reserve', requireAuth, async (req, res) => {
  try {
    const { reserveId } = req.body;
    if (!reserveId) return res.status(400).json({ error: 'Reserve ID is required' });

    const user = req.user;
    const serviceClient = createServiceClient();

    const { error: cancelError } = await serviceClient
      .from('reserves')
      .update({ status: 'cancelled' })
      .eq('id', reserveId)
      .eq('user_id', user.id)
      .eq('status', 'active');

    if (cancelError) return res.status(500).json({ error: 'Failed to cancel reservation' });

    return res.json({ success: true, message: 'Reservation cancelled' });
  } catch (error) {
    console.error('Cancel reserve error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
