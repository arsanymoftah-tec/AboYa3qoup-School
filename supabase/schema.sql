-- Abo Ya3qoup Professional schema
-- Run in Supabase SQL Editor on a new project or reconcile with your existing schema first.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'member' check (role in ('admin','servant','teacher','parent','member')),
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name, role, status)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'member', 'pending')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_active_member()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.status = 'active');
$$;
create or replace function public.is_active_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.status = 'active' and p.role = 'admin');
$$;

create table if not exists public.children (
 id uuid primary key default gen_random_uuid(), name text not null, code text, class_name text, stage text,
 parent_name text, parent_phone text, birth_date date, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.servants (
 id uuid primary key default gen_random_uuid(), name text not null, username text, code text, phone text,
 assigned_class text, status text not null default 'pending' check (status in ('pending','active','suspended')), notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.classes (
 id uuid primary key default gen_random_uuid(), name text not null, stage text, grade text, room text, servant_name text, description text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.attendance (
 id uuid primary key default gen_random_uuid(), person_name text not null, person_type text not null default 'child' check(person_type in ('child','servant')),
 class_name text, attendance_date date not null default current_date, status text not null default 'present' check(status in ('present','absent','late','excused')), notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(), title text not null, class_name text, subject text, exam_date date,
 duration_minutes integer, total_marks numeric, status text not null default 'draft' check(status in ('draft','published','closed')), description text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.announcements (
 id uuid primary key default gen_random_uuid(), title text not null, body text not null, target text not null default 'all',
 class_name text, publish_date date, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
do $$ declare t text; begin
 foreach t in array array['profiles','children','servants','classes','attendance','exams','announcements'] loop
   execute format('drop trigger if exists touch_updated_at on public.%I', t);
   execute format('create trigger touch_updated_at before update on public.%I for each row execute procedure public.touch_updated_at()', t);
 end loop;
end $$;

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.servants enable row level security;
alter table public.classes enable row level security;
alter table public.attendance enable row level security;
alter table public.exams enable row level security;
alter table public.announcements enable row level security;

drop policy if exists "profile self or admin read" on public.profiles;
create policy "profile self or admin read" on public.profiles for select to authenticated using (id = auth.uid() or public.is_active_admin());
drop policy if exists "profile self update safe fields" on public.profiles;
create policy "profile self update safe fields" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = (select p.role from public.profiles p where p.id = auth.uid()) and status = (select p.status from public.profiles p where p.id = auth.uid()));
drop policy if exists "admin manage profiles" on public.profiles;
create policy "admin manage profiles" on public.profiles for all to authenticated using (public.is_active_admin()) with check (public.is_active_admin());

do $$ declare t text; begin
 foreach t in array array['children','servants','classes','attendance','exams','announcements'] loop
   execute format('drop policy if exists "active members read" on public.%I', t);
   execute format('create policy "active members read" on public.%I for select to authenticated using (public.is_active_member())', t);
   execute format('drop policy if exists "admin insert" on public.%I', t);
   execute format('create policy "admin insert" on public.%I for insert to authenticated with check (public.is_active_admin())', t);
   execute format('drop policy if exists "admin update" on public.%I', t);
   execute format('create policy "admin update" on public.%I for update to authenticated using (public.is_active_admin()) with check (public.is_active_admin())', t);
   execute format('drop policy if exists "admin delete" on public.%I', t);
   execute format('create policy "admin delete" on public.%I for delete to authenticated using (public.is_active_admin())', t);
 end loop;
end $$;

-- IMPORTANT: after creating your first account, promote it to admin from SQL Editor:
-- update public.profiles set role='admin', status='active' where id=(select id from auth.users where email='YOUR_EMAIL');
-- Do not enable public signups unless you intend to allow registration; new accounts remain pending by default.
