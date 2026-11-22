const enc = new TextEncoder();

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Content-Type': 'application/json',
  };
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: corsHeaders() });
}

function toHex(buf) {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function fromHex(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function b64url(bytes) {
  return btoa(String.fromCharCode(...new Uint8Array(bytes)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function unb64url(str) {
  const padded = str.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((str.length + 3) % 4);
  const bin = atob(padded);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, key, 256);
  return `${toHex(salt)}:${toHex(bits)}`;
}

async function verifyPassword(password, stored) {
  const [saltHex, hashHex] = stored.split(':');
  if (!saltHex || !hashHex) return false;
  const key = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt: fromHex(saltHex), iterations: 100000, hash: 'SHA-256' }, key, 256);
  const derivedHex = toHex(bits);
  if (derivedHex.length !== hashHex.length) return false;
  let diff = 0;
  for (let i = 0; i < derivedHex.length; i++) diff |= derivedHex.charCodeAt(i) ^ hashHex.charCodeAt(i);
  return diff === 0;
}

async function signJwt(claims, secret, ttlSec) {
  const header = b64url(enc.encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
  const payload = b64url(enc.encode(JSON.stringify({ ...claims, exp: Math.floor(Date.now() / 1000) + ttlSec })));
  const data = `${header}.${payload}`;
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  return `${data}.${b64url(sig)}`;
}

async function verifyJwt(token, secret) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('HMAC', key, unb64url(parts[2]), enc.encode(`${parts[0]}.${parts[1]}`));
  if (!ok) return null;
  const payload = JSON.parse(new TextDecoder().decode(unb64url(parts[1])));
  if (!payload.exp || payload.exp < Math.floor(Date.now() / 1000)) return null;
  return payload;
}

async function hmacHex16(payload, secret) {
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(payload));
  return toHex(sig).slice(0, 16);
}

let schemaReady = false;
async function ensureSchema(db) {
  if (schemaReady) return;
  await db.prepare(`CREATE TABLE IF NOT EXISTS operators (
    id TEXT PRIMARY KEY, full_name TEXT NOT NULL, email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'operator',
    branch_id TEXT NOT NULL DEFAULT 'MAIN', is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL
  )`).run();
  await db.prepare(`CREATE TABLE IF NOT EXISTS parking_tickets (
    token_number TEXT PRIMARY KEY, branch_id TEXT NOT NULL, vehicle_type TEXT NOT NULL,
    plate_number TEXT NOT NULL, owner_name TEXT NOT NULL, location_slot TEXT NOT NULL,
    total_fee REAL NOT NULL DEFAULT 0, status TEXT NOT NULL, entry_time TEXT NOT NULL,
    exit_time TEXT, qr_signature TEXT NOT NULL, operator_id TEXT, updated_at TEXT NOT NULL
  )`).run();
  schemaReady = true;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders() });

    const url = new URL(request.url);
    const path = url.pathname;
    const jwtSecret = env.JWT_SECRET || 'DEFAULT_DEV_JWT_CHANGE_IN_CF';
    const refreshSecret = env.REFRESH_SECRET || 'DEFAULT_DEV_REFRESH_CHANGE_IN_CF';

    if (path === '/' || path === '/v1/health') {
      return json({ ok: true, service: 'SmartPark Pro Cloudflare API', db: Boolean(env.DB) });
    }

    try {
      await ensureSchema(env.DB);
      const body = request.method === 'POST' ? await request.json().catch(() => ({})) : {};

      if (path === '/v1/auth/register' && request.method === 'POST') {
        const fullName = String(body.full_name || '').trim();
        const email = String(body.email || '').trim().toLowerCase();
        const password = String(body.password || '');
        const branchId = String(body.branch_id || 'MAIN').trim().toUpperCase();
        if (!fullName || !email.includes('@') || password.length < 6) {
          return json({ message: 'Valid name, email, and 6+ char password required.' }, 400);
        }
        const exists = await env.DB.prepare('SELECT id FROM operators WHERE email = ?').bind(email).first();
        if (exists) return json({ message: 'Email already registered. Please sign in.' }, 409);

        const id = crypto.randomUUID();
        const hash = await hashPassword(password);
        await env.DB.prepare(
          'INSERT INTO operators (id, full_name, email, password_hash, role, branch_id, is_active, created_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?)'
        ).bind(id, fullName, email, hash, 'operator', branchId, new Date().toISOString()).run();

        const user = { id, full_name: fullName, email, role: 'operator', branch_id: branchId };
        const access_token = await signJwt({ sub: id, email, role: 'operator', branch_id: branchId }, jwtSecret, 900);
        const refresh_token = await signJwt({ sub: id, type: 'refresh' }, refreshSecret, 2592000);
        return json({ access_token, refresh_token, user }, 201);
      }

      if (path === '/v1/auth/login' && request.method === 'POST') {
        const email = String(body.email || '').trim().toLowerCase();
        const password = String(body.password || '');
        const row = await env.DB.prepare('SELECT * FROM operators WHERE email = ?').bind(email).first();
        if (!row || row.is_active !== 1 || !(await verifyPassword(password, row.password_hash))) {
          return json({ message: 'Invalid email or password.' }, 401);
        }
        const user = { id: row.id, full_name: row.full_name, email: row.email, role: row.role, branch_id: row.branch_id };
        const access_token = await signJwt({ sub: row.id, email: row.email, role: row.role, branch_id: row.branch_id }, jwtSecret, 900);
        const refresh_token = await signJwt({ sub: row.id, type: 'refresh' }, refreshSecret, 2592000);
        return json({ access_token, refresh_token, user });
      }

      if (path === '/v1/auth/refresh' && request.method === 'POST') {
        const decoded = await verifyJwt(String(body.refresh_token || ''), refreshSecret);
        if (!decoded || decoded.type !== 'refresh') return json({ message: 'Refresh token expired' }, 401);
        const row = await env.DB.prepare('SELECT * FROM operators WHERE id = ?').bind(decoded.sub).first();
        if (!row || row.is_active !== 1) return json({ message: 'Operator session revoked' }, 401);
        const access_token = await signJwt({ sub: row.id, email: row.email, role: row.role, branch_id: row.branch_id }, jwtSecret, 900);
        const refresh_token = await signJwt({ sub: row.id, type: 'refresh' }, refreshSecret, 2592000);
        return json({ access_token, refresh_token });
      }

      const authHeader = request.headers.get('Authorization') || '';
      const bearer = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
      const authUser = await verifyJwt(bearer, jwtSecret);
      if (!authUser) return json({ message: 'Unauthorized' }, 401);

      if (path === '/v1/parking/tickets' && request.method === 'POST') {
        if (env.QR_HMAC_SECRET) {
          const payload = `${body.token_number}|${body.plate_number}|${body.branch_id}|${new Date(body.entry_time).getTime()}`;
          if (body.qr_signature !== await hmacHex16(payload, env.QR_HMAC_SECRET)) {
            return json({ message: 'Invalid QR signature' }, 403);
          }
        }
        await env.DB.prepare(`
          INSERT INTO parking_tickets (token_number, branch_id, vehicle_type, plate_number, owner_name, location_slot, total_fee, status, entry_time, qr_signature, operator_id, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(token_number) DO UPDATE SET status=excluded.status, total_fee=excluded.total_fee, updated_at=excluded.updated_at
        `).bind(
          body.token_number, body.branch_id, body.vehicle_type, body.plate_number, body.owner_name,
          body.location_slot, body.total_fee || 0, body.status, body.entry_time, body.qr_signature,
          authUser.sub, new Date().toISOString()
        ).run();
        return json({ ok: true, token_number: body.token_number }, 201);
      }

      if (path.startsWith('/v1/parking/tickets/') && path.endsWith('/checkout') && request.method === 'POST') {
        const token = path.split('/')[4];
        await env.DB.prepare(
          'UPDATE parking_tickets SET status=?, exit_time=?, total_fee=?, updated_at=? WHERE token_number=?'
        ).bind('checkedOut', body.exit_time || new Date().toISOString(), body.total_fee || 0, new Date().toISOString(), token).run();
        return json({ ok: true, token_number: token });
      }

      return json({ message: 'Not found' }, 404);
    } catch (err) {
      return json({ message: 'Server error', detail: String(err.message || err) }, 500);
    }
  },
};
