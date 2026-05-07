# PRD — Task 02-02: Timer Loop

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar o **TimerService** — wrapper sobre `Toybox.Timer.Timer` que gera ticks de 1 segundo — e conectá-lo ao `PomodoroModel` existente. Modificar `TomaApp` para orquestrar Model + TimerService como singletons, transformar `TimerView` de uma view estática (parâmetros hardcoded no construtor) para uma view dinâmica que lê estado real do Model, e alterar `HomeDelegate` para iniciar sessões de verdade ao invés de navegar para demos.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que já existe | Como reutilizar |
|---|---|---|
| `source/model/PomodoroModel.mc` | State machine completa: `start()`, `tick()`, `pause()`, `resume()`, `stop()`, observer pattern com `addObserver/removeObserver` | Usar diretamente — é o core. O TimerService apenas chama `model.tick()` a cada segundo |
| `source/model/PomodoroState.mc` | Enum (`IDLE`, `RUNNING_WORK`, `RUNNING_SHORT_BREAK`, `RUNNING_LONG_BREAK`, `PAUSED`, `COMPLETED`) + `isRunning()` | Usar para decidir cores/labels na View |
| `source/model/PomodoroEvent.mc` | Enum de eventos (`ON_START`, `ON_TICK`, `ON_PHASE_CHANGE`, `ON_WORK_PHASE_COMPLETE`, `ON_PAUSE`, `ON_RESUME`, `ON_STOP`, `ON_COMPLETE`) | View subscreve e chama `requestUpdate()` nos eventos relevantes |
| `source/model/Preset.mc` | Classe `Preset` + module `Presets.builtinList()` | HomeDelegate já usa; manter como está |
| `source/views/TimerView.mc` | Render completo (ring, display, pills, phase label, paused state). Recebe dados via construtor | Refatorar para receber referência ao Model em vez de parâmetros individuais |
| `source/delegates/TimerDelegate.mc` | Stub com `onBack()` (popView) e `onSelect()` (TODO) | Conectar ao app.pauseSession() / app.stopSession() |
| `source/delegates/HomeDelegate.mc` | Demo navigation (cicla entre vários estados visuais) | Substituir lógica de demo por chamada a `getApp().startSession(preset)` |
| `tests/PomodoroModelTest.mc` | 18 testes cobrindo todas as transições, pause/resume, observers | Manter + adicionar testes de tick em batch (simulando N ticks consecutivos) |
| `source/ui/components/*` | TimerRing, TimerDisplay, SessionPills, PhaseLabel — todos stateless, recebem params | Chamar da TimerView com dados do Model |

### 2.2 Assets disponíveis

- Strings: `Rez.Strings.state_paused` já existe. Nenhuma string nova necessária para esta task.
- Cores: `Colors.BRAND`, `Colors.ACCENT`, `Colors.TEXT_MUTED`, `Colors.BRAND_DIM`, etc. — todas presentes em `source/ui/layout/Colors.mc`.
- Dimensões: todas em `source/ui/layout/Dimensions.mc`.
- Layouts: não usamos XML layouts para TimerView (render programático).

### 2.3 Approach de implementação

**Decisão: Timer periódico simples + callback no App.**

- `TimerService` encapsula `Toybox.Timer.Timer`, expõe `start(callback, intervalMs)` e `stop()`.
- `TomaApp` mantém singleton de `PomodoroModel` e `TimerService`.
- `TomaApp.startSession(preset)` chama `_model.start(preset)` + `_timerService.start(method(:onTimerTick), 1000)`.
- `TomaApp.onTimerTick()` chama `_model.tick()` + `Ui.requestUpdate()`.
- `TimerView` recebe referência ao `PomodoroModel` no construtor e lê estado dele no `onUpdate()`.
- `TimerView.onShow()` registra observer no Model; `onHide()` remove.

**Alternativa descartada:** Timer Service que internamente faz o tick e emite eventos — adiciona camada desnecessária. O Model já é o dono do estado; o Service deve ser wrapper fino.

### 2.4 APIs Connect IQ utilizadas

| API | Assinatura confirmada | Fonte |
|---|---|---|
| `Toybox.Timer.Timer()` | `new Timer.Timer()` | garmin_platform.md §2.1 |
| `Timer.Timer.start(callback as Method, period as Number, repeat as Boolean)` | `_timer.start(callback, 1000, true)` | garmin_platform.md §2.1 |
| `Timer.Timer.stop()` | `_timer.stop()` | garmin_platform.md §2.1 |
| `Toybox.WatchUi.requestUpdate()` | `Ui.requestUpdate()` | Usado em HomeView já |
| `Toybox.WatchUi.pushView(view, delegate, transition)` | Usado em HomeDelegate já |
| `Toybox.WatchUi.popView(transition)` | Usado em TimerDelegate já |

### 2.5 Cores/dimensões/strings necessárias

**Nenhuma nova cor ou dimensão.** Tudo já está mapeado para TimerView nos protótipos visuais (task 01-02).

**Strings existentes usadas:**
- `Rez.Strings.state_paused` — label "PAUSED"

**Strings de fase:** Atualmente hardcoded em `TimerView.getPhaseText()` ("FOCUS", "BREAK", "LONG BREAK"). Idealmente seriam `Rez.Strings.*`, mas a task 01-02 já implementou assim e isso pode ser corrigido na task de i18n. Manter como está para não expandir escopo.

---

## 3. Decisões a tomar

### D1. Back no TimerView sem confirm dialog

**Contexto:** A task `02-04` implementa o confirm dialog (C13). Nesta task, Back faz o quê?

**Opções:**
1. Back chama `stopSession()` e popView direto (simples, provisório).
2. Back não faz nada (ignora).

**Recomendação:** Opção 1. A task já define isso: "Back popView direto e chama `stopSession()`". Documentar como provisório; `02-04` substituirá por confirm dialog.

### D2. Pausa real via Enter ou apenas stub?

**Contexto:** A task diz que Pause/Resume real é `02-04`. Porém B3 (loop) funciona sem pause. A task 02-02 define `onTimerTick` verificando `isPaused()`.

**Opções:**
1. Enter chama `app.pauseSession()` / `app.resumeSession()` já nesta task — modelo já suporta.
2. Enter continua como TODO; pause fica 100% para `02-04`.

**Recomendação:** Opção 1. O Model já implementa pause/resume. O custo é mínimo (2 linhas no delegate), e permite testar visualmente o estado paused no simulador. Estratégia: timer para de decrementar, view mostra cor dim + "PAUSED". Resume reativa.

**Nota:** A spec da task (seção "Out of scope") diz "Pausa/Resume real (02-04)". Contudo, o approach do task body diz `pauseSession()` já chamado no `onTimerTick`. **Decisão:** implementar pause/resume funcional aqui, pois o Model já cobre. O que `02-04` faz é o UX polish (tela P4 separada, confirm dialog ao sair). Aqui fazemos a mecânica básica (mesmo TimerView muda visual).

### D3. Navegação ao COMPLETED

**Contexto:** Quando Model emite `ON_COMPLETE`, deve navegar para CycleCompleteView (P6).

**Opções:**
1. O observer no `onTimerTick` detecta state == COMPLETED e faz `pushView(CycleCompleteView)`.
2. O observer na TimerView detecta ON_COMPLETE e navega.

**Recomendação:** Opção 1 (no App). A View não deve navegar (architecture.md §3: "View render only"). O App é quem orquestra navegação em transições de state machine.

### D4. Navegação nas transições de fase (Phase Transition P5)

**Contexto:** A task diz explicitamente: "Navegação automática para PhaseTransitionView entre fases (02-04 ou separar — definir)".

**Recomendação:** **Não** implementar PhaseTransitionView nesta task. Apenas continuar o countdown na mesma TimerView — a view se atualiza automaticamente (cor, label, tempo mudam). PhaseTransitionView fica para task posterior.

### D5. TimerService: parar timer quando paused ou manter rodando?

**Contexto:** A task spec mostra 2 abordagens:
- A: Timer continua rodando; `onTimerTick` faz early return se paused.
- B: Timer para em pause, reinicia em resume.

**Recomendação:** Opção A (timer continua rodando). Razão: mais simples, evita bugs de edge case ao re-startar o timer. Custo: 1 callback/s extra durante pause (noop). Garmin não penaliza isso em memória.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | Timer callback não é chamado se app vai para background | Out of scope (V1 é foreground-only). Recovery será task `02-16`. |
| 2 | `requestUpdate()` chamado a cada segundo pode causar flicker em MIP displays | MIP tem refresh lento; Connect IQ faz debounce. Testar no simulador FR255. |
| 3 | TimerView refatorada perde compatibilidade com protótipos que usam params hardcoded | HomeDelegate demo mode será removido (substituído por sessão real). Protótipos já cumpriram propósito. |
| 4 | `getApp()` retorna `AppBase`, não `TomaApp` — precisa de cast | Padrão Connect IQ: `(App.getApp() as TomaApp).startSession(preset)`. Typecheck ok. |
| 5 | Múltiplos `requestUpdate()` por frame coalescem — view pode mostrar dados "atrasados" | Não é problema: requestUpdate é debounced naturalmente. Próximo frame pega estado atual. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/services/TimerService.mc` | **Criar** (+ criar dir `source/services/`) | Wrapper fino sobre Toybox.Timer.Timer. start(callback, intervalMs), stop(), isRunning(). |
| `source/TomaApp.mc` | **Modificar** | Adicionar singletons `_model` e `_timerService`. Expor `getModel()`, `startSession(preset)`, `onTimerTick()`, `pauseSession()`, `resumeSession()`, `stopSession()`. |
| `source/views/TimerView.mc` | **Modificar** | Refatorar construtor: receber `PomodoroModel`. onShow/onHide: registrar/remover observer. onUpdate: ler Model em vez de campos locais. |
| `source/delegates/TimerDelegate.mc` | **Modificar** | onSelect: toggle pause/resume via App. onBack: chamar stopSession + popView. |
| `source/delegates/HomeDelegate.mc` | **Modificar** | onSelect para presets (idx 0-3): chamar `getApp().startSession(preset)` e pushView TimerView com model real. Remover lógica de demo. |
| `tests/PomodoroModelTest.mc` | **Modificar** | Adicionar testes de tick batch (ex: simular 60 ticks e verificar transição), testar que tick durante pause é noop, testar ciclo completo 1/1/2 rápido com contagem de eventos. |

---

## 6. Arquitetura do fluxo

```
┌──────────────────────────────────────────────────────────────────────┐
│  USER INPUT                                                          │
│                                                                      │
│  [Home: Enter]                                                       │
│       │                                                              │
│       ▼                                                              │
│  HomeDelegate.onSelect()                                             │
│       │                                                              │
│       ├── app = getApp() as TomaApp                                  │
│       ├── app.startSession(preset)                                   │
│       │       │                                                      │
│       │       ├── _model.start(preset)   ← emite ON_START, ON_PHASE  │
│       │       └── _timerService.start(method(:onTimerTick), 1000)    │
│       │                                                              │
│       └── Ui.pushView(TimerView(_model), TimerDelegate, SLIDE_LEFT)  │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  TIMER LOOP (cada 1000ms)                                            │
│                                                                      │
│  Toybox.Timer ──callback──► TomaApp.onTimerTick()                    │
│                                  │                                   │
│                                  ├── if _model.isPaused(): return     │
│                                  ├── _model.tick()                    │
│                                  │      │                            │
│                                  │      ├── remaining--              │
│                                  │      ├── if 0: _transitionPhase() │
│                                  │      │            emite ON_PHASE   │
│                                  │      └── else: emite ON_TICK      │
│                                  │                                   │
│                                  └── Ui.requestUpdate()              │
│                                         │                            │
│                                         ▼                            │
│                                  TimerView.onUpdate(dc)              │
│                                    reads model.getState()            │
│                                    reads model.getRemainingSeconds() │
│                                    draws ring, display, pills, label │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  USER INPUT (during session)                                         │
│                                                                      │
│  [Timer: Enter] → TimerDelegate.onSelect()                           │
│       │                                                              │
│       ├── if model.isPaused(): app.resumeSession()                   │
│       └── else:                app.pauseSession()                    │
│                                     │                                │
│                                     └── _model.pause()               │
│                                          (timer keeps ticking,       │
│                                           tick() returns early)      │
│                                                                      │
│  [Timer: Back] → TimerDelegate.onBack()                              │
│       │                                                              │
│       ├── app.stopSession()                                          │
│       │       ├── _model.stop()                                      │
│       │       └── _timerService.stop()                               │
│       └── Ui.popView(SLIDE_RIGHT)                                    │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  COMPLETION                                                          │
│                                                                      │
│  Model emite ON_COMPLETE → Observer no App detecta                   │
│       │                                                              │
│       ├── _timerService.stop()                                       │
│       └── Ui.switchToView(CycleCompleteView, delegate, SLIDE_LEFT)   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 7. Referências para o plan.md

O plan.md deve ler:

1. **Este PRD** — seções 3 (decisões) e 5 (arquivos).
2. **`source/model/PomodoroModel.mc`** — API pública completa do Model.
3. **`source/views/TimerView.mc`** — estado atual para saber o que refatorar.
4. **`source/delegates/HomeDelegate.mc`** — lógica demo a ser substituída.
5. **`source/delegates/TimerDelegate.mc`** — stub a ser conectado.
6. **`source/TomaApp.mc`** — ponto de partida para orquestração.
7. **`references/garmin_platform.md` §2.1** — assinatura do Timer.Timer.
8. **`references/architecture.md` §3** — separação de responsabilidades (Model não toca Toybox).

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação (D1–D5).
- [x] Riscos identificados com mitigação (5 riscos).
- [x] Arquivos listados com responsabilidade clara (6 arquivos).
- [x] Fluxo de dados documentado (diagrama textual completo).
- [x] Strings e cores mapeadas (nenhuma nova necessária).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
