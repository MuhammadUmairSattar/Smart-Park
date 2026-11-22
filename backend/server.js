const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex');
const REFRESH_SECRET = process.env.REFRESH_SECRET || crypto.randomBytes(32).toString('hex');
const QR_HMAC_SECRET = process.env.QR_HMAC_SECRET || '';

let pool = null;
const memUsers = new Map();
const memTickets = new Map();

async function initDb() {
  if (!process.env.DATABASE_URL) {
    console.log('Warning: DATABASE_URL not set. Running in temporary memory mode.');
    return;
  }
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await pool.query(`
    CREATE TABLE IF NOT EXISTS operators (
      id TEXT PRIMARY KEY,
      full_name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'operator',
      branch_id TEXT NOT NULL DEFAULT 'MAIN',
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS parking_tickets (
      token_number TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      vehicle_type TEXT NOT NULL,
      plate_number TEXT NOT NULL,
      owner_name TEXT NOT NULL,
      location_slot TEXT NOT NULL,
      total_fee NUMERIC NOT NULL DEFAULT 0,
      status TEXT NOT NULL,
      entry_time TIMESTAMPTZ NOT NULL,
      exit_time TIMESTAMPTZ,
      qr_signature TEXT NOT NULL,
      operator_id TEXT,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
  console.log('PostgreSQL tables ready.');
}

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
  const [salt, key] = stored.split(':');
  if (!salt || !key) return false;
  const derived = crypto.scryptSync(password, salt, 64);
  const keyBuf = Buffer.from(key, 'hex');
  return derived.length === keyBuf.length && crypto.timingSafeEqual(derived, keyBuf);
}

function issueTokens(user) {
  const accessToken = jwt.sign(
    { sub: user.id, email: user.email, role: user.role, branch_id: user.branch_id },
    JWT_SECRET,
    { expiresIn: '15m' }
  );
  const refreshToken = jwt.sign(
    { sub: user.id, type: 'refresh' },
    REFRESH_SECRET,
    { expiresIn: '30d' }
  );
  return { accessToken, refreshToken };
}

function requireAuth(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Missing token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    return next();
  } catch {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

app.get('/', (_, res) => res.json({ ok: true, service: 'SmartPark Pro API v1' }));
app.get('/v1/health', (_, res) => res.json({ ok: true, db: Boolean(pool) }));

app.post('/v1/auth/register', async (req, res) => {
  try {
    const fullName = String(req.body.full_name || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    const branchId = String(req.body.branch_id || 'MAIN').trim().toUpperCase();

    if (!fullName || !email.includes('@') || password.length < 6) {
      return res.status(400).json({ message: 'Valid name, email, and 6+ char password required.' });
    }

    const id = crypto.randomUUID();
    const passwordHash = hashPassword(password);
    const user = { id, full_name: fullName, email, role: 'operator', branch_id: branchId };

    if (pool) {
      const existing = await pool.query('SELECT id FROM operators WHERE email = $1', [email]);
      if (existing.rows.length > 0) {
        return res.status(409).json({ message: 'Email already registered. Please sign in.' });
      }
      await pool.query(
        'INSERT INTO operators (id, full_name, email, password_hash, role, branch_id) VALUES ($1,$2,$3,$4,$5,$6)',
        [id, fullName, email, passwordHash, 'operator', branchId]
      );
    } else {
      if (memUsers.has(email)) {
        return res.status(409).json({ message: 'Email already registered. Please sign in.' });
      }
      memUsers.set(email, { ...user, password_hash: passwordHash, is_active: true });
    }

    const { accessToken, refreshToken } = issueTokens(user);
    return res.status(201).json({ access_token: accessToken, refresh_token: refreshToken, user });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Registration failed' });
  }
});

app.post('/v1/auth/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');

    let row = null;
    if (pool) {
      const q = await pool.query('SELECT * FROM operators WHERE email = $1', [email]);
      row = q.rows[0] || null;
    } else {
      row = memUsers.get(email) || null;
    }

    if (!row || !row.is_active || !verifyPassword(password, row.password_hash)) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const user = { id: row.id, full_name: row.full_name, email: row.email, role: row.role, branch_id: row.branch_id };
    const { accessToken, refreshToken } = issueTokens(user);
    return res.json({ access_token: accessToken, refresh_token: refreshToken, user });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Login failed' });
  }
});

app.post('/v1/auth/refresh', async (req, res) => {
  try {
    const token = String(req.body.refresh_token || '');
    const decoded = jwt.verify(token, REFRESH_SECRET);
    if (decoded.type !== 'refresh') return res.status(401).json({ message: 'Invalid refresh token' });

    let row = null;
    if (pool) {
      const q = await pool.query('SELECT * FROM operators WHERE id = $1', [decoded.sub]);
      row = q.rows[0] || null;
    } else {
      for (const u of memUsers.values()) {
        if (u.id === decoded.sub) { row = u; break; }
      }
    }

    if (!row || !row.is_active) return res.status(401).json({ message: 'Operator session revoked' });
    const user = { id: row.id, full_name: row.full_name, email: row.email, role: row.role, branch_id: row.branch_id };
    const { accessToken, refreshToken } = issueTokens(user);
    return res.json({ access_token: accessToken, refresh_token: refreshToken });
  } catch {
    return res.status(401).json({ message: 'Refresh token expired' });
  }
});

app.post('/v1/parking/tickets', requireAuth, async (req, res) => {
  try {
    const b = req.body;
    if (QR_HMAC_SECRET) {
      const payload = `${b.token_number}|${b.plate_number}|${b.branch_id}|${new Date(b.entry_time).getTime()}`;
      const expected = crypto.createHmac('sha256', QR_HMAC_SECRET).update(payload).digest('hex').slice(0, 16);
      if (b.qr_signature !== expected) {
        return res.status(403).json({ message: 'Invalid QR cryptographic signature' });
      }
    }

    if (pool) {
      await pool.query(
        `INSERT INTO parking_tickets (token_number, branch_id, vehicle_type, plate_number, owner_name, location_slot, total_fee, status, entry_time, qr_signature, operator_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
         ON CONFLICT (token_number) DO UPDATE SET status=EXCLUDED.status, total_fee=EXCLUDED.total_fee, updated_at=NOW()`,
        [b.token_number, b.branch_id, b.vehicle_type, b.plate_number, b.owner_name, b.location_slot, b.total_fee || 0, b.status, b.entry_time, b.qr_signature, req.user.sub]
      );
    } else {
      memTickets.set(b.token_number, b);
    }
    return res.status(201).json({ ok: true, token_number: b.token_number });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Ticket sync failed' });
  }
});

app.post('/v1/parking/tickets/:token/checkout', requireAuth, async (req, res) => {
  try {
    const token = req.params.token;
    const b = req.body;
    if (pool) {
      await pool.query(
        `UPDATE parking_tickets SET status='checkedOut', exit_time=$1, total_fee=$2, updated_at=NOW() WHERE token_number=$3`,
        [b.exit_time || new Date().toISOString(), b.total_fee || 0, token]
      );
    } else {
      memTickets.set(token, { ...memTickets.get(token), ...b, status: 'checkedOut' });
    }
    return res.json({ ok: true, token_number: token });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Checkout sync failed' });
  }
});

initDb()
  .then(() => app.listen(PORT, '0.0.0.0', () => console.log(`SmartPark API running on ${PORT}`)))
  .catch((e) => {
    console.error('DB init failed:', e);
    process.exit(1);
  });
