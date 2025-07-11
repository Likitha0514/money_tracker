require('dotenv').config();
const express   = require('express');
const mongoose  = require('mongoose');
const cors      = require('cors');
const helmet    = require('helmet');
const morgan    = require('morgan');

const app  = express();
const PORT = process.env.PORT || 5000;

/* ─────────────────────────────────────────────────────────── middle‑ware ── */
app.use(cors({ origin: process.env.CLIENT_URL || '*' }));
app.use(express.json());
app.use(helmet());          // adds security headers
app.use(morgan('tiny'));    // request logger

/* ───────────────────────────────────────────────────────────── database ─── */
mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser:    true,
    useUnifiedTopology: true,
  })
  .then(() => console.log('✅  MongoDB connected'))
  .catch(err => {
    console.error('❌  MongoDB connection error:', err.message);
    process.exit(1);
  });

/* ───────────────────────────────────────────────────────────── routes ───── */
app.get('/health', (_, res) => res.json({ status: 'ok' }));   // quick ping

const userRoutes = require('./routes/user');
app.use('/api/users', userRoutes);   // <── mounted BEFORE listen
app.use('/api/transactions', require('./routes/transactions'));

/* 404 fallback */
app.use((_, res) => res.status(404).json({ message: 'Route not found' }));

/* Centralised error handler */
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.status || 500).json({ message: err.message || 'Server error' });
});

/* ───────────────────────────────────────────────────────────── start ──── */
app.listen(PORT, () => console.log(`🚀  Server listening on port ${PORT}`));
