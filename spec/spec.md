# Toma — Specification (Macro)

> Especificação global do produto. Lista todas as **páginas (P)**, **componentes (C)** e **comportamentos (B)**. Cada item recebe um identificador estável (P1, B7, etc.) que é referenciado em tasks individuais.

---

## 1. Resumo

**Toma** é um app Garmin Connect IQ (System 7+) para a técnica Pomodoro com 4 presets configuráveis, gravação de cada sessão como FIT Activity no Garmin Connect, vibração inteligente em transições de fase, contagem persistente de sessões, histórico local, e identidade visual minimalista dark-mode (manual de marca Toma).

**Plataforma alvo V1:** Forerunner 255 + todos devices Connect IQ System 7+ AMOLED e MIP (FR255S, FR265, FR265S, FR955, FR965, Fenix 7/8, Epix Gen 2, Venu 3/3S, Vivoactive 5).

**Diferencial competitivo:** único app Pomodoro do ecossistema Garmin que grava sessões como activity FIT.

---

## 2. Páginas (P)

### P1. Home / Preset Picker

**Propósito:** ponto de entrada do app. Lista os presets disponíveis e permite iniciar uma sessão.

**Conteúdo:**
- Wordmark "toma" no topo (lowercase, fonte UI).
- Preset selecionado destacado no centro (preset card grande).
- Indicador de paginação (4 dots) — qual dos 5 presets está selecionado: 25/5, 30/5, 50/10, Custom, e o item "Configurações".
- Last preset usado é a seleção default (lê de `lastSelectedPreset` em Properties).

**Inputs:**
- Up/Down (FR) ou swipe vertical (touch): navegar entre presets.
- Enter (FR) ou tap (touch): iniciar sessão com preset selecionado, navega para P3.
- Long-press Enter ou Menu: abrir Settings (P8).

**Estados:**
- Sempre presente (não tem variantes).

**Componentes usados:** wordmark, preset card, dots indicator, ring border vazio.

### P2. Custom Builder

**Propósito:** editar o preset Custom (work / break / cycles).

**Conteúdo:**
- Tela com 3 linhas:
  - WORK: `25 min` (editável)
  - BREAK: `5 min` (editável)
  - CYCLES: `4` (editável)
- Linha selecionada destacada (cor accent).
- Hints de input no rodapé.

**Inputs:**
- Up/Down: alternar entre linhas.
- Enter: entrar em modo edit da linha. Up/Down agora ajusta valor; Enter confirma.
- Back: cancelar / voltar.
- Touch: tap em linha para editar.

**Estados:**
- Navegação entre linhas (3 estados).
- Modo edit ativo em linha (3 estados × range de valores).

**Limites (regras de negócio):**
- WORK: 5–90 min (passo 5 min).
- BREAK: 1–30 min (passo 1 min).
- CYCLES: 1–10 (passo 1).

**Componentes usados:** linha de spec, value display, hints rodapé.

### P3. Timer Running

**Propósito:** mostra a sessão em andamento. Tela principal durante toda a sessão.

**Conteúdo:**
- Phase label no topo: `FOCUS` / `BREAK` / `LONG BREAK` (uppercase, cor da fase).
- Anel circular de progresso (TimerRing) — preenche da posição 12h em sentido horário conforme tempo passa.
- Display MM:SS centralizado (TimerDisplay).
- SessionPills no rodapé indicando ciclos completos.

**Inputs:**
- Enter (FR) ou tap (touch): pause → vai para P4.
- Back: pedido de stop → diálogo de confirmação.
- Up/Down ou swipe lateral: nada (evita ações acidentais durante sessão).

**Estados:**
- `running_work`: anel `brand`, label `FOCUS`.
- `running_short_break`: anel `textMuted`, label `BREAK`.
- `running_long_break`: anel `accent`, label `LONG BREAK`.

**Componentes usados:** TimerRing, TimerDisplay, PhaseLabel, SessionPills.

### P4. Paused

**Propósito:** sessão pausada. Mesmo layout do P3 mas com indicação visual de pause.

**Conteúdo:**
- Identico a P3, exceto:
  - Anel desenhado em cor "dim" (versão escurecida da cor da fase).
  - Display MM:SS em `textMuted` em vez de `textPrimary`.
  - Label adicional "PAUSED" abaixo do display.

**Inputs:**
- Enter ou tap: resume → volta a P3.
- Back: pedido de stop → diálogo de confirmação.

**Estados:**
- Sub-estado de cada fase. 3 variantes (paused work, paused short break, paused long break).

**Componentes usados:** mesmos de P3 + label "PAUSED".

### P5. Phase Transition

**Propósito:** tela curta (3 segundos) que anuncia a transição entre fases (work → break, break → work, work → long break).

**Conteúdo:**
- Fundo `bg`.
- Texto gigante centralizado: `BREAK`, `FOCUS` ou `LONG BREAK`.
- Cor do texto = cor da fase que está começando.
- Pequeno hint embaixo: "Session 2 of 4" / "Sessão 2 de 4".

**Inputs:**
- Qualquer input: pula a transição imediatamente, vai direto para P3 da nova fase.
- Auto-advance após 3s.

**Estados:**
- 3 variantes: pra Break, pra Focus, pra Long Break.

**Componentes usados:** PhaseLabel grande, hint pequeno.

### P6. Cycle Complete

**Propósito:** após completar todos os ciclos do preset (ex: 4 work + 3 break + 1 long break), mostra resultado e pergunta o próximo passo.

**Conteúdo:**
- Heading "CYCLE COMPLETE" no topo (cor accent).
- Número grande no centro: `4 / 4` (cycles done / cycles in preset).
- Linha "Today: %d sessions" (contador diário).
- 2 CTAs:
  - PrimaryButton "Start again" (volta para P3 com mesmo preset).
  - Secondary "Done" (volta para P1).

**Inputs:**
- Enter: ativa CTA atualmente focado.
- Up/Down ou swipe: alternar entre 2 CTAs.
- Back: equivalente a "Done", volta para P1.
- Touch: tap direto em CTA.

**Estados:**
- Sempre visual full (anel "completed" preenchido com `accent`).

**Componentes usados:** heading, número grande, contador hint, PrimaryButton ×2.

### P7. History

**Propósito:** lista das últimas N sessões concluídas.

**Conteúdo:**
- Título "HISTORY" no topo.
- Lista vertical de até 50 entradas:
  - Data + hora (ex: "May 6, 14:32")
  - Duração total da sessão (ex: "2h 0m")
  - Preset usado (ex: "25/5 · 4")
- Empty state: "No sessions yet" centralizado.

**Inputs:**
- Up/Down: scroll na lista.
- Back: volta para P1.
- Long-press em uma entrada: opção "Delete" (apenas em V1.x se houver demanda; V1 sem delete).

**Estados:**
- Lista vazia (empty state).
- Lista populada.

**Componentes usados:** lista scrollable nativa Connect IQ, items de history.

### P8. Settings

**Propósito:** menu de configurações. Implementado via `WatchUi.Menu2` nativo.

**Conteúdo:** itens do menu (todos toggle ou seleção):

| Item | Tipo | Default | Descrição |
|---|---|---|---|
| Sound | Toggle | OFF | Tocar tom no fim de fase (devices com speaker) |
| Vibration | Toggle | ON | Vibração no fim de fase |
| Backlight on alert | Toggle | ON | Acender backlight em transições |
| Record as activity | Toggle | ON | Salvar sessão como activity Garmin |
| Language | Selector | Auto | Auto / English / Português |
| History | Action | — | Navega para P7 |
| About | Action | — | Mostra versão + créditos |

**Inputs:**
- Padrão Menu2: Up/Down navega, Enter ativa toggle ou abre selector, Back volta.

**Estados:**
- Estado dos toggles reflete `Application.Properties`.

**Componentes usados:** `Ui.ToggleMenuItem`, `Ui.MenuItem` nativos.

---

## 3. Componentes (C)

Componentes reutilizáveis (UI). Definidos em [references/design_system.md](../references/design_system.md) seção 5.

| ID | Componente | Onde aparece |
|---|---|---|
| C1 | TimerRing | P3, P4, P6 |
| C2 | TimerDisplay | P3, P4 |
| C3 | SessionPills | P3, P4 |
| C4 | PhaseLabel | P3, P4, P5 |
| C5 | PrimaryButton | P6 |
| C6 | Wordmark "toma" | P1, P8 (header) |
| C7 | Preset Card | P1 |
| C8 | Dots Indicator | P1 |
| C9 | Spec Line (label + valor) | P2 |
| C10 | Hints (rodapé) | P2 |
| C11 | History Item | P7 |
| C12 | Empty State | P7 |
| C13 | Confirm Dialog (Stop?) | overlay sobre P3/P4 |
| C14 | Recovery Dialog (Resume?) | mostrado em onStart se aplicável |

---

## 4. Comportamentos (B)

### B1. Iniciar sessão a partir de preset

**Trigger:** usuário pressiona Enter em P1 com preset selecionado.

**Fluxo:**
1. Lê preset (work/break/cycles do Properties).
2. Inicializa `PomodoroModel` com preset.
3. Inicia `TimerService` (1Hz tick).
4. Se `recordAsActivity == true`, inicia `ActivityService.start()`.
5. Vibra "start" via `AttentionService.vibrateStart()`.
6. Navega para P3.

**Edge cases:**
- Se preset Custom não tiver sido editado nunca, usa defaults (25/5/4).
- Se já existe sessão ativa em recovery, pergunta antes (B16).

### B2. Construir preset personalizado

**Trigger:** usuário seleciona "Custom" em P1 e pressiona Enter, OU acessa P2 via menu.

**Fluxo:**
1. Lê valores atuais de `customWorkMin`, `customBreakMin`, `customCycles` (Properties).
2. Renderiza P2 com os valores.
3. Usuário edita (ver inputs de P2).
4. Ao confirmar (Back ou Enter sequência), persiste novos valores em Properties.
5. Volta para P1 com Custom selecionado.

**Validações:**
- Aplicar limites de cada campo (ver P2).
- Se valor inválido, não permitir confirmar.

### B3. Loop de countdown

**Coração técnico do timer.**

**Fluxo:**
1. `TimerService.startTicking(callback, 1000)` registra callback periódica de 1s.
2. Cada callback (`onTick`):
   - Decrementa `Model.remainingSeconds` em 1.
   - Se chegou a 0, chama `Model.transitionPhase()` (B4).
   - Caso contrário, requestUpdate da View ativa.
3. Throttle de persistência: a cada 5s, persiste estado em Storage para recovery (B16).

**Detalhes técnicos:**
- `Toybox.Timer.Timer` documentado em [garmin_platform.md §2.1](../references/garmin_platform.md).
- Callback não aloca memória.

### B4. Transição de fase (state machine)

**State machine:**

```
                    start(preset)
                          │
                          ▼
                  ┌──── IDLE ────┐
                  │              │
                  │   start()    │
                  ▼              │
            RUNNING_WORK         │
              │                  │
              │ tick=0 + cycles_done < total-1
              ▼                  │
         RUNNING_SHORT_BREAK     │
              │                  │
              │ tick=0           │
              ▼                  │
            RUNNING_WORK ────────┘ (loop)
              ...
              │ tick=0 + cycles_done == total-1
              ▼
         RUNNING_LONG_BREAK
              │
              │ tick=0
              ▼
            COMPLETED ──── pop to P1 / show P6
```

**Regras:**
- Long break **só** após o último ciclo de work (não a cada 4 sessões de qualquer tipo).
- Após COMPLETED, sessão é concluída — gravada no histórico (B10) e como activity FIT (B11).

**Eventos emitidos pelo Model em cada transição:**
- `:onStart` (preset)
- `:onPhaseChange` (oldPhase, newPhase)
- `:onTick` (remainingSeconds, totalSeconds)
- `:onPause` ()
- `:onResume` ()
- `:onStop` (saved as activity? boolean)
- `:onComplete` (totalSessions)

### B5. Pausa / Resume

**Trigger:** Enter ou tap em P3 (pausa); Enter ou tap em P4 (resume).

**Fluxo pausar:**
1. `Model.pause()` congela `remainingSeconds`.
2. `TimerService.stop()` cancela callback periódica.
3. View troca de P3 para P4 (sem re-pushView; só muda estado e re-render).
4. `ActivityService.pause()` (se ativo) — pausa também a activity FIT.

**Fluxo resume:**
1. `Model.resume()` retoma o estado.
2. `TimerService.startTicking(...)` reativa.
3. View volta para P3.
4. `ActivityService.resume()` (se ativo).

### B6. Stop / Reset

**Trigger:** Back em P3 ou P4 → mostra C13 (Confirm Dialog).

**Fluxo:**
1. Confirm dialog: "Stop session?" com [Stop / Continue].
2. Se Stop:
   - `Model.stop()`.
   - `TimerService.stop()`.
   - `ActivityService.discard()` (não salva como activity, pois sessão foi abortada).
   - Navega de volta para P1.
3. Se Continue: dismiss dialog, mantém timer rodando.

### B7. Vibração de alerta

**Trigger:** transições de fase (B4) e início (B1) e fim (`onComplete`).

**Mapeamento:**

| Evento | Profile | Quando |
|---|---|---|
| Start de sessão | 1 pulso curto | B1, antes de mostrar P3 |
| End of work → break | 2 pulsos médios | B4, antes de P5 |
| End of break → work | 1 pulso longo | B4, antes de P5 |
| Cycle complete (final) | 3 pulsos longos | B4, antes de P6 |

**Settings:**
- Se `vibrationEnabled == false`, vibração é suprimida.
- Se `doNotDisturb == true` (device-level), também suprime (cortesia).

### B8. Som de alerta

**Trigger:** mesmos de B7, mas só em devices `:hasSpeaker`.

**Settings:**
- Default: `soundEnabled == false` (silêncio respeita o tom da marca).
- Se enabled, tocar `Attention.TONE_LOUD_BEEP` no fim de cada fase.

**Capability check obrigatório:** `if (Attention has :playTone)`.

### B9. Contagem de sessões concluídas (diária)

**Trigger:** sempre que sessão completa (`onComplete` do Model OU cada work-phase concluída — ver decisão).

**Decisão:** **conta cada work-phase concluída**, não só o ciclo inteiro. Justificativa: usuário que faz 2 sessions e para deve ver "2" no contador, não "0".

**Fluxo:**
1. Ao completar uma work-phase (não pause/stop), `Model` emite `:onWorkPhaseComplete`.
2. `HistoryRepository` incrementa contador `today.workSessions`.
3. Storage key: `dailyCounter` = `{ "date": "2026-05-06", "count": 5 }`.
4. **Reset diário:** ao iniciar app, comparar `dailyCounter.date` com `Time.today()`. Se diferente, resetar para 0.

**Apresentação:**
- Mostrado em P6 (Cycle Complete): "Today: 8 sessions".
- Mostrado em P7 (History) opcionalmente como header.

### B10. Histórico persistente

**Trigger:** sessão completa (`onComplete`).

**Fluxo:**
1. `HistoryRepository.append(session)`.
2. `Session` schema: `{ "completedAt": <epoch>, "preset": "25/5/4" | "custom", "workMin": 25, "breakMin": 5, "cycles": 4, "totalDuration": <seconds> }`.
3. Mantém últimas **50** sessões. Mais antigas são descartadas.
4. Persistido em `Application.Storage["sessionHistory"]`.

**Edge cases:**
- Sessão pausada e retomada: ainda conta como uma sessão.
- Sessão stopada (B6): **não** vai para histórico.

### B11. Gravar como FIT Activity

**Diferencial competitivo. Documentado em [garmin_platform.md §2.7](../references/garmin_platform.md).**

**Trigger:** B1 (início de sessão), se `recordAsActivity == true`.

**Fluxo:**
1. `ActivityService.start()` cria session com:
   - `name`: "Focus" (customizable em V2 talvez).
   - `sport`: `SPORT_GENERIC`.
   - `subSport`: `SUB_SPORT_GENERIC`.
2. Pause/Resume da session segue B5 (também pausa/resume a activity).
3. Stop não-confirmado (B6): `ActivityService.discard()` — activity descartada.
4. Complete (`onComplete`): `ActivityService.stop()` + `save()` — activity vai para Garmin Connect.

**Comportamento:**
- HR é gravado automaticamente (Garmin coleta).
- Calorias estimadas pelo device.
- Aparece na timeline do Garmin Connect como "Focus" activity.

**Limitações:**
- Algumas devices podem não permitir múltiplas activities concorrentes (se usuário já está em corrida, app não cria outra). Validar no setup.

### B12. Settings persistentes

**Trigger:** mudança de toggle em P8.

**Fluxo:**
1. `SettingsMenuDelegate.onSelect(item)`.
2. Para `ToggleMenuItem`, lê novo valor (`item.isEnabled()`).
3. `SettingsRepository.set<Key>(value)` persiste em Properties.
4. View `requestUpdate()` para refletir.

**Aplicação em runtime:**
- Mudanças aplicam imediatamente (próximo evento usa novo valor).
- Não requer reiniciar o app.

### B13. Internacionalização PT/EN

**Trigger:** carregamento de strings.

**Fluxo:**
1. `Application.Properties["language"]` lido. Valores: `"auto"`, `"en"`, `"pt"`.
2. Se `auto`, usa `System.getDeviceSettings().systemLanguage`.
3. Connect IQ resolve `Rez.Strings.<key>` para arquivo correto:
   - `resources-en/strings/strings.xml` (default)
   - `resources-pt/strings/strings.xml`

**Manifest:**
```xml
<iq:languages>
    <iq:language>eng</iq:language>
    <iq:language>por</iq:language>
</iq:languages>
```

**Glossário em [design_system.md §7](../references/design_system.md).**

### B14. Input multi-device

**Mapeamento padronizado:**

| Ação semântica | FR (botões) | AMOLED (touch) |
|---|---|---|
| Confirmar / Play / Pause | Enter (Up-Right top) | Tap centro |
| Voltar / Cancelar / Stop | Back (Down-Right) | Swipe right |
| Navegar Up | Botão Up (Left top) | Swipe up |
| Navegar Down | Botão Down (Left bottom) | Swipe down |
| Menu | Botão Menu (Up Long-press em alguns) | Tap longo central |

**Implementação via `BehaviorDelegate`:** abstrai botões e touch automaticamente. Override `onSelect`, `onBack`, `onMenu`, `onPreviousPage`, `onNextPage`.

### B15. Sleep prevention durante sessão

**Estratégia documentada em [garmin_platform.md §6](../references/garmin_platform.md).**

**Decisão V1:** confiar no comportamento padrão do device. Não tentar manter screen on artificialmente.

**Detalhes:**
- App em foreground → device mantém screen ativa.
- Em transição de fase (B4), chamar `Attention.backlight(true)` para garantir visibilidade.

### B16. Recovery após kill

**Trigger:** abertura do app (`onStart`) com sessão "ativa" em Storage.

**Fluxo:**
1. `RecoveryService.checkOnStart()` lê `activeSession` do Storage.
2. Se existe e `remaining > 0`:
   - Calcular novo `remaining` baseado em diff de tempo.
   - Mostrar C14 (Recovery Dialog): "Resume session?" com [Resume / Discard].
   - Se Resume: hidrata Model e vai para P3.
   - Se Discard: limpa Storage, vai para P1.
3. Se não há sessão ativa, vai direto para P1.

**Persistência:**
- Storage key: `activeSession`.
- Schema: `{ "preset": ..., "phase": "running_work", "remaining": 1234, "savedAt": <epoch>, "cyclesCompleted": 1 }`.
- Throttle de save: a cada 5s do tick (B3).
- Limpa o Storage após `:onComplete` ou Discard.

---

## 5. Mapa página × comportamentos

| | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B10 | B11 | B12 | B13 | B14 | B15 | B16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P1 Home | ✅ | | | | | | | | | | | | ✅ | ✅ | | ✅ |
| P2 Custom Builder | | ✅ | | | | | | | | | | | ✅ | ✅ | | |
| P3 Timer Running | | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ | |
| P4 Paused | | | | | ✅ | ✅ | | | | | ✅ | | ✅ | ✅ | | |
| P5 Phase Transition | | | | ✅ | | | ✅ | ✅ | ✅ | | | | ✅ | ✅ | ✅ | |
| P6 Cycle Complete | ✅ | | | | | | ✅ | ✅ | | ✅ | ✅ | | ✅ | ✅ | | |
| P7 History | | | | | | | | | | ✅ | | | ✅ | ✅ | | |
| P8 Settings | | | | | | | | | | | | ✅ | ✅ | ✅ | | |

---

## 6. Regras de negócio explícitas

1. **Long break** acontece somente após o **último** ciclo de work no preset (não a cada N work-phases).
2. **Custom preset limites:** work 5–90 min, break 1–30 min, cycles 1–10. Validação na entrada (P2).
3. **Sessão é gravada no histórico (B10) e como activity (B11)** **somente** se completar todos os ciclos do preset. Sessão pausada e retomada conta. Sessão stopada (B6) não conta.
4. **Contador diário (B9)** incrementa a cada **work-phase** concluída (não por ciclo completo).
5. **Reset diário** usa `Time.today()` (hora local do device). Se device muda timezone durante sessão, comportamento é "lenient" — ignora a mudança.
6. **Vibração e som** respeitam settings + DND do sistema. Em devices sem capability, suprimidos silenciosamente.
7. **Recovery (B16)** só oferece resume se `remaining > 60s`. Senão, descarta automaticamente (não vale interromper o usuário por <1min).
8. **Idioma** detectado automaticamente pelo system locale, com override manual em Settings.
9. **Preset Custom** é único — alterar Custom não cria novo preset, sobrescreve. (V2 pode ter múltiplos customs.)
10. **Default preset** ao iniciar app é o último usado. Primeira execução usa 25/5/4.

---

## 7. Out of scope (V1)

Documentado para evitar scope creep. Itens que **não** entram na V1:

- Companion mobile app.
- Cloud sync.
- Estatísticas avançadas (gráficos, trends).
- Soundscapes / white noise.
- Múltiplos custom presets.
- Goal tracking ("8 pomodoros today").
- Streaks / achievements.
- Integrações third-party (Notion, Calendar, etc.).
- Watch face Toma.
- Data Field Toma.
- Settings via Garmin Connect mobile app (XML em `resources/settings/`) — **decisão a revisar:** se for trivial, pode entrar; senão fica V1.1.

---

## 8. Roadmap pós-V1

Detalhado em [references/benchmark.md](../references/benchmark.md) seção 3.3.

---

## 9. Como esta spec serve à FASE 1.2 (fatiamento)

Cada **P** vira uma task em `tasks/01-prototipos-visuais/` (8 tasks, P1–P8).
Cada **B** vira uma ou mais tasks em `tasks/02-comportamentos/` (12 tasks consolidando os 16 behaviors).

Tasks declaram explicitamente quais P/B/C cobrem, e referenciam seções desta spec ao invés de duplicar conteúdo.
