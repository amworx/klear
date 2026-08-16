# P7 — Booking UX Improvements + Additional Steps

Milestone plan · 2026-08-16 · Status: PROPOSED (awaiting scope confirm)

## Goal

Remove the friction observed in the live walkthrough (EVT-20260816-0037) and add
a proper Review + Payment step so the booking flow ends with an explicit
customer commitment, not a silent insert.

## Grounding — live observations driving this milestone

- Step 1 estimate copy "Before car size adjustment" is internal-sounding.
- Price breakdown (base / size factor / total) only appears on the last step.
- Step 2 is dense: no default car, time selection is a checkbox, "Use my
  current location" has no loading/error handling.
- After Confirm the user lands back on Home with no "upcoming" signal.
- My Orders is a flat list: no status, no detail, no cancel, no refresh, no
  empty-state CTA.
- No payment/customer-commitment step exists (total computed, never accepted).

## Scope IN (Tier 1 + Tier 2 + Tier 3)

### Tier 1 — Flow polish
1. Rewrite estimate labels: "Base price", "Size adjustment", "Estimated total"
   (ar/en) — remove "Before car size adjustment" wording.
2. Show the live breakdown card on Step 2 as well as Step 3 (updates when the
   selected car changes: 20000 -> 25000 on medium).
3. Default car:
   - `cars` table gains `is_default bool not null default false`
   - My Cars: "Set as default" action; at most one default per user
   - Step 2 pre-selects the default car when present (otherwise first car)
4. Date & time:
   - Block past dates/times (cannot select before now)
   - "Pick another time" opens a date + time picker directly
   - Selected absolute date/time shown clearly on Step 2
5. "Use my current location":
   - Loading state while geolocating
   - Error snackbar on permission-denied / timeout / failure
6. Post-confirm: navigate Home and show an "Upcoming wash" hero card
   (date + car + total + View details) when a future pending booking exists.

### Tier 2 — My Orders upgrade
1. Status enum + label/color/icon map: pending / confirmed / in_progress /
   completed / cancelled (ar/en) — status chips on each order.
2. Booking detail page (route /orders/:id):
   - service, car (make/model/plate/size), address, date+time, total with
     breakdown, note, status
   - Cancel booking (confirm dialog) when status is pending -> updates
     bookings.status to 'cancelled' in DB
3. Pull-to-refresh (RefreshIndicator) + auto-refresh when tab is visited.
4. Empty state CTA -> "Book your first wash" (deep-link to /book/service).

### Tier 3 — New step: Review + Payment (booking step 4)
1. Booking flow becomes 4 steps: Service -> Details (car/address/time) ->
   Extras placeholder -> Review & Pay -> confirmation.
   (Extras deferred; step numbering keeps room for P8.)
2. Review & Pay page:
   - Full recap (service, car, address, time, note)
   - Cost breakdown card (base / size / total)
   - Payment method: "Pay on arrival" selected by default (MVP). UI reserved
     for future online payment methods but only cash option active.
   - Explicit confirm button: "Confirm booking" (replaces bare Confirm)
3. On success: existing success dialog -> Home + Upcoming wash card.

## Scope OUT (deferred to P8+)

- Extras/add-ons step
- Rating/review after completed wash
- Onboarding screens
- Captain assignment preview / tracking
- Online payment gateway
- Provider/wash-team dashboard
- Push/email notifications

## DB changes

- `cars.is_default` (bool, default false) + unique partial index
  (one default per user). Migration `20260816_000005_car_default.sql`.
- bookings.status values already 'pending'; cancel uses existing status column.
  No new statuses this milestone (provider sets others later).

## l10n

- New strings ar/en: estimate labels, upcoming card, status labels
  (pending/confirmed/in_progress/completed/cancelled), cancel dialog, empty
  order CTA, pay-on-arrival, confirm booking, location errors.
- Regenerate with `flutter gen-l10n`.

## Tests

- Booking draft: 4-step completion gating (service, car, address, time,
  payment accepted).
- Status label mapping (ar/en-safe).
- Cancel updates status to 'cancelled' (repository unit, mocked datasource).
- Default car selection logic (highest priority = default else first).
- Existing 12 tests stay green.

## Gates

- `flutter analyze` clean
- `flutter test` all green
- Live E2E: book with default car -> breakdown live -> pick another time ->
  Review & Pay -> confirm -> Home shows Upcoming card -> Orders shows
  confirmed/pending chip -> cancel a pending booking -> status cancelled in DB.

## Memory

- Event EVT-20260816-0038 (or next) on completion; lessons/patterns/decisions
  updated; decision record for 4-step flow + pay-on-arrival MVP.

## Status: DONE - 2026-08-16 (EVT-20260816-0038)

Delivered + live-verified:
- Upcoming wash card on Home (hides when none remain) - verified
- OrderDetailPage (/orders/:id) with full info + Cancel - verified
- Cancel -> soft status 'cancelled' in DB + Cancelled chip - verified
- Step 1 footer basePriceNoCar ("select a car for a precise total") - verified
- Step 2 default-car pre-select (preferredCar) + live breakdown card - verified
- Step 3 renamed Review & Pay with payment-method card (pay on arrival MVP,
  online disabled "coming soon") - verified
- My Cars set-as-default star + Default chip; clear-then-set switch verified
- Gates: analyze clean, 17/17 tests. DB: new booking d3f699b5 pending.
- Kept 3 steps (decision): no Extras placeholder step (amends the 4-step sketch
  in the original body above).

### Post-audit fixes (2026-08-16, EVT-20260816-0039)

User flagged the session todo list as all-unchecked. Audited item-by-item: all
delivered (live-verified); the list was just never ticked. Closed 3 residual
gaps so the plan text is fully true:
- Tests: added statusLabel en/ar mapping (all 5 statuses) + cancelBooking
  delegation unit test (fake datasource) -> 19/19.
- OrderDetailPage: added price breakdown card (Base / Size x factor / Total)
  when car is known (was: total only).
- Review & Pay confirm button now reads "Confirm booking" (was: bare Confirm).
Re-verified live on the rebuilt web (main.dart.js.v20260816c.js).
