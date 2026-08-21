-- Klear: Diagnostics & App Updates
--  - error_reports: user-submitted diagnostics from the in-app log viewer
--  - app_updates: single-row config for in-app update prompts (latest version, URL, changelog)

-- ============================================================
-- ERROR_REPORTS: user feedback on failures (RLS: anyone can insert, admin reads all, user reads own)
-- ============================================================
create table if not exists public.error_reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null,
  email text,
  app_version text not null,
  platform text not null default 'android',
  error_summary text not null,
  logs text not null,
  status text not null default 'open' check (status in ('open','acknowledged','fixed')),
  device_info jsonb
);

alter table public.error_reports enable row level security;

drop policy if exists "error_reports_insert_any" on public.error_reports;
create policy "error_reports_insert_any" on public.error_reports
  for insert with check (true);

drop policy if exists "error_reports_select_own" on public.error_reports;
create policy "error_reports_select_own" on public.error_reports
  for select using (auth.uid() = user_id);

drop policy if exists "error_reports_select_admin" on public.error_reports;
create policy "error_reports_select_admin" on public.error_reports
  for select using (public.is_admin());

drop policy if exists "error_reports_update_admin" on public.error_reports;
create policy "error_reports_update_admin" on public.error_reports
  for update using (public.is_admin()) with check (public.is_admin());

-- Allow admin to delete (cleanup)
drop policy if exists "error_reports_delete_admin" on public.error_reports;
create policy "error_reports_delete_admin" on public.error_reports
  for delete using (public.is_admin());

-- ============================================================
-- APP_UPDATES: single-row config for in-app update banner/dialog
-- ============================================================
create table if not exists public.app_updates (
  id int primary key check (id = 1),
  latest_version text not null,
  minimum_version text not null,
  update_url text not null,
  changelog text,
  force_update boolean not null default false,
  updated_at timestamptz not null default now()
);

-- Seed with current version (1.0.0). Admin updates this row to publish an update.
insert into public.app_updates (id, latest_version, minimum_version, update_url, changelog, force_update)
values (1, '1.0.0', '1.0.0', 'https://github.com/amworx/klear/releases', 'Initial release', false)
on conflict (id) do nothing;

alter table public.app_updates enable row level security;

drop policy if exists "app_updates_select_all" on public.app_updates;
create policy "app_updates_select_all" on public.app_updates
  for select using (true);

drop policy if exists "app_updates_update_admin" on public.app_updates;
create policy "app_updates_update_admin" on public.app_updates
  for update using (public.is_admin()) with check (public.is_admin());

-- Keep updated_at fresh
create or replace function public.touch_app_updates_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_app_updates_updated_at on public.app_updates;
create trigger trg_app_updates_updated_at
  before update on public.app_updates
  for each row execute function public.touch_app_updates_updated_at();
