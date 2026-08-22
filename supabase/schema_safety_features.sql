-- Her Campus safety features — run once in Supabase SQL Editor.
-- Dashboard → SQL → New query → paste → Run.

create extension if not exists "pgcrypto";

-- App profile (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique not null,
  display_name text,
  role text not null default 'student',
  campus_name text,
  last_lat double precision,
  last_lng double precision,
  last_location_at timestamptz,
  sharing_location boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_authenticated"
  on public.profiles for select to authenticated using (true);

create policy "profiles_insert_own"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    lower(new.email),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'student')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trusted circle
create table if not exists public.trusted_circle (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  member_id uuid not null references public.profiles (id) on delete cascade,
  label_name text not null,
  created_at timestamptz not null default now(),
  unique (owner_id, member_id)
);

alter table public.trusted_circle enable row level security;

create policy "trusted_owner_all"
  on public.trusted_circle for all to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "trusted_member_read"
  on public.trusted_circle for select to authenticated
  using (auth.uid() = member_id);

-- Buddy walk requests
create table if not exists public.buddy_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  destination text not null,
  campus_name text,
  lat double precision not null,
  lng double precision not null,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

alter table public.buddy_requests enable row level security;

create policy "buddy_requests_select_auth"
  on public.buddy_requests for select to authenticated using (true);

create policy "buddy_requests_insert_own"
  on public.buddy_requests for insert to authenticated
  with check (auth.uid() = requester_id);

create policy "buddy_requests_update_own"
  on public.buddy_requests for update to authenticated
  using (auth.uid() = requester_id);

-- In-app notifications for nearby students
create table if not exists public.buddy_notifications (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.buddy_requests (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  message text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.buddy_notifications enable row level security;

create policy "buddy_notif_select_own"
  on public.buddy_notifications for select to authenticated
  using (auth.uid() = recipient_id);

create policy "buddy_notif_insert_auth"
  on public.buddy_notifications for insert to authenticated
  with check (true);

create policy "buddy_notif_update_own"
  on public.buddy_notifications for update to authenticated
  using (auth.uid() = recipient_id);

-- Peer escort volunteers (admin-managed)
create table if not exists public.escort_volunteers (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  display_name text,
  campus_name text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.escort_volunteers enable row level security;

create policy "escort_volunteers_select_auth"
  on public.escort_volunteers for select to authenticated using (true);

create policy "escort_volunteers_write_auth"
  on public.escort_volunteers for all to authenticated
  using (true)
  with check (true);

-- Peer escort student requests
create table if not exists public.escort_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  destination text not null,
  note text not null default '',
  status text not null default 'pending',
  volunteer_email text,
  created_at timestamptz not null default now()
);

alter table public.escort_requests enable row level security;

create policy "escort_requests_select_auth"
  on public.escort_requests for select to authenticated using (true);

create policy "escort_requests_insert_own"
  on public.escort_requests for insert to authenticated
  with check (auth.uid() = student_id);

create policy "escort_requests_update_auth"
  on public.escort_requests for update to authenticated
  using (true);
