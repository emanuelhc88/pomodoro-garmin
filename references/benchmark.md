# Toma — Competitive Benchmark

> Síntese da pesquisa sobre apps Pomodoro existentes na Connect IQ Store. Define os gaps competitivos e o roadmap pós-V1.

Pesquisa feita em **2026-05-06** via WebFetch e WebSearch nos sites oficiais Garmin (apps.garmin.com), forum (forums.garmin.com), GitHub e Reddit. **10 apps Pomodoro identificados.**

---

## 1. Apps mapeados

| # | Nome | Link | Tipo | Preço | Avaliação |
|---|---|---|---|---|---|
| 1 | Pomodoro Timer | [link](https://apps.garmin.com/en-US/apps/7fae9d35-93d5-4e15-9c84-e2226448dec6) | App | Free | n/d |
| 2 | Pomodoro Productivity Timer (WorkTimeLogger) | [link](https://apps.garmin.com/en-US/apps/28456453-f3f4-4a6b-b134-8aef7e83e879) | App | Free | "best UX" (sem rating) |
| 3 | PomoMin | [link](https://apps.garmin.com/apps/66e318e7-cae6-4052-90c6-65bd58092202) | App | Free | n/d |
| 4 | Pomodoro (genérico) | [link](https://apps.garmin.com/en-US/apps/4b11ad8f-3e48-4112-83df-336065c49829) | App | Free | n/d |
| 5 | Pomodoro Sprints | [link](https://apps.garmin.com/en-US/apps/83977225-664d-4d89-ad2c-7ba00edafeef) | App | Free | n/d |
| 6 | Pomodoro Pro | [link](https://apps.garmin.com/apps/8769a6fc-42bd-42a3-8885-af6dba6a1731) | App | Pago (provável) | n/d |
| 7 | Pomodoro App | [link](https://apps.garmin.com/en-US/apps/283cf898-c1a5-4dfb-b71a-ad4e957c5748) | App | Free | n/d |
| 8 | Pomodoro Scripts | [link](https://apps.garmin.com/apps/3c28bd37-7e7b-4bc4-aff5-16f3d997bc9e) | Widget/DF | Free | n/d |
| 9 | Tomato Timer | [link](https://apps.garmin.com/apps/85a547a3-e3e0-4f69-87aa-c3f4528ca729) | App | Free | n/d |
| 10 | Garmodoro (open source) | [github](https://github.com/klimeryk/garmodoro) | App | Free | n/d (8 issues abertas) |

---

## 2. Matriz de features

| Feature | #1 | #2 (WorkTime) | #3 | #4 | #5 | #6 | #7 | #8 | #9 | #10 (Garmodoro) | **Toma V1** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Timer ajustável | ✅ | ✅ | ? | ❌ (fixo 25/5) | ? | ? | ? | ? | ? | ✅ | ✅ |
| Múltiplos presets | ❌ | ❌ | ❌ | ❌ | ❌ | ? | ❌ | ❌ | ❌ | ❌ | ✅ (4 presets) |
| Vibração | ✅ | ✅ | ? | ✅ | ? | ? | ? | ? | ✅ | ✅ | ✅ |
| Som | ✅ | ✅ | ? | ✅ | ? | ? | ? | ? | ✅ | ✅ | ✅ |
| Pause/Resume | ? | ✅ | ? | ✅ | ? | ? | ? | ? | ? | ✅ | ✅ |
| Stop | ? | ✅ | ? | ✅ | ? | ? | ? | ? | ? | ✅ | ✅ |
| Contagem sessões | ✅ | ✅ | ? | ✅ | ? | ? | ? | ? | ✅ | ✅ | ✅ |
| Long break | ✅ | ✅ | ? | ❌ | ? | ? | ? | ? | ? | ✅ | ✅ |
| Histórico persistente | ❌ | ✅ (web) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (local) |
| **Gravar como FIT activity** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ ⭐ |
| Settings via Garmin Connect mobile | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ (V2) |
| Companion mobile app | ❌ | ❌ (só web) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ (V2) |
| Cloud sync | ❌ | ✅ (worktimelogger.com) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ (V2) |
| Estatísticas avançadas | ❌ | parcial (web) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ (V2) |
| Identidade visual cuidada | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ ⭐ |
| Multi-device responsivo (S/M/L) | parcial | parcial | ? | parcial | ? | ? | ? | ? | parcial | ✅ | ✅ |
| Open source | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | TBD |

⭐ = diferencial competitivo único do Toma V1.

---

## 3. Gaps no ecossistema

### 3.1 Gap principal (V1 ataca)

**Nenhum app grava sessões como activity FIT no Garmin Connect.** Isso significa que usuários:
- Não veem suas sessões de foco no histórico do Garmin Connect.
- Não podem correlacionar produtividade com HR, sono, stress.
- Não acumulam estatísticas no ecossistema Garmin que já usam.

**Toma V1 resolve isso.** Cada sessão concluída = 1 activity "Focus" no Garmin Connect, com HR, duração, calorias.

### 3.2 Gap de identidade visual

Todos os apps têm UI genérica — fonte default, cores arbitrárias, layouts não responsivos. **Toma V1 oferece identidade premium** baseada no manual de marca já definido (paleta dark + tipografia técnica + tom de voz direto).

### 3.3 Gaps que a V1 NÃO ataca (roadmap)

Documentar para futuras versões:

#### V2 (próximas 8-12 semanas após V1)

- **Companion mobile app (iOS + Android)** — gap mais citado em forums. Configuração via celular, dashboard de estatísticas. Stack provável: React Native ou nativo + Garmin Connect IQ Companion APIs.
- **Settings via Garmin Connect mobile** — alternativa mais simples ao companion: usar o sistema de settings do Garmin Connect que já existe (XML em `resources/settings/`). Permite editar settings via app oficial.
- **Estatísticas avançadas** — gráficos de sessões por dia/semana/mês, streaks, time-of-day patterns. Pode viver no companion ou no próprio relógio (limitado).
- **Soundscapes / white noise** — durante sessão de foco. Requer áudio (`hasSpeaker`).
- **Goal setting** — "8 pomodoros today". Simples; pode entrar mesmo na V1.x se houver demanda.

#### V3 (post V2)

- **Integrações third-party** — Notion, Todoist, Google Calendar, Linear. Requer companion mobile com OAuth.
- **Cloud sync entre múltiplos relógios** — usuários com FR + Fenix querem stats unificadas.
- **Gamification leve** — streaks, achievements. Cuidado com o tom da marca: nada de confetti.
- **Modo enfoque + DND** — bloquear notificações durante sessão. Limitado pelo que o Garmin permite via API.

---

## 4. Reclamações comuns dos usuários (forums)

Coletadas de:
- [forums.garmin.com — Pomodoro Timer Request](https://forums.garmin.com/sports-fitness/sports-fitness/f/vivomove-luxe-style/346339/request-pomodoro-timer-repeat-timers)
- [Reddit r/Garmin — diversos threads]
- [GitHub klimeryk/garmodoro — issues](https://github.com/klimeryk/garmodoro/issues)

| Reclamação | Frequência | Toma V1 resolve? |
|---|---|---|
| App reinicia ao bloquear tela | Alta | Parcial — recovery via Storage (item 6 do garmin_platform.md) |
| Vibração inconsistente entre devices | Alta | Parcial — capability detection + perfis testados |
| Sem long break customizável | Média | ✅ — preset 50/10 e Custom permitem |
| Sem histórico persistente | Alta | ✅ — Storage local de 50 sessões |
| Não integra com Garmin Connect | **Universal** | ✅ — FIT activity recording |
| UI genérica, ilegível em sol forte (MIP) | Média | ✅ — design system com contraste validado |
| Sem feedback visual claro de fase | Média | ✅ — anel colorido por fase + label uppercase |
| Confunde se está em work ou break | Média | ✅ — cores distintas + label sempre visível |

---

## 5. Posicionamento Toma

**Tagline:** "Pomodoro. Sem ornamento. Para quem escreve código."

**Diferenciais V1:**
1. **Único** que grava como activity Garmin Connect.
2. **Único** com identidade visual cuidada (Toma brand).
3. 4 presets + custom — mais flexibilidade que a maioria.
4. Histórico local persistente.
5. Multi-device responsivo (FR255S a Venu 3).

**Anti-posicionamento:**
- Não é gamificado.
- Não tem mascote.
- Não é colorido.
- Não tem mensagens motivacionais.

---

## 6. Estratégia de publicação Connect IQ Store

### 6.1 Categoria

- Categoria: **Productivity** (existente na Store).
- Tags: pomodoro, focus, productivity, timer, work.

### 6.2 Descrição (draft)

```
TOMA — Pomodoro for developers.

Time-block your work in clean, focused sessions. Toma is a no-nonsense
Pomodoro timer for Garmin watches with four presets, custom durations,
and full Garmin Connect integration.

Features
- 4 presets: 25/5, 30/5, 50/10, custom
- Each session recorded as a Garmin activity
- Local history of last 50 sessions
- Vibration alerts for phase transitions
- Optional sound (devices with speaker)
- Pause / resume / stop with confirmation
- Multi-language: English, Portuguese
- Works on Forerunner 255+, Fenix 7+, Venu 3, and more

No ads. No tracking. No nonsense.
```

### 6.3 Screenshots (preparar)

1. Home / Preset Picker.
2. Timer running (Focus, anel brand).
3. Cycle Complete (anel accent + contagem).
4. History list.
5. Settings menu.

### 6.4 Hero image

Logo Toma centralizado em `#0C0C0C`, 500×500 PNG.

### 6.5 Estratégia de preço

- **V1: Free.** Construir base de usuários, coletar feedback.
- **V2: Free + Premium tier opcional.** Premium desbloqueia: companion mobile + estatísticas avançadas + integrações.
- **Sempre free:** features básicas (timer, vibração, history local).

---

## 7. Métricas de sucesso V1

A medir 30 dias após release:

- **Downloads:** 500+ (modesto para "novo app", mas decente em nicho).
- **Reviews:** > 4.0 estrelas, > 10 reviews.
- **Crash rate:** < 1% das sessões.
- **Retenção D7:** > 30%.

Sem analytics na V1 (Connect IQ apps não têm telemetry built-in fácil). Métricas vêm da Connect IQ Store dashboard que mostra downloads + reviews.

---

## 8. Fontes consultadas

### Apps individuais
- [Pomodoro Timer](https://apps.garmin.com/en-US/apps/7fae9d35-93d5-4e15-9c84-e2226448dec6)
- [Pomodoro Productivity Timer](https://apps.garmin.com/en-US/apps/28456453-f3f4-4a6b-b134-8aef7e83e879)
- [PomoMin](https://apps.garmin.com/apps/66e318e7-cae6-4052-90c6-65bd58092202)
- [Pomodoro](https://apps.garmin.com/en-US/apps/4b11ad8f-3e48-4112-83df-336065c49829)
- [Pomodoro Sprints](https://apps.garmin.com/en-US/apps/83977225-664d-4d89-ad2c-7ba00edafeef)
- [Pomodoro Pro](https://apps.garmin.com/apps/8769a6fc-42bd-42a3-8885-af6dba6a1731)
- [Garmodoro on GitHub](https://github.com/klimeryk/garmodoro)
- [Tomato Timer](https://apps.garmin.com/apps/85a547a3-e3e0-4f69-87aa-c3f4528ca729)

### Forums
- [Garmin Forum — Help testing Tomato](https://forums.garmin.com/developer/connect-iq/f/discussion/4672/help-testing-tomato---a-pomodoro-timer)
- [Garmin Forum — Pomodoro Timer Request](https://forums.garmin.com/sports-fitness/sports-fitness/f/vivomove-luxe-style/346339/request-pomodoro-timer-repeat-timers)
- [Garmin Forum — WatchApp Pomodoro Showcase](https://forums.garmin.com/developer/connect-iq/f/showcase/1065/watchapp-pomodoro-timer)

### Posts de devs
- [WorkTimeLogger blog post](https://szarski.eu/2017/03/20/performance-management-pomodoro-and-my-app-for-garmin-watches.html)
- [Productive Pixie — Garmin Smartwatch Guide](https://www.theproductivepixie.com/2022/02/how-to-use-garmin-smartwatch-to-uplevel.html)
