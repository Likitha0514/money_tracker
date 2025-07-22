const mongoose = require('mongoose');

const emiSchema = new mongoose.Schema({
  email: { type: String, required: true },
  name: { type: String, required: true },
  amount: { type: Number, required: true },
  months: [{ type: String }], // e.g., ["2025-08", "2025-09", ...]
});

module.exports = mongoose.model('Emi', emiSchema);