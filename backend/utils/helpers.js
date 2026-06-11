const { differenceInDays, addDays, isPast } = require('date-fns');

const FINE_RATE_PER_DAY = 10;
const MEMBERSHIP_LIMITS = {
  free: { borrowLimit: 2, borrowDays: 7 },
  premium: { borrowLimit: 5, borrowDays: 21 },
  vip: { borrowLimit: 999, borrowDays: 30 }
};

function getBorrowDays(tier) {
  return MEMBERSHIP_LIMITS[tier]?.borrowDays || 7;
}

function getBorrowLimit(tier) {
  return MEMBERSHIP_LIMITS[tier]?.borrowLimit || 2;
}

function calculateDueDate(tier, from = new Date()) {
  return addDays(from, getBorrowDays(tier));
}

function isOverdue(dueDate, returnedAt = null) {
  if (returnedAt) return false;
  return isPast(new Date(dueDate));
}

function calculateFine(dueDate, returnedAt = null) {
  if (!isOverdue(dueDate, returnedAt)) return 0;
  const days = Math.max(0, differenceInDays(new Date(), new Date(dueDate)));
  return days * FINE_RATE_PER_DAY;
}

function generateOTP() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

module.exports = {
  getBorrowDays,
  getBorrowLimit,
  calculateDueDate,
  isOverdue,
  calculateFine,
  generateOTP,
  FINE_RATE_PER_DAY
};
