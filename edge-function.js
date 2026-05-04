// ═══════════════════════════════════════════════════════════════
//  edge-function.js — Supabase Edge Function para lembretes
//
//  Como configurar:
//  1. Instale Supabase CLI: npm install -g supabase
//  2. Login: supabase login
//  3. Crie a função: supabase functions new send-reminders
//  4. Substitua o conteúdo pelo código abaixo
//  5. Deploy: supabase functions deploy send-reminders
//  6. No painel do Supabase, vá em Edge Functions > Schedules
//     e adicione um cron: "0 * * * *" (roda todo hora)
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL'),
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
)

Deno.serve(async () => {
  try {
    // Busca configurações
    const { data: cfg } = await supabase.from('config').select('*').eq('id', 1).single()
    if (!cfg?.zapi_instance || !cfg?.zapi_token) {
      return new Response('Z-API não configurado', { status: 200 })
    }

    const now   = new Date()
    const hhmm  = now.getHours().toString().padStart(2,'0') + ':' + now.getMinutes().toString().padStart(2,'0')
    const today = now.toISOString().split('T')[0]
    const tomorrow = new Date(now)
    tomorrow.setDate(tomorrow.getDate() + 1)
    const tomorrowStr = tomorrow.toISOString().split('T')[0]

    let sent = 0

    // ── Lembrete D-1 (véspera) ──────────────────────────────
    if (cfg.lembrete_d1_ativo && hhmm === cfg.lembrete_d1_hora) {
      const { data: reservas } = await supabase
        .from('reservations')
        .select('*')
        .eq('date', tomorrowStr)
        .eq('status', 'confirmed')

      for (const r of reservas || []) {
        const msg = buildMsg(cfg.tpl_lembrete_d1, r, cfg)
        await sendWA(cfg, r.phone, msg)
        sent++
      }
    }

    // ── Lembrete dia da reserva ──────────────────────────────
    if (cfg.lembrete_dia_ativo && hhmm === cfg.lembrete_dia_hora) {
      const { data: reservas } = await supabase
        .from('reservations')
        .select('*')
        .eq('date', today)
        .eq('status', 'confirmed')

      for (const r of reservas || []) {
        const msg = buildMsg(cfg.tpl_lembrete_dia, r, cfg)
        await sendWA(cfg, r.phone, msg)
        sent++
      }
    }

    return new Response(JSON.stringify({ ok: true, sent, hora: hhmm }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})

function buildMsg(template, r, cfg) {
  const [y,m,d] = r.date.split('-')
  return template
    .replace(/{nome}/g,        r.name.split(' ')[0])
    .replace(/{restaurante}/g, cfg.restaurante_nome || 'Restaurante')
    .replace(/{data}/g,        `${d}/${m}/${y}`)
    .replace(/{hora}/g,        r.time)
    .replace(/{ambiente}/g,    r.ambiente)
    .replace(/{preferencia}/g, r.preferencia || r.mesa || 'Sem preferência')
    .replace(/{pessoas}/g,     r.people)
    .replace(/{codigo}/g,      r.id)
}

async function sendWA(cfg, phone, message) {
  const clean = '55' + phone.replace(/\D/g,'').replace(/^55/,'')
  await fetch(`https://api.z-api.io/instances/${cfg.zapi_instance}/token/${cfg.zapi_token}/send-text`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'client-token': cfg.zapi_client_token },
    body: JSON.stringify({ phone: clean, message })
  })
}
