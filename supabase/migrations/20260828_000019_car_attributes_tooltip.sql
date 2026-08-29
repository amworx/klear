-- Klear: editable tooltip for car attributes.
--
-- The admin page shows tooltips on the system / affects-price badges (generic
-- i18n strings), but there was no per-attribute tooltip that an admin could
-- edit and that the customer app could display. Customers saw only the
-- generated "Label: Value · Affects price ×factor" chip tooltip.
--
-- Add two nullable text columns so each attribute can carry a localized
-- tooltip/description (shown as the chip tooltip in the Flutter app; when
-- empty the app falls back to the generated label/value string).
alter table public.car_attributes
  add column if not exists tooltip_ar text,
  add column if not exists tooltip_en text;
