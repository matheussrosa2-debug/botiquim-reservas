// ═══════════════════════════════════════════════════════════════════
//  config.js — Configuração do restaurante
//  Edite APENAS este arquivo para adaptar a um novo cliente.
//  Os demais arquivos HTML leem tudo daqui automaticamente.
// ═══════════════════════════════════════════════════════════════════

const CONFIG = {

  // ── Identidade ───────────────────────────────────────────────────
  restaurante:  'Botiquim.bar',
  logoLetra:    'B',
  logoUrl:      'imagens/Logo_Em_Alta_Botiquim.png',

  // ── Supabase ─────────────────────────────────────────────────────
  supabaseUrl:     'https://XXXX.supabase.co',
  supabaseKey:     'eyJhbGc...',      // anon key
  supabaseService: 'eyJhbGc...',      // service_role key (só no painel)

  // ── Z-API WhatsApp ────────────────────────────────────────────────
  zapiInstance:    'SUA_INSTANCIA',
  zapiToken:       'SEU_TOKEN',
  zapiClientToken: 'SEU_CLIENT_TOKEN',
  managerPhone:    '5511999999999',   // DDI + DDD + número, sem símbolos

  // ── URLs do sistema ───────────────────────────────────────────────
  loginUrl:     'botiquim-login.html',
  confirmarUrl: 'https://SEU-PROJETO.vercel.app/confirmar.html',

  // ── Horários disponíveis para reserva ─────────────────────────────
  horarios: [
    '11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00',
    '18:00','18:30','19:00','19:30','20:00','20:30','21:00',
    '21:30','22:00','22:30','23:00',
  ],

  // ── Ocasiões ──────────────────────────────────────────────────────
  ocasioes: [
    '🍽️ Jantar casual',
    '🎂 Aniversário',
    '💍 Pedido de casamento',
    '💑 Encontro romântico',
    '👥 Reunião de amigos',
    '💼 Reunião de negócios',
    '🎉 Comemoração',
    '👨‍👩‍👧 Almoço em família',
    '🥳 Happy hour',
    '🎓 Formatura',
    'Outro',
  ],

  // ── Layout do restaurante ─────────────────────────────────────────
  //
  //  Como personalizar:
  //  • Adicione ou remova itens em 'ambientes' para mudar os ambientes
  //  • Dentro de cada ambiente, adicione ou remova 'secoes'
  //  • Dentro de cada seção, adicione ou remova 'mesas'
  //  • 'capacidade' é o número de pessoas que cabem naquela mesa
  //  • 'id' é o código da mesa (ex: M01, Z01, T01) — deve ser único
  //
  ambientes: [
    {
      id:         'interno',
      nome:       'Interno',
      icon:       '🪑',
      capacidade:  40,           // capacidade total do ambiente (para o formulário do cliente)
      secoes: [
        {
          nome:  'Salão Principal',
          mesas: [
            { id: 'M01', capacidade: 2 },
            { id: 'M02', capacidade: 2 },
            { id: 'M03', capacidade: 4 },
            { id: 'M04', capacidade: 4 },
            { id: 'M05', capacidade: 4 },
            { id: 'M06', capacidade: 6 },
          ],
        },
        {
          nome:  'Fundo',
          mesas: [
            { id: 'M07', capacidade: 4 },
            { id: 'M08', capacidade: 6 },
            { id: 'M09', capacidade: 8 },
            { id: 'M10', capacidade: 4 },
          ],
        },
      ],
    },
    {
      id:         'mezanino',
      nome:       'Mezanino',
      icon:       '🏛️',
      capacidade:  20,
      secoes: [
        {
          nome:  'Varanda',
          mesas: [
            { id: 'Z01', capacidade: 2 },
            { id: 'Z02', capacidade: 2 },
            { id: 'Z03', capacidade: 4 },
            { id: 'Z04', capacidade: 4 },
          ],
        },
        {
          nome:  'Área Central',
          mesas: [
            { id: 'Z05', capacidade: 6 },
            { id: 'Z06', capacidade: 6 },
            { id: 'Z07', capacidade: 8 },
          ],
        },
      ],
    },
  ],

}
