const express = require('express');
const asyncHandler = require('express-async-handler');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

/* --------------------------- POST /api/users/register ------------------- */
router.post(
  '/register',
  [
    body('name').trim().isLength({ min: 2 }).withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid e‑mail required'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be ≥ 8 chars'),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, password } = req.body;

    // 🔍 Manually check for existing email
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'Email already exists' });
    }

    try {
      const user = await User.create({ name, email, password }); // auto‑hashes
      return res.status(201).json({ id: user._id });
    } catch (err) {
      return res.status(500).json({ message: 'Registration failed' });
    }
  })
);


/* ------------------------------ POST /api/users/login ------------------- */
router.post(
  '/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty().withMessage('Password required'),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ errors: errors.array() });

    const { email, password } = req.body;

    // get user and explicit pwd field
    const user = await User.findOne({ email }).select('+password');
    const ok = user && (await user.comparePassword(password));

    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

    /* sign JWT (expires in 7 d) */
    const token = jwt.sign({ sub: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d',
    });

    res.json({
      token,
      user: { id: user._id, name: user.name, email: user.email },
    });
  })
);
router.get('/by-email/:email', asyncHandler(async (req, res) => {
  const user = await User.findOne({ email: req.params.email }).select('name email');
  if (!user) return res.status(404).json({ message: 'User not found' });
  res.json(user);
}));
router.post('/check-email', asyncHandler(async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email is required' });

  const user = await User.findOne({ email });
  if (!user) return res.json({ exists: false });

  res.json({ exists: true });
}));
router.post('/reset-password',
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password').isLength({ min: 8 }).withMessage('Password must be ≥ 8 chars'),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ errors: errors.array() });

    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'User not found' });

    user.password = password; // will be auto-hashed via `pre('save')` hook
    await user.save();

    res.json({ message: 'Password updated successfully' });
  })
);

module.exports = router;
