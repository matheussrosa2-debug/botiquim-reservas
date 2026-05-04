-- ═══════════════════════════════════════════════════════════════
--  schema-update.sql
--  Execute no SQL Editor do Supabase para habilitar
--  a confirmação via WhatsApp
-- ═══════════════════════════════════════════════════════════════

-- Adiciona token de confirmação na tabela de reservas
alter table public.reservations
  add column if not exists confirm_token text;

-- Função RPC: confirma reserva com token (sem precisar de login)
-- O token é gerado no momento da reserva e enviado apenas ao gerente via WhatsApp
create or replace function public.confirm_reservation(res_id text, token text)
returns json as $$
declare
  res record;
begin
  -- Busca a reserva
  select * into res from public.reservations
  where id = res_id and confirm_token = token and status = 'pending';

  if not found then
    return json_build_object('ok', false, 'msg', 'Reserva não encontrada ou já processada.');
  end if;

  -- Confirma
  update public.reservations
  set status = 'confirmed', updated_at = now()
  where id = res_id;

  return json_build_object(
    'ok',      true,
    'name',    res.name,
    'date',    res.date,
    'time',    res.time,
    'people',  res.people,
    'ambiente',res.ambiente,
    'mesa',    res.mesa,
    'phone',   res.phone,
    'ocasiao', res.ocasiao
  );
end;
$$ language plpgsql security definer;
