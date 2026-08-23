# T3 — Smart Features (personalization)

Parent plan: plans/2026-08-22_booking_ux_overhaul.md
Depends on: T1 (badges surface), orders data (exists).

## Steps
1. insights_provider.dart (orders feature):
   - mostUsedServiceId: argmax count of service_id over non-cancelled orders.
   - lastBooking: latest by scheduled_at/created_at.
   - preferredWindow: mode of time_type/hour-bucket across history.
2. Merge into catalog pipeline: ServiceGridCard receives optional
   isMostUsed → renders auto "الأكثر طلباً" badge when admin badge absent
   (admin badge wins if set).
3. Home quick action "احجز مرة أخرى" card when lastBooking exists and its
   service still active: one tap prefills draft (service/car/address/latlng/
   last window) → jumps straight to confirm step.
4. Smart defaults in step 2: preselect preferredWindow chip if that window has
   capacity (needs T2 provider).
5. l10n keys: bookAgain, mostOrdered, smartDefaultHint (ar/en).
6. Tests: aggregation logic (empty history, ties → lowest sort index),
   book-again prefill correctness.

## Acceptance
- Returning user sees their favorite service badged + can rebook in ≤2 taps.
