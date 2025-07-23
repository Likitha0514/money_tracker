const express = require('express');
const asyncHandler = require('express-async-handler');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Emi = require('../models/Emi');
const router = express.Router();

/* ---------------- Helper: Add a transaction ---------------- */
const addTransaction = asyncHandler(async (req, res) => {
  let { email, amount, type, notes, date, isPrevious } = req.body;
  amount = Number(amount);

  if (!email || amount === undefined || isNaN(amount) || !type) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found' });

  if (type === 'lend' && !isPrevious) {
    if (user.balance < amount) {
      return res.status(400).json({ message: 'Insufficient balance' });
    }
    user.balance -= amount;
  }

  if (type === 'in') {
    user.balance += amount;
  }

  if (type === 'out') {
    if (user.balance < amount) {
      return res.status(400).json({ message: 'Insufficient balance' });
    }
    user.balance -= amount;
  }

  const txn = await Transaction.create({
    user: user._id,
    amount,
    type,
    notes,
    date: date || new Date(),
  });

  await user.save();
  res.status(201).json(txn);
});


/* ---------------- POST /api/transactions (generic add) ---------------- */
router.post('/add', addTransaction);

/* ---------------- POST /api/transactions/in ---------------- */
router.post('/in', (req, res, next) => {
  req.body.type = 'in';
  next();
}, addTransaction);

/* ---------------- POST /api/transactions/out ---------------- */
router.post('/out', (req, res, next) => {
  req.body.type = 'out';
  next();
}, addTransaction);

/* ---------------- POST /api/transactions/lend ---------------- */
router.post('/lend', (req, res, next) => {
  req.body.type = 'lend';
  next();
}, addTransaction);

/* ---------------- GET /api/transactions?type=... ---------------- */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const { email, type } = req.query;
    if (!email || !type) {
      return res.status(400).json({ message: 'Email and type are required' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const txns = await Transaction.find({ user: user._id, type }).sort({ date: -1 });
    res.json(txns);
  })
);
/* ---------------- GET /api/transactions/all ---------------- */
router.get(
  '/all',
  asyncHandler(async (req, res) => {
    const { email } = req.query;
    if (!email) return res.status(400).json({ message: 'Email is required' });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const txns = await Transaction.find({ user: user._id }).sort({ date: -1 });
    res.json(txns);
  })
);
router.post('/delete-range', async (req, res) => {
  try {
    const { email, startDate, endDate } = req.body;
    if (!email || !startDate || !endDate) {
      return res.status(400).json({ message: 'Missing parameters' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const result = await Transaction.deleteMany({
      user: user._id,
      type: { $in: ['in', 'out'] }, // ✅ Only delete 'in' and 'out'
      date: {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      },
    });

    res.json({ message: `${result.deletedCount} transaction(s) deleted.` });
  } catch (err) {

    res.status(500).json({ message: 'Server error' });
  }

});


//POST /clear-full
router.post('/clear-full', async (req, res) => {
  const { transactionId, amount, date, note: userNote } = req.body;
  try {
    if (!transactionId || !amount || !date) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // 1) Remove the original lend txn, grab its stored note
    const original = await Transaction.findByIdAndDelete(transactionId);
    if (!original)
      return res.status(404).json({ message: 'Original transaction not found' });

    // 2) Build a new note that merges both
    const combinedNote = [
      'Cleared from lent',
      original.notes && original.notes.trim(),
      userNote && userNote.trim()
    ]
      .filter(Boolean)
      .join(' • ');
    // e.g. "Cleared from lent • Lunch with Sam • Partial amount"

    // 3) Create the “in” transaction, using that combined note
    await Transaction.create({
      user: original.user,
      type: 'in',
      amount,
      date,
      notes: combinedNote,
    });

    // 4) Restore the user's balance
    const user = await User.findById(original.user);
    if (user) {
      user.balance += Number(amount);
      await user.save();
    }

    res.send({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).send("Server error");
  }
});

// POST /clear-partial
router.post('/clear-partial', async (req, res) => {
  const { transactionId, clearAmount, remainingAmount, date, note: userNote } = req.body;
  try {
    if (!transactionId || !clearAmount || !remainingAmount || !date) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // 1) Update the original lend txn’s amount, keep its note
    const updated = await Transaction.findByIdAndUpdate(
      transactionId,
      { amount: remainingAmount },
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: 'Transaction not found' });

    // 2) Combine notes
    const combinedNote = [
      'Partial clear from lent',
      updated.notes && updated.notes.trim(),
      userNote && userNote.trim()
    ]
      .filter(Boolean)
      .join(' • ');

    // 3) Create the “in” piece
    await Transaction.create({
      user: updated.user,
      type: 'in',
      amount: clearAmount,
      date,
      notes: combinedNote,
    });

    // 4) Restore the user’s balance by the cleared amount
    const user = await User.findById(updated.user);
    if (user) {
      user.balance += Number(clearAmount);
      await user.save();
    }

    res.send({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).send("Server error");
  }
});


router.get('/balance', async (req, res) => {
  const { email } = req.query;
  if (!email) return res.status(400).json({ message: 'Email is required' });

  try {
    const user = await User.findOne({ email: new RegExp(`^${email}$`, 'i') });
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({ balance: user.balance });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});
// in routes/transactions.js, after your existing routes:

// GET /api/transactions/monthly-summary?email=...&year=YYYY&month=MM
router.get('/monthly-summary', asyncHandler(async (req, res) => {
  const { email, year, month } = req.query;
  if (!email || !year || !month) {
    return res.status(400).json({ message: 'Missing parameters' });
  }
  const user = await User.findOne({ email: new RegExp(`^${email}$`, 'i') });
  if (!user) return res.status(404).json({ message: 'User not found' });

  const start = new Date(`${year}-${month}-01T00:00:00.000Z`);
  const end = new Date(start);
  end.setMonth(end.getMonth() + 1);

  // aggregate sums by type
  const agg = await Transaction.aggregate([
    { $match: { user: user._id, date: { $gte: start, $lt: end } } },
    { $group: { _id: '$type', total: { $sum: '$amount' } } }
  ]);

  // default zero
  const summary = { lend: 0, in: 0, out: 0 };
  agg.forEach(row => { summary[row._id] = row.total; });

  res.json(summary);
}));

// GET /api/transactions/weekly-summary?email=...&start=YYYY-MM-DD&end=YYYY-MM-DD
router.get('/weekly-summary', asyncHandler(async (req, res) => {
  const { email, start, end } = req.query;
  if (!email || !start || !end) {
    return res.status(400).json({ message: 'Missing parameters' });
  }
  const user = await User.findOne({ email: new RegExp(`^${email}$`, 'i') });
  if (!user) return res.status(404).json({ message: 'User not found' });

  const startDate = new Date(`${start}T00:00:00.000Z`);
  const endDate = new Date(`${end}T23:59:59.999Z`);

  // aggregate sums by type
  const agg = await Transaction.aggregate([
    { $match: { user: user._id, date: { $gte: startDate, $lte: endDate } } },
    { $group: { _id: '$type', total: { $sum: '$amount' } } }
  ]);

  // default zero
  const summary = { lend: 0, in: 0, out: 0 };
  agg.forEach(row => { summary[row._id] = row.total; });

  res.json(summary);
}));

// POST /api/transactions/pay-emi

router.post('/pay-emi', asyncHandler(async (req, res) => {
  const { email, emiId, month, amount, note } = req.body; // ✅ now includes note
  //console.log('📥 PAY EMI REQUEST:', req.body);

  if (!email || !emiId || !month || amount === undefined || isNaN(Number(amount))) {
    //console.log('❌ Missing or invalid input');
    return res.status(400).json({ message: 'Missing or invalid fields' });
  }

  const user = await User.findOne({ email });
  if (!user) {
    //console.log('❌ User not found');
    return res.status(404).json({ message: 'User not found' });
  }

  const amt = Number(amount);
  // console.log('💰 Parsed amount:', amt);

  if (user.balance < amt) {
    //console.log(`❌ Insufficient balance: ${user.balance} < ${amt}`);
    return res.status(400).json({ message: 'Insufficient balance' });
  }

  const emi = await Emi.findById(emiId);
  if (!emi) {
    // console.log('❌ EMI not found');
    return res.status(404).json({ message: 'EMI not found' });
  }

  //  console.log('📦 EMI before:', emi.months);

  emi.months = emi.months.filter(m => m !== month);
  await emi.save();
  // console.log('✅ EMI month removed:', month);

  user.balance -= amt;
  const txn = await Transaction.create({
    user: user._id,
    amount: amt,
    type: 'out',
    notes: note,
    date: new Date(),
  });

  await user.save();

  // console.log('✅ Balance updated:', user.balance);
  // console.log('✅ Transaction created:', txn);

  res.status(201).json({ message: 'EMI paid successfully', transaction: txn, emi });
}));

module.exports = router;
