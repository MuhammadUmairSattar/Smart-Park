# SmartPark Pro — Commercial Parking Operations Suite

Enterprise Flutter (Android & iOS) parking management application featuring offline-first SQLite persistence, auto-login session restoration, background cloud sync, REST JWT authentication with biometric session unlock, multi-region ANPR license plate OCR, HMAC-SHA256 signed QR exit passes, multi-branch tariffs, 50 themes, VIP passes, and PDF/CSV financial exports.

## Features Implemented
- **Auto-Login & JWT Security:** Persistent encrypted session restoration (`FlutterSecureStorage`) with real `/auth/login`, `/auth/register`, and `/auth/refresh` endpoints plus biometric unlock.
- **Offline-First SQLite + Cloud Sync:** Persistent `sqflite` storage (`tickets`, `sync_queue`, `vip_passes`) with `connectivity_plus` auto-sync.
- **Multi-Region ANPR OCR:** Google ML Kit text recognition with geometry scoring and regional regex ranking.
- **Anti-Forgery QR Passes:** HMAC-SHA256 signed QR receipts verified via `mobile_scanner` on check-out.
- **Commercial Tariff & Theme Engine:** Configurable base/hourly rates, grace period, tax/VAT %, 30-day VIP passes, multi-branch switching, 50 luxury themes, and 80mm thermal PDF + CSV exports.
- **Localization:** Verified English, Urdu (RTL), and Arabic (RTL) translations.

## Environment Variables (`--dart-define`)
| Variable | Description |
|---|---|
| `API_BASE_URL` | Base URL for your REST backend (`/auth/*`, `/parking/tickets*`) |
| `QR_HMAC_SECRET` | 256-bit secret shared with backend for QR HMAC-SHA256 signing |

## Developer
**Muhammad Umair Sattar** — © 2026 All Rights Reserved.
