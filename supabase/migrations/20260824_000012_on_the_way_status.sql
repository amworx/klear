-- 20260824_000012_on_the_way_status.sql
-- New booking status for 'captain is en route'. Must be its own migration:
-- Postgres requires new enum values to be committed before use.

ALTER TYPE booking_status ADD VALUE IF NOT EXISTS 'on_the_way' AFTER 'accepted';