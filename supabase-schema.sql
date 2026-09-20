-- Supabase schema for the fitness tracker app
-- Run this in Supabase SQL editor.

create extension if not exists "uuid-ossp";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '사용자',
  subtitle text not null default '나만의 건강 기록을 관리하세요',
  daily_calories integer not null default 1900,
  daily_carb integer not null default 95,
  daily_protein integer not null default 190,
  daily_fat integer not null default 84,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_date date not null,
  name text not null,
  calories integer not null default 0,
  carbs double precision not null default 0,
  protein double precision not null default 0,
  fat double precision not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exercises (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise_date date not null,
  name text not null,
  minutes integer not null default 0,
  burned_calories integer not null default 0,
  protein_bonus integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
before update on public.profiles
for each row execute procedure public.handle_updated_at();

create trigger meals_updated_at
before update on public.meals
for each row execute procedure public.handle_updated_at();

create trigger exercises_updated_at
before update on public.exercises
for each row execute procedure public.handle_updated_at();

-- Profiles row creation after signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, subtitle)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', '사용자'), '나만의 건강 기록을 관리하세요');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS policies
alter table public.profiles enable row level security;
alter table public.meals enable row level security;
alter table public.exercises enable row level security;

create policy "Users can view own profile"
on public.profiles
for select
using (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own meals"
on public.meals
for insert
with check (auth.uid() = user_id);

create policy "Users can update own meals"
on public.meals
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own meals"
on public.meals
for delete
using (auth.uid() = user_id);

create policy "Users can select own meals"
on public.meals
for select
using (auth.uid() = user_id);

create policy "Users can insert own exercises"
on public.exercises
for insert
with check (auth.uid() = user_id);

create policy "Users can update own exercises"
on public.exercises
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own exercises"
on public.exercises
for delete
using (auth.uid() = user_id);

create policy "Users can select own exercises"
on public.exercises
for select
using (auth.uid() = user_id);

-- Helpful view for daily totals
create or replace view public.daily_summary as
select
  m.user_id,
  m.meal_date as log_date,
  coalesce(sum(m.calories), 0) as calories,
  coalesce(sum(m.carbs), 0) as carbs,
  coalesce(sum(m.protein), 0) as protein,
  coalesce(sum(m.fat), 0) as fat,
  coalesce(sum(e.burned_calories), 0) as burned_calories,
  coalesce(sum(e.minutes), 0) as exercise_minutes
from public.meals m
full join public.exercises e
  on m.user_id = e.user_id and m.meal_date = e.exercise_date
group by m.user_id, m.meal_date;

-- Example queries:
-- select * from public.profiles where id = auth.uid();
-- select * from public.meals where user_id = auth.uid() order by meal_date desc;
-- select * from public.exercises where user_id = auth.uid() order by exercise_date desc;
