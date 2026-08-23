# Booking UX Overhaul — Plan
Date: 2026-08-22 · Status: DRAFT (awaiting decisions Q1–Q4)

## Goal
Transform the booking experience: visual slot calendar, e-store-style service
catalog with badges/discounts, and smart personalization.

## Current state (verified in code)
- Step 2 of booking (`booking_details_page.dart`): day chips (today/tomorrow/
  custom) × flexibility categories (all-day / 8–12 / 10–14 / 14–18 / urgent+25%).
  Zero availability awareness.
- Services UI: flat list rows (`services_section.dart`) reused on Home + tab.
- Schema: `services(name_ar/en, desc_ar/en, base_price, currency, is_active,
  sort, duration_min)`; `bookings(scheduled_at, scheduled_end, time_type,
  status, provider_id…)` with time_type ∈ all_day|window|urgent.
- **RLS constraint:** customers can SELECT only their OWN bookings ⇒ global
  busy-slot data must come from a SECURITY DEFINER aggregate RPC, never a
  direct table read.
- `AppSettings` (client) already carries priceFactorFor(size) +
  urgentSurchargePercent — pricing pipeline exists for discounts to plug into.

## Architecture decisions
D1. Availability = server RPC `day_availability(day date)` → returns per-window
    remaining capacity. Client renders free/limited/busy. No raw bookings read.
D2. Windows stay the booking unit (all-day/4h/urgent unchanged, backward
    compatible with existing rows); calendar adds *visibility*, not a new model.
    [Revisit if Q1 answer says fixed hourly slots.]
D3. Badges/discounts live on `services`: `badge_kind`(none|new|discount|
    popular|custom) + `badge_label_ar/en` + `discount_percent`. Effective price
    computed client-side; checkout total uses it.
D4. "Most used" is derived client-side from orders history (no schema change),
    surfaced as an auto-badge + reorder hint.

## Phases / Tasks
### Phase 1 — Catalog redesign (T1)
- Migration `20260822_000010_service_badges.sql`: badge_kind, badge_label_ar/en,
  discount_percent (+ CHECK 0..100), image_url (nullable, later use).
- KlearService: effectivePrice, discountPercent, badgeKind/Label parsing.
- New `service_grid_card.dart`: 2-col GridView product card — media tile
  (icon/image), badge overlay chip, name, desc (2 lines), duration chip,
  price row (effective bold + strikethrough base when discounted).
- ServicesPage → responsive grid (2 cols phone / 3–4 wide). Home keeps
  horizontal carousel of the same card (compact variant).
- l10n keys ar+en for badge fallbacks ("جديد", "خصم %", "الأكثر طلباً").

### Phase 2 — Calendar & slots (T2)
- RPC `day_availability(day)`: windows [{8–12,10–14,14–18}] × {booked_count,
  capacity} for status != cancelled; SECURITY DEFINER + revoke from anon writes.
- AppSettings += `daily_capacity`, `slot_windows` (server-driven defaults 8–18).
- Step 2 UI: 14-day horizontal calendar strip with load dots (free/limited/
  full) under each day; selecting a day shows per-window capacity pills;
  full windows disabled; all-day disabled when every window full; urgent
  unaffected (today-only rule kept).
- Draft gains optional `selectedWindowKey`; confirm page unchanged otherwise.

### Phase 3 — Smart features (T3)
- ordersProvider-derived stats: mostUsedServiceId, lastBooking.
- Auto "most used" badge merge into catalog cards; Home "احجز مرة أخرى"
  (book again) quick action prefilling draft (car/address/service/window).
- Smart defaults: preselect previously used window when available.

## Out of scope (recorded)
- klear-admin editing UI for badges/discounts (follow-up in that repo).
- Payments, provider assignment logic, push reminders.

## Open decisions blocking BUILD
Q1 window-model, Q2 daily capacity, Q3 discounts real vs display-only,
Q4 admin repo included now? (see chat message)
