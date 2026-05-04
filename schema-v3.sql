-- ═══════════════════════════════════════════════════════════════
--  schema-v3.sql — Execute no SQL Editor do Supabase
--  Adiciona posições das mesas e configurações de reserva
-- ═══════════════════════════════════════════════════════════════

-- Novas colunas na tabela config
alter table public.config
  add column if not exists reserva_min_pessoas   int  default 1,
  add column if not exists reserva_max_pessoas   int  default 20,
  add column if not exists reserva_antecedencia  int  default 0,   -- minutos mínimos de antecedência
  add column if not exists funcionamento_inicio  text default '11:30',
  add column if not exists funcionamento_fim     text default '23:00';

-- Tabela de posições das mesas no mapa
create table if not exists public.mesa_positions (
  id          uuid primary key default uuid_generate_v4(),
  ambiente_id text not null,   -- ex: 'interno', 'mezanino'
  mesa_id     text not null,   -- ex: 'M01', 'Z03'
  x           float not null default 50,  -- posição % horizontal
  y           float not null default 50,  -- posição % vertical
  map_image   text,            -- URL da imagem de fundo do ambiente
  updated_at  timestamptz default now(),
  unique(ambiente_id, mesa_id)
);

alter table public.mesa_positions enable row level security;

create policy "auth_read_positions"  on public.mesa_positions for select using (auth.role()='authenticated');
create policy "auth_write_positions" on public.mesa_positions for all   using (auth.role()='authenticated');

-- Função para upsert de posição
create or replace function public.upsert_mesa_position(
  p_ambiente_id text, p_mesa_id text, p_x float, p_y float
) returns void as $$
begin
  insert into public.mesa_positions (ambiente_id, mesa_id, x, y, updated_at)
  values (p_ambiente_id, p_mesa_id, p_x, p_y, now())
  on conflict (ambiente_id, mesa_id)
  do update set x=p_x, y=p_y, updated_at=now();
end;
$$ language plpgsql security definer;

grant execute on function public.upsert_mesa_position(text,text,float,float) to authenticated;

-- Atualiza config com defaults novos
update public.config set
  reserva_min_pessoas  = coalesce(reserva_min_pessoas,  1),
  reserva_max_pessoas  = coalesce(reserva_max_pessoas,  20),
  reserva_antecedencia = coalesce(reserva_antecedencia, 0),
  funcionamento_inicio = coalesce(funcionamento_inicio, '11:30'),
  funcionamento_fim    = coalesce(funcionamento_fim,    '23:00')
where id = 1;
