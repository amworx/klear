# T1 — Services Catalog Redesign (e-store grid + badges)

Parent plan: plans/2026-08-22_booking_ux_overhaul.md
Blocked by: Q3 (discount real vs display-only), Q4 (admin repo scope).

## Steps
1. Migration 20260822_000010_service_badges.sql
   - alter table services
       add column if not exists badge_kind text not null default 'none'
         check (badge_kind in ('none','new','discount','popular','custom')),
       add column if not exists badge_label_ar text,
       add column if not exists badge_label_en text,
       add column if not exists discount_percent numeric(5,2)
         not null default 0 check (discount_percent between 0 and 100),
       add column if not exists image_url text;
   - Seed demo: Full Care → discount 15% + badge 'الأكثر طلباً' (popular);
     Exterior Wash → 'new'.
2. Domain: KlearService += fields; effectivePrice = basePrice*(1-d);
   hasDiscount; badgeLabel(langCode) with admin label > kind fallback.
3. UI `service_grid_card.dart` (product card, RTL-first, dark-mode safe):
   - Aspect ~0.72 tile; media area h≈110 (icon in gradient container now,
     image_url via Image.network when set later); badge chip overlay
     top-leading (discount=error container, new=primary, popular=amber).
   - Name (1 line), desc (2 lines ellipsis), duration chip, price row:
     effective price bold primary + base strikethrough onSurfaceVariant.
   - AnimatedPress scale + Entrance stagger preserved.
4. ServicesPage → LayoutBuilder GridView.extent maxCrossAxisExtent 220;
   Home ServicesSection → compact horizontal carousel of same card.
5. Booking draft/confirm: use effectivePrice in estimates (per Q3).
6. l10n: badgeNew/badgePopular/badgeDiscountPercent/offLabel ar+en.
7. Tests: model parsing + effectivePrice math; grid smoke test;
   golden-free (existing test style).

## Acceptance
- Catalog reads like a product grid; discounted service shows both prices;
  badges visible in ar+en and both themes.
