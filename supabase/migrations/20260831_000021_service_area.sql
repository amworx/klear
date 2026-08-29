-- 20260831_000021_service_area.sql
-- Service area for phased rollout: start in Afrin (Aleppo), then expand.
-- Single circle (center + radius) keeps the first phase simple; later we can
-- add multi-zone support. Center is Afrin city ~36.5114,36.8681, radius 15km
-- covers Afrin + immediate villages. Expand by increasing radius or moving
-- center (e.g. Aleppo city 36.202,37.158 needs ~50km to cover both).

alter table public.app_settings
  add column if not exists service_center_lat double precision,
  add column if not exists service_center_lng double precision,
  add column if not exists service_radius_km integer;

-- Seed Afrin defaults for the single row (id=1). Keep existing row if present.
update public.app_settings
set service_center_lat = coalesce(service_center_lat, 36.5114),
    service_center_lng = coalesce(service_center_lng, 36.8681),
    service_radius_km  = coalesce(service_radius_km, 15)
where id = 1;

-- Ensure a row exists even on fresh installs.
insert into public.app_settings (id, service_center_lat, service_center_lng, service_radius_km)
values (1, 36.5114, 36.8681, 15)
on conflict (id) do nothing;
