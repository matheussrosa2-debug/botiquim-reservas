# Botiquim.bar — Sistema de Reservas
## Guia de Configuração Completo

---

## 📁 Arquivos do sistema

| Arquivo | Descrição |
|---|---|
| `schema.sql` | Script do banco de dados (Supabase) |
| `botiquim-reservas.html` | Plataforma pública de reservas |
| `botiquim-login.html` | Tela de login do gerente |
| `botiquim-painel.html` | Painel de gestão de reservas |
| `botiquim-usuarios.html` | Gestão de usuários (admin) |
| `webhook-zapi.js` | Servidor Node.js para lembretes automáticos |

---

## 🚀 Passo a passo

### ETAPA 1 — Banco de dados (Supabase)

1. Acesse seu projeto em supabase.com
2. Vá em **SQL Editor** e execute o conteúdo de `schema.sql`
3. Em **Authentication → URL Configuration**, adicione a URL dos HTMLs à lista de "Redirect URLs"
4. Em **Database → Replication**, ative a tabela `reservas` para notificações em tempo real

### ETAPA 2 — Criar o primeiro usuário admin

1. No Supabase: **Authentication → Users → Add user → Create new user**
2. Informe e-mail e senha do gerente principal
3. Em **Table Editor → profiles**, mude o campo `role` deste usuário para `admin`

### ETAPA 3 — Configurar credenciais nos arquivos HTML

Substitua em **todos os arquivos HTML**:

```
SUPABASE_URL = 'https://SEU_PROJETO.supabase.co'
SUPABASE_KEY = 'SUA_ANON_KEY'
```

Encontre em: Supabase → Settings → API

Nos arquivos botiquim-reservas.html e botiquim-painel.html, configure também:

```
ZAPI_INSTANCE = 'SUA_INSTANCIA_ZAPI'
ZAPI_TOKEN    = 'SEU_TOKEN_ZAPI'
TEL_GERENTE   = '5511999999999'
```

### ETAPA 4 — Hospedar os arquivos HTML

Qualquer hospedagem estática serve:
- Netlify: arraste a pasta para app.netlify.com
- Vercel: vercel deploy
- GitHub Pages, Cloudflare Pages

Após hospedar, adicione a URL no Supabase (Authentication → URL Configuration → Redirect URLs).

### ETAPA 5 — Servidor de webhook (opcional)

Necessário para lembretes automáticos e respostas SIM/NÃO dos clientes.

Instale:
  npm install express @supabase/supabase-js node-cron dotenv

Crie arquivo .env:
  SUPABASE_URL=https://SEU_PROJETO.supabase.co
  SUPABASE_SERVICE_KEY=SUA_SERVICE_ROLE_KEY
  ZAPI_INSTANCE=SUA_INSTANCIA_ZAPI
  ZAPI_TOKEN=SEU_TOKEN_ZAPI
  PORT=3000

IMPORTANTE: Use a service_role key apenas no servidor, nunca nos HTMLs.

Inicie:
  node webhook-zapi.js

Configure o webhook na Z-API apontando para:
  POST https://SEU_SERVIDOR/webhook/zapi

---

## 🔑 Fluxo completo

Cliente → botiquim-reservas.html → Salva no Supabase → WhatsApp para gerente
Gerente → botiquim-login.html → botiquim-painel.html → Aprova/Recusa → WhatsApp para cliente
Servidor (cron 11h) → Lembrete 24h → Cliente responde SIM/NÃO → Atualiza banco

---

## 📱 Links para a bio

- Reservas: https://seusite.com/botiquim-reservas.html
- Painel (interno): https://seusite.com/botiquim-login.html

---

*Sistema botiquim.bar v1.0*
