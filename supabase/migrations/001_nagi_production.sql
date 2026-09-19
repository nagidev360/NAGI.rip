-- NAGI.rip production schema extension
-- Apply only to the dedicated NAGI.rip Supabase project.
create extension if not exists pgcrypto;

do $$ begin create type public.user_role as enum ('USER','MODERATOR','ADMIN','OWNER'); exception when duplicate_object then null; end $$;
do $$ begin create type public.account_status as enum ('ACTIVE','SUSPENDED','BANNED','DELETED'); exception when duplicate_object then null; end $$;

alter table public.profiles add column if not exists role public.user_role not null default 'USER';
alter table public.profiles add column if not exists account_status public.account_status not null default 'ACTIVE';
alter table public.profiles add column if not exists email_verified boolean not null default false;
alter table public.profiles add column if not exists timezone text not null default 'Asia/Kolkata';
alter table public.profiles add column if not exists language text not null default 'en';
alter table public.profiles add column if not exists country text;
alter table public.profiles add column if not exists category text not null default 'Personal';
alter table public.profiles add column if not exists seo_title text;
alter table public.profiles add column if not exists seo_description text;
alter table public.profiles add column if not exists og_image text;
alter table public.profiles add column if not exists canonical_url text;
alter table public.profiles add column if not exists published_at timestamptz;

create table if not exists public.profile_themes (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 name text not null,
 config jsonb not null default '{}'::jsonb,
 is_active boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.templates (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 category text not null,
 config jsonb not null default '{}'::jsonb,
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.sessions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 device text,
 browser text,
 ip_hash text,
 created_at timestamptz not null default now(),
 last_active timestamptz not null default now(),
 expires_at timestamptz not null
);
create table if not exists public.user_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 autosave boolean not null default true,
 analytics_opt_out boolean not null default false,
 reduced_motion boolean not null default false,
 high_contrast boolean not null default false,
 notification_settings jsonb not null default '{}'::jsonb,
 privacy_settings jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.profile_revisions (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 revision_number bigint generated always as identity,
 snapshot jsonb not null,
 created_at timestamptz not null default now()
);
create table if not exists public.profile_change_history (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 actor_user_id uuid references auth.users(id) on delete set null,
 change_type text not null,
 before_value jsonb,
 after_value jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.blocks (
 blocker_user_id uuid not null references auth.users(id) on delete cascade,
 blocked_user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key (blocker_user_id, blocked_user_id),
 check (blocker_user_id <> blocked_user_id)
);
create table if not exists public.email_events (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id) on delete set null,
 type text not null,
 provider_id text,
 status text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.feature_flags (
 key text primary key,
 enabled boolean not null default false,
 config jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now()
);
create table if not exists public.site_settings (
 key text primary key,
 value jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now()
);
create table if not exists public.rate_limits (
 key text primary key,
 count integer not null default 0,
 reset_at timestamptz not null
);

create index if not exists profiles_user_id_idx on public.profiles(user_id);
create index if not exists profiles_status_visibility_idx on public.profiles(status, visibility);
create index if not exists profile_themes_profile_idx on public.profile_themes(profile_id, updated_at desc);
create index if not exists sessions_user_idx on public.sessions(user_id, last_active desc);
create index if not exists revisions_profile_idx on public.profile_revisions(profile_id, created_at desc);
create index if not exists reports_status_idx on public.reports(status, created_at desc);
create index if not exists domains_domain_idx on public.custom_domains(domain);
create index if not exists analytics_event_time_idx on public.analytics_events(created_at desc);
create unique index if not exists profiles_username_lower_unique on public.profiles(lower(username));

create or replace function public.touch_updated_at()
returns trigger language plpgsql security invoker as $$
begin new.updated_at = now(); return new; end $$;

do $$ begin
 create trigger profiles_touch_updated before update on public.profiles for each row execute function public.touch_updated_at();
exception when duplicate_object then null; end $$;
do $$ begin
 create trigger settings_touch_updated before update on public.profile_settings for each row execute function public.touch_updated_at();
exception when duplicate_object then null; end $$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
 requested_username text;
 safe_username text;
begin
 requested_username := lower(coalesce(new.raw_user_meta_data->>'username',''));
 if requested_username !~ '^[a-z0-9_-]{3,24}$' then
   requested_username := 'user_' || substr(replace(new.id::text,'-',''),1,12);
 end if;
 safe_username := requested_username;
 if exists(select 1 from public.profiles where username = safe_username) then
   safe_username := 'user_' || substr(replace(new.id::text,'-',''),1,12);
 end if;
 insert into public.profiles(user_id,username,display_name,email_verified)
 values(new.id,safe_username,coalesce(new.raw_user_meta_data->>'display_name',''),coalesce(new.email_confirmed_at is not null,false))
 on conflict (user_id) do nothing;
 insert into public.profile_settings(profile_id) select id from public.profiles where user_id=new.id
 on conflict do nothing;
 insert into public.diamond_balances(user_id,balance) values(new.id,0) on conflict do nothing;
 insert into public.user_preferences(user_id) values(new.id) on conflict do nothing;
 return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where user_id=(select auth.uid()) and role in ('ADMIN','OWNER') and account_status='ACTIVE')
$$;

create or replace function public.is_moderator()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where user_id=(select auth.uid()) and role in ('MODERATOR','ADMIN','OWNER') and account_status='ACTIVE')
$$;

alter table public.profile_themes enable row level security;
alter table public.sessions enable row level security;
alter table public.user_preferences enable row level security;
alter table public.profile_revisions enable row level security;
alter table public.profile_change_history enable row level security;
alter table public.blocks enable row level security;
alter table public.email_events enable row level security;
alter table public.feature_flags enable row level security;
alter table public.site_settings enable row level security;
alter table public.rate_limits enable row level security;

drop policy if exists "owner profile themes" on public.profile_themes;
create policy "owner profile themes" on public.profile_themes for all to authenticated
using (profile_id in (select id from public.profiles where user_id=(select auth.uid())))
with check (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "owner preferences" on public.user_preferences;
create policy "owner preferences" on public.user_preferences for all to authenticated
using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));

drop policy if exists "owner revisions" on public.profile_revisions;
create policy "owner revisions" on public.profile_revisions for select to authenticated
using (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "owner history" on public.profile_change_history;
create policy "owner history" on public.profile_change_history for select to authenticated
using (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "owner blocks" on public.blocks;
create policy "owner blocks" on public.blocks for all to authenticated
using (blocker_user_id=(select auth.uid())) with check (blocker_user_id=(select auth.uid()));

drop policy if exists "admin site settings" on public.site_settings;
create policy "admin site settings" on public.site_settings for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin feature flags" on public.feature_flags;
create policy "admin feature flags" on public.feature_flags for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "moderator reports" on public.reports;
create policy "moderator reports" on public.reports for select to authenticated
using (reporter_id=(select auth.uid()) or public.is_moderator());

grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_moderator() to authenticated;
