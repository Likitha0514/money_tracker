const express = require('express');
const router = express.Router();
const Emi = require('../models/Emi');

// Add EMI
router.post('/addemi', async (req, res) => {
  const { email, name, amount, months } = req.body;
  const emi = new Emi({ email, name, amount, months });
  await emi.save();
  res.json({ success: true, emi });
});

// Fetch EMIs
router.get('/fetchemi', async (req, res) => {
  const { email } = req.query;
  const emis = await Emi.find({ email });
  res.json({ emis });
});

// Update EMI (pay a month)
router.post('/updateemi', async (req, res) => {
  const { emiId, month } = req.body;
  const emi = await Emi.findById(emiId);
  emi.months = emi.months.filter(m => m !== month);
  await emi.save();
  res.json({ success: true, emi });
});

module.exports = router;