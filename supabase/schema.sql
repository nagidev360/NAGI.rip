create extension if not exists pgcrypto;

do $$ begin
  create type public.plan_type as enum ('FREE','PREMIUM','VIP');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.profile_status as enum ('DRAFT','PUBLISHED','UNPUBLISHED','SUSPENDED');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null unique references auth.users(id) on delete cascade,
 username text not null unique,
 display_name text not null default '',
 bio text not null default '',
 avatar_url text,
 banner_url text,
 location text,
 website text,
 pronouns text,
 status public.profile_status not null default 'DRAFT',
 visibility text not null default 'PUBLIC' check (visibility in ('PUBLIC','PRIVATE','UNLISTED','SUSPENDED')),
 plan public.plan_type not null default 'FREE',
 theme_id text not null default 'Midnight',
 published_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.profile_settings (
 profile_id uuid primary key references public.profiles(id) on delete cascade,
 settings jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.links (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 title text not null,
 description text,
 url text not null,
 icon text,
 image text,
 thumbnail text,
 style text not null default 'Glass',
 position integer not null default 0,
 enabled boolean not null default true,
 open_new_tab boolean not null default true,
 nofollow boolean not null default false,
 start_at timestamptz,
 end_at timestamptz,
 timezone text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.social_links (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 platform text not null,
 url text not null,
 label text,
 tooltip text,
 position integer not null default 0,
 enabled boolean not null default true,
 style text not null default 'Icon',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.modules (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 type text not null,
 position integer not null default 0,
 settings jsonb not null default '{}'::jsonb,
 visibility boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.music_tracks (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 title text not null,
 artist text,
 cover_url text,
 audio_url text not null,
 autoplay_muted boolean not null default true,
 loop boolean not null default false,
 created_at timestamptz not null default now()
);

create table if not exists public.profile_views (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 visitor_hash text,
 device text,
 browser text,
 region text,
 created_at timestamptz not null default now()
);
create table if not exists public.analytics_events (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid not null references public.profiles(id) on delete cascade,
 event_type text not null,
 entity_id uuid,
 visitor_hash text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.link_clicks (
 id uuid primary key default gen_random_uuid(),
 link_id uuid not null references public.links(id) on delete cascade,
 profile_id uuid not null references public.profiles(id) on delete cascade,
 visitor_hash text,
 created_at timestamptz not null default now()
);
create table if not exists public.social_clicks (
 id uuid primary key default gen_random_uuid(),
 social_id uuid not null references public.social_links(id) on delete cascade,
 profile_id uuid not null references public.profiles(id) on delete cascade,
 visitor_hash text,
 created_at timestamptz not null default now()
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 type text not null,
 title text not null,
 message text not null,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.oauth_accounts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 provider text not null,
 provider_user_id text not null,
 created_at timestamptz not null default now(),
 unique(provider, provider_user_id)
);
create table if not exists public.subscriptions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 provider text not null,
 provider_subscription_id text unique,
 plan public.plan_type not null,
 status text not null,
 current_period_end timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 provider text not null,
 provider_payment_id text unique,
 amount_minor bigint not null,
 currency text not null default 'INR',
 status text not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.diamond_balances (
 user_id uuid primary key references auth.users(id) on delete cascade,
 balance bigint not null default 0 check (balance >= 0),
 updated_at timestamptz not null default now()
);
create table if not exists public.diamond_transactions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 amount bigint not null,
 type text not null,
 reference_id text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.custom_domains (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 profile_id uuid not null references public.profiles(id) on delete cascade,
 domain text not null unique,
 status text not null default 'Pending',
 verification_token text not null,
 verified_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid references auth.users(id) on delete set null,
 profile_id uuid references public.profiles(id) on delete cascade,
 category text not null,
 details text not null,
 status text not null default 'Open',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.tags (
 id uuid primary key default gen_random_uuid(),
 name text not null unique
);
create table if not exists public.profile_tags (
 profile_id uuid not null references public.profiles(id) on delete cascade,
 tag_id uuid not null references public.tags(id) on delete cascade,
 primary key(profile_id, tag_id)
);
create table if not exists public.audit_logs (
 id uuid primary key default gen_random_uuid(),
 actor_user_id uuid references auth.users(id) on delete set null,
 action text not null,
 target_type text,
 target_id uuid,
 result text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.admin_actions (
 id uuid primary key default gen_random_uuid(),
 actor_user_id uuid not null references auth.users(id) on delete cascade,
 action text not null,
 target_user_id uuid references auth.users(id) on delete set null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create index if not exists profiles_username_idx on public.profiles(lower(username));
create index if not exists links_profile_position_idx on public.links(profile_id, position);
create index if not exists social_profile_position_idx on public.social_links(profile_id, position);
create index if not exists modules_profile_position_idx on public.modules(profile_id, position);
create index if not exists views_profile_created_idx on public.profile_views(profile_id, created_at desc);
create index if not exists analytics_profile_created_idx on public.analytics_events(profile_id, created_at desc);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.profile_settings enable row level security;
alter table public.links enable row level security;
alter table public.social_links enable row level security;
alter table public.modules enable row level security;
alter table public.music_tracks enable row level security;
alter table public.profile_views enable row level security;
alter table public.analytics_events enable row level security;
alter table public.link_clicks enable row level security;
alter table public.social_clicks enable row level security;
alter table public.notifications enable row level security;
alter table public.oauth_accounts enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payments enable row level security;
alter table public.diamond_balances enable row level security;
alter table public.diamond_transactions enable row level security;
alter table public.custom_domains enable row level security;
alter table public.reports enable row level security;
alter table public.tags enable row level security;
alter table public.profile_tags enable row level security;
alter table public.audit_logs enable row level security;
alter table public.admin_actions enable row level security;

drop policy if exists "public published profiles" on public.profiles;
create policy "public published profiles" on public.profiles for select to anon, authenticated using (status='PUBLISHED' and visibility='PUBLIC');

drop policy if exists "owners manage profiles" on public.profiles;
create policy "owners manage profiles" on public.profiles for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

drop policy if exists "owners manage settings" on public.profile_settings;
create policy "owners manage settings" on public.profile_settings for all to authenticated using (profile_id in (select id from public.profiles where user_id=(select auth.uid()))) with check (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "public links" on public.links;
create policy "public links" on public.links for select to anon, authenticated using (enabled and profile_id in (select id from public.profiles where status='PUBLISHED' and visibility='PUBLIC'));
drop policy if exists "owners manage links" on public.links;
create policy "owners manage links" on public.links for all to authenticated using (profile_id in (select id from public.profiles where user_id=(select auth.uid()))) with check (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "public socials" on public.social_links;
create policy "public socials" on public.social_links for select to anon, authenticated using (enabled and profile_id in (select id from public.profiles where status='PUBLISHED' and visibility='PUBLIC'));
drop policy if exists "owners manage socials" on public.social_links;
create policy "owners manage socials" on public.social_links for all to authenticated using (profile_id in (select id from public.profiles where user_id=(select auth.uid()))) with check (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "public modules" on public.modules;
create policy "public modules" on public.modules for select to anon, authenticated using (visibility and profile_id in (select id from public.profiles where status='PUBLISHED' and visibility='PUBLIC'));
drop policy if exists "owners manage modules" on public.modules;
create policy "owners manage modules" on public.modules for all to authenticated using (profile_id in (select id from public.profiles where user_id=(select auth.uid()))) with check (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "owners manage music" on public.music_tracks;
create policy "owners manage music" on public.music_tracks for all to authenticated using (profile_id in (select id from public.profiles where user_id=(select auth.uid()))) with check (profile_id in (select id from public.profiles where user_id=(select auth.uid())));

drop policy if exists "owners notifications" on public.notifications;
create policy "owners notifications" on public.notifications for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists "owners diamonds" on public.diamond_balances;
create policy "owners diamonds" on public.diamond_balances for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists "owners diamond transactions" on public.diamond_transactions;
create policy "owners diamond transactions" on public.diamond_transactions for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists "owners domains" on public.custom_domains;
create policy "owners domains" on public.custom_domains for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
drop policy if exists "reports own" on public.reports;
create policy "reports own" on public.reports for insert to authenticated with check (reporter_id=(select auth.uid()));
drop policy if exists "tags public" on public.tags;
create policy "tags public" on public.tags for select to anon, authenticated using (true);
drop policy if exists "profile tags public" on public.profile_tags;
create policy "profile tags public" on public.profile_tags for select to anon, authenticated using (profile_id in (select id from public.profiles where status='PUBLISHED' and visibility='PUBLIC'));

grant select on public.profiles, public.links, public.social_links, public.modules, public.tags, public.profile_tags to anon;
grant select, insert, update, delete on public.profiles, public.profile_settings, public.links, public.social_links, public.modules, public.music_tracks, public.custom_domains to authenticated;
