-- App Ciudadana: primera tabla de reportes ciudadanos.
-- Ejecutar en Supabase > SQL Editor con una cuenta administradora del proyecto.
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 5 and 100),
  category text not null check (category in (
    'Calles y vías', 'Alumbrado público', 'Basura y limpieza',
    'Agua potable y fugas', 'Alcantarillado', 'Espacios públicos', 'Otro'
  )),
  description text not null check (char_length(trim(description)) between 15 and 1500),
  status text not null default 'pending' check (status in (
    'pending', 'received', 'in_review', 'assigned', 'in_progress', 'resolved', 'rejected'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reports_user_created_idx
  on public.reports (user_id, created_at desc);

alter table public.reports enable row level security;

-- Un ciudadano solo puede crear y consultar sus propios reportes.
drop policy if exists "Citizens can create own reports" on public.reports;
create policy "Citizens can create own reports"
  on public.reports for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Citizens can read own reports" on public.reports;
create policy "Citizens can read own reports"
  on public.reports for select to authenticated
  using (auth.uid() = user_id);

-- No se concede UPDATE ni DELETE a ciudadanos en esta primera etapa.
-- Los permisos de funcionarios/admin se incorporarán con perfiles y roles protegidos.
