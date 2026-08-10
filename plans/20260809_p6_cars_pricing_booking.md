# P6 — Book a wash with My Cars + transparent pricing

Date: 2026-08-09
Status: In progress
Tags: cars, pricing, booking, supabase, milestone

## Goal

Finish the booking value chain the user described across three messages:
1. Users add their cars (make/model/plate/size) so the washing team can identify
   them when the owner is absent, and so the **car size drives cost estimation**.
2. Booking flow collects schedule + washing type + other details and produces a
   **correct cost estimate and final money cost**.
3. Bookings are finally **persisted to Supabase** (existing confirm button was a TODO).

## Reference analysis — Captainz (captainzsa.com, Saudi Arabia)

Closest market analog. Confirms the model and refines UI details:
- Services show **estimated duration + fixed price** (e.g. Exterior ٢٠ دقيقة · ٤٩ ر.س).
- Flow: service → location/time → "Book now"; app has 4 tabs
  (Home / My bookings / Wallet / Account).
- Differentiation we keep: **size-aware pricing** (Captainz uses flat prices).
- Future phases (NOT this milestone): live captain tracking, monthly
  subscriptions, wallet payments, ratings, fleet/franchise.

## Scope (this milestone)

### A. My Cars (new feature: `features/cars/`)
- Domain `KlearCar { id, userId, make, model, plateNumber, size, createdAt }`
- `KlearCarSize` enum: small/medium/large with DB value + price factor
  (small ×1.0, medium ×1.25, large ×1.5)
- Table `public.cars` + RLS (owner full CRUD) + provider read policy
  (washing team can read cars linked to their assigned bookings)
- UI: account entry tile → list page (FAB add, edit, delete with confirm)
- l10n ar/en; LTR plate field

### B. Pricing & estimation
- `BookingDraft.estimatedTotal = service.basePrice × car.size.factor`
- Confirm page shows breakdown: base price row, car-size row, estimated total

### C. Booking flow enrichment (persist)
- New step **select your car** (route `book/car`), inserted after service
- Notes field on confirm page (already in draft, no UI yet)
- Confirm button persists booking: `bookings` insert with customer_id,
  service_id, car_id, address, scheduled_at, note, total_price
- Success dialog after real insert (still pops to root)

### D. Services duration (Captainz pattern)
- `duration_min` column on `services` (nullable), shown on service cards
  and booking summary ("≈ 20 min")

## Schema changes (`20260809_000004_cars.sql`)
1. `create table public.cars` (+ index, RLS, policies customer CRUD + provider select)
2. `alter bookings add column car_id uuid references cars(id)`
3. `alter services add column duration_min int`
4. `alter bookings add column note text` (was `note` already? init has `note` — reuse)

## Files touched
- `supabase/migrations/20260809_000004_cars.sql`
- `src/lib/features/cars/domain/klear_car.dart`
- `src/lib/features/cars/data/cars_remote_datasource.dart`
- `src/lib/features/cars/data/cars_repository.dart`
- `src/lib/features/cars/presentation/cars_providers.dart`
- `src/lib/features/cars/presentation/cars_page.dart`
- `src/lib/features/cars/presentation/car_form_page.dart`
- `src/lib/features/services/domain/klear_service.dart` (+duration)
- `src/lib/features/bookings/domain/klear_booking.dart` (car in draft)
- `src/lib/features/bookings/data/bookings_remote_datasource.dart` (new)
- `src/lib/features/bookings/data/bookings_repository.dart` (new)
- `src/lib/features/bookings/presentation/booking_providers.dart`
- `src/lib/features/bookings/presentation/car_selection_page.dart` (new)
- `src/lib/features/bookings/presentation/confirmation_page.dart`
- `src/lib/features/services/presentation/services_page.dart` (+duration)
- `src/lib/features/home/presentation/widgets/services_section.dart` (+duration)
- `src/lib/app/app_router.dart`, `src/lib/app/klear_app.dart`
- `src/lib/features/account/presentation/account_page.dart` (My Cars tile)
- `src/lib/l10n/app_ar.arb`, `app_en.arb`
- `src/test/klear_car_test.dart` (new), `booking_test.dart` (extend)

## Quality gates
- `flutter analyze` clean
- `flutter test` green (existing 5 + new car/draft tests)
- Migration applied to live Supabase (`supabase db query`)
- Live verify on web: login → add car → book → booking row exists

## Out of scope (next milestones)
- Orders list page (bookings now exist; wire the tab next)
- Wallet/subscriptions, live tracking, ratings
- Provider/admin dashboard for the washing team