-- ═══════════════════════════════════════════════════════════════
--  schema-v2.sql — Execute no SQL Editor do Supabase
--  Rode APÓS o schema.sql e schema-update.sql anteriores
-- ═══════════════════════════════════════════════════════════════

-- ── Novas colunas em reservations ────────────────────────────
alter table public.reservations
  add column if not exists origin      text default 'online' check (origin in ('online','telefone','presencial','instagram','outro')),
  add column if not exists edited_by   uuid references auth.users(id),
  add column if not exists edited_at   timestamptz,
  add column if not exists preferencia text;

-- ── Tabela: config ───────────────────────────────────────────
create table if not exists public.config (
  id                    int primary key default 1 check (id = 1), -- linha única
  restaurante_nome      text default 'Botiquim.bar',
  zapi_instance         text,
  zapi_token            text,
  zapi_client_token     text,
  manager_phone         text,
  owner_phone           text,
  site_url              text,
  -- Templates de mensagem
  tpl_confirmacao       text default 'Olá, {nome}! ✅ Sua reserva no *{restaurante}* está confirmada.\n\n📅 {data} às {hora}\n📍 {ambiente} — {preferencia}\n👥 {pessoas} pessoas\n🔑 Código: {codigo}\n\nNos vemos lá! 🍺',
  tpl_recusa            text default 'Olá, {nome}. Infelizmente não conseguimos confirmar sua reserva para {data} às {hora}.\n\nMotivo: {motivo}\n\nQualquer dúvida, fale com a gente! 🍺',
  tpl_lembrete_d1       text default 'Olá, {nome}! 👋 Lembrando que amanhã você tem reserva no *{restaurante}*.\n\n📅 {data} às {hora}\n📍 {ambiente} — {preferencia}\n👥 {pessoas} pessoas\n\nAté lá! 🍺',
  tpl_lembrete_dia      text default 'Bom dia, {nome}! ☀️ Hoje é o dia da sua reserva no *{restaurante}*!\n\n🕐 Às {hora}\n📍 {ambiente} — {preferencia}\n\nNos vemos hoje! 🍺',
  tpl_evento            text default 'Olá, {nome}! 🎉 Além da sua reserva, hoje tem *{evento}* no {restaurante}!\n\n{descricao}\n\nVem com a galera! 🍺',
  -- Horários dos lembretes (HH:MM)
  lembrete_d1_hora      text default '18:00',
  lembrete_dia_hora     text default '10:00',
  -- Lembretes ativos
  lembrete_d1_ativo     boolean default true,
  lembrete_dia_ativo    boolean default true,
  updated_at            timestamptz default now()
);

-- Insere linha padrão se não existir
insert into public.config (id) values (1) on conflict (id) do nothing;

-- ── Tabela: events ───────────────────────────────────────────
create table if not exists public.events (
  id           uuid primary key default uuid_generate_v4(),
  nome         text not null,
  descricao    text,
  flyer_url    text,
  recorrencia  text not null check (recorrencia in ('semanal','mensal','unica')),
  dia_semana   int,             -- 0=Dom,1=Seg...6=Sab (para recorrencia semanal)
  dia_mes      int,             -- para recorrencia mensal
  data_unica   date,            -- para recorrencia unica
  horario      text,
  ativo        boolean default true,
  created_by   uuid references auth.users(id),
  created_at   timestamptz default now()
);

-- ── Tabela: permissions ──────────────────────────────────────
create table if not exists public.permissions (
  id           int primary key default 1 check (id = 1),
  admin        jsonb default '{"aprovar":true,"criar_manual":true,"editar":true,"cancelar":true,"historico":true,"mapa":true,"semanal":true,"eventos":true,"equipe":true,"config":false}'::jsonb,
  gerente      jsonb default '{"aprovar":true,"criar_manual":true,"editar":true,"cancelar":true,"historico":true,"mapa":true,"semanal":true,"eventos":false,"equipe":false,"config":false}'::jsonb,
  staff        jsonb default '{"aprovar":false,"criar_manual":false,"editar":false,"cancelar":false,"historico":false,"mapa":true,"semanal":false,"eventos":false,"equipe":false,"config":false}'::jsonb
);

insert into public.permissions (id) values (1) on conflict (id) do nothing;

-- ── Tabela: action_logs ──────────────────────────────────────
create table if not exists public.action_logs (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid references auth.users(id),
  user_name      text,
  action         text not null,  -- 'approve','reject','edit','cancel','create_manual'
  reservation_id text references public.reservations(id),
  details        jsonb,
  created_at     timestamptz default now()
);

-- ── RLS ──────────────────────────────────────────────────────
alter table public.config      enable row level security;
alter table public.events      enable row level security;
alter table public.permissions enable row level security;
alter table public.action_logs enable row level security;

-- Config: qualquer autenticado lê, só master/admin escreve
create policy "auth_read_config"   on public.config for select using (auth.role()='authenticated');
create policy "auth_write_config"  on public.config for update using (auth.role()='authenticated');

-- Events: público lê (para mostrar no formulário futuramente), autenticado escreve
create policy "public_read_events" on public.events for select using (true);
create policy "auth_write_events"  on public.events for all using (auth.role()='authenticated');

-- Permissions: autenticado lê e escreve
create policy "auth_read_perms"    on public.permissions for select using (auth.role()='authenticated');
create policy "auth_write_perms"   on public.permissions for update using (auth.role()='authenticated');

-- Logs: autenticado lê e insere
create policy "auth_read_logs"     on public.action_logs for select using (auth.role()='authenticated');
create policy "auth_insert_logs"   on public.action_logs for insert with check (auth.role()='authenticated');

-- ── Função: buscar eventos do dia ────────────────────────────
create or replace function public.get_events_for_date(target_date date)
returns setof public.events as $$
begin
  return query
  select * from public.events
  where ativo = true
  and (
    (recorrencia = 'semanal'  and dia_semana = extract(dow from target_date)::int)
    or (recorrencia = 'mensal' and dia_mes   = extract(day from target_date)::int)
    or (recorrencia = 'unica'  and data_unica = target_date)
  );
end;
$$ language plpgsql security definer;

grant execute on function public.get_events_for_date(date) to authenticated;
