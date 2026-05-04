-- ============================================================
-- BOTIQUIM.BAR — Schema Supabase
-- Execute no SQL Editor do seu projeto Supabase
-- ============================================================

create extension if not exists "uuid-ossp";

-- ────────────────────────────────────────────────
-- TABELA: reservations
-- ────────────────────────────────────────────────
create table if not exists public.reservations (
  id            text primary key,
  name          text not null,
  phone         text not null,
  email         text,
  date          date not null,
  time          text not null,
  people        integer not null check (people >= 1 and people <= 20),
  ambiente      text not null check (ambiente in ('Interno', 'Mezanino')),
  mesa          text,
  ocasiao       text,
  obs           text,
  status        text not null default 'pending'
                  check (status in ('pending', 'confirmed', 'cancelled')),
  reject_reason text,
  reject_msg    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ────────────────────────────────────────────────
-- TABELA: tables
-- ────────────────────────────────────────────────
create table if not exists public.tables (
  id        text primary key,
  ambiente  text not null,
  capacity  integer not null,
  section   text,
  active    boolean default true
);

insert into public.tables (id, ambiente, capacity, section) values
  ('M01','Interno',2,'Salão principal'),('M02','Interno',2,'Salão principal'),
  ('M03','Interno',4,'Salão principal'),('M04','Interno',4,'Salão principal'),
  ('M05','Interno',4,'Salão principal'),('M06','Interno',6,'Salão principal'),
  ('M07','Interno',4,'Fundo'),('M08','Interno',6,'Fundo'),
  ('M09','Interno',8,'Fundo'),('M10','Interno',4,'Fundo'),
  ('Z01','Mezanino',2,'Varanda'),('Z02','Mezanino',2,'Varanda'),
  ('Z03','Mezanino',4,'Varanda'),('Z04','Mezanino',4,'Varanda'),
  ('Z05','Mezanino',6,'Área central'),('Z06','Mezanino',6,'Área central'),
  ('Z07','Mezanino',8,'Área central')
on conflict (id) do nothing;

-- ────────────────────────────────────────────────
-- TABELA: blocked_slots
-- ────────────────────────────────────────────────
create table if not exists public.blocked_slots (
  id         uuid primary key default uuid_generate_v4(),
  date       date,
  time       text,
  ambiente   text,
  reason     text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- ────────────────────────────────────────────────
-- TABELA: profiles
-- ────────────────────────────────────────────────
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text,
  email      text,
  role       text default 'manager' check (role in ('admin', 'manager')),
  active     boolean default true,
  created_at timestamptz default now()
);

-- ────────────────────────────────────────────────
-- TRIGGERS
-- ────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'role','manager')
  ) on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

drop trigger if exists set_reservations_updated_at on public.reservations;
create trigger set_reservations_updated_at
  before update on public.reservations
  for each row execute procedure public.set_updated_at();

-- ────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ────────────────────────────────────────────────
alter table public.reservations  enable row level security;
alter table public.tables        enable row level security;
alter table public.blocked_slots enable row level security;
alter table public.profiles      enable row level security;

-- Reservations
create policy "insert_public"   on public.reservations for insert with check (true);
create policy "select_auth"     on public.reservations for select using (auth.role()='authenticated');
create policy "update_auth"     on public.reservations for update using (auth.role()='authenticated');

-- Tables
create policy "select_public"   on public.tables for select using (true);
create policy "manage_auth"     on public.tables for all using (auth.role()='authenticated');

-- Blocked slots
create policy "select_public"   on public.blocked_slots for select using (true);
create policy "manage_auth"     on public.blocked_slots for all using (auth.role()='authenticated');

-- Profiles
create policy "own_profile"     on public.profiles for select using (auth.uid()=id);
create policy "admin_select"    on public.profiles for select using (
  exists(select 1 from public.profiles where id=auth.uid() and role='admin' and active=true)
);
create policy "admin_update"    on public.profiles for update using (
  exists(select 1 from public.profiles where id=auth.uid() and role='admin' and active=true)
);

-- ────────────────────────────────────────────────
-- FUNÇÃO RPC: ID único de reserva
-- ────────────────────────────────────────────────
create or replace function public.generate_reservation_id()
returns text as $$
declare new_id text; n int;
begin
  loop
    new_id := 'BOT-' || floor(1000+random()*8999)::text;
    select count(*) into n from public.reservations where id=new_id;
    exit when n=0;
  end loop;
  return new_id;
end;
$$ language plpgsql security definer;
