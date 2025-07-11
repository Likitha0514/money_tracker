// models/Transaction.js
const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    user: {                          // ➜ reference to the User
      type: mongoose.Schema.Types.ObjectId,
      ref:  'User',
      required: true,
      index: true,                   // fast look‑ups by user
    },

    type: {                          // lend | in | out
      type: String,
      enum: ['lend', 'in', 'out'],
      required: true,
      index: true,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    notes: {
      type: String,
      trim: true,
      maxlength: 200,
    },

    date: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,                // createdAt, updatedAt
  }
);

module.exports = mongoose.model('Transaction', transactionSchema);
