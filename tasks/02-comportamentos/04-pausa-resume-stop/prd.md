# PRD — Task 02-04: Pause / Resume / Stop

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Implementar o ciclo completo Pause/Resume/Stop com confirmacao visual: toggle pause/resume via Enter no TimerView, stop com ConfirmDialog (C13) ao pressionar Back, auto-navegacao para PhaseTransitionView (P5) entre fases, e navegacao para CycleCompleteView (P6) com acoes "Start again" e "Done" funcionais.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que aproveitar |
|---|---|
| `source/model/PomodoroModel.mc` | Ja possui `pause()`, `resume()`, `stop()` completos com emissao de eventos. Testes unitarios ja cobrem todos esses metodos. |
| `source/model/PomodoroState.mc` | Estados PAUSED, IDLE, COMPLETED ja definidos. |
| `source/model/PomodoroEvent.mc` | Eventos ON_PAUSE, ON_RESUME, ON_STOP, ON_PHASE_CHANGE, ON_COMPLETE ja definidos. |
| `source/TomaApp.mc` | Ja tem `pauseSession()`, `resumeSession()`, `stopSession()`, `onModelEvent()` parcialmente implementado (trata ON_START, ON_PHASE_CHANGE parcial, ON_COMPLETE). |
| `source/delegates/TimerDelegate.mc` | Ja tem `onSelect()` com toggle pause/resume e `onBack()` (atualmente faz stop direto sem confirmacao). |
| `source/views/TimerView.mc` | Ja renderiza estado paused (cor dim, label "PAUSED"). |
| `source/views/PhaseTransitionView.mc` | Completa: recebe phase/session/total, timer de 3s com auto-dismiss. |
| `source/delegates/PhaseTransitionDelegate.mc` | Completa: dismiss em qualquer input. |
| `source/views/CycleCompleteView.mc` | Renderiza heading, numero, today, 2 botoes com focus. |
| `source/delegates/CycleCompleteDelegate.mc` | Navegacao Up/Down + Select/Back. Atualmente `onSelect` so faz println + popView (placeholder). |
| `source/ui/components/PrimaryButton.mc` | Componente de botao reutilizavel. |

### 2.2 Assets disponiveis

- Strings: `state_paused`, `start_again`, `done`, `cycle_complete_title` ja existem.
- Cores: `Colors.BG`, `Colors.BORDER`, `Colors.TEXT_PRIMARY`, `Colors.TEXT_MUTED`, `Colors.ACCENT`, `Colors.BRAND` — todas disponiveis.
- Dimensoes: `Dimensions.buttonWidth/Height`, `Dimensions.cycleButton1Y/2Y` ja existem.
- Faltam strings para o ConfirmDialog: "Stop session?", "Stop", "Continue".

### 2.3 Approach de implementacao

**Estrategia:** evoluir o codigo existente em vez de reescrever. Os principais gaps sao:

1. **ConfirmStopView/Delegate** — novo overlay de confirmacao (nao existe).
2. **TimerDelegate.onBack()** — trocar stop direto por pushView do ConfirmDialog.
3. **TomaApp.onModelEvent()** — completar handler de ON_PHASE_CHANGE para pushView PhaseTransitionView quando fase muda (atualmente so vibra).
4. **CycleCompleteDelegate.onSelect()** — implementar "Start again" (reinicia com mesmo preset) e "Done" (volta para Home).
5. **TomaApp** — guardar referencia ao ultimo preset para viabilizar "Start again".

**Decisao sobre TimerService no pause:** manter TimerService rodando durante pause (a task sugere isso como opcao). O `onTimerTick()` do TomaApp ja faz early-return se `isPaused()`. Justificativa: simplicidade, evita bugs de start/stop frequente, sem custo significativo de bateria (callback vazio a cada 1s e irrelevante).

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `WatchUi.pushView(view, delegate, transition)` | Abrir ConfirmStopView e PhaseTransitionView | `pushView(view as View, delegate as InputDelegate, transition as SlideType) as Void` |
| `WatchUi.popView(transition)` | Fechar dialogs e views | `popView(transition as SlideType) as Void` |
| `WatchUi.switchToView(view, delegate, transition)` | Troca completa da view stack (usado no CycleComplete e Start again) | `switchToView(view as View, delegate as InputDelegate, transition as SlideType) as Void` |
| `WatchUi.requestUpdate()` | Forcar re-render apos state change | `requestUpdate() as Void` |
| `Timer.Timer` | Timer one-shot para auto-dismiss da PhaseTransition (ja implementado) | — |

Fonte: `references/garmin_platform.md` secoes 2.1, 2.6.

### 2.5 Cores/dimensoes/strings necessarias

**Strings novas (a adicionar em `resources/strings/strings.xml`):**

| ID | EN | Uso |
|---|---|---|
| `confirm_stop_title` | `Stop session?` | Titulo do ConfirmDialog |
| `confirm_stop_stop` | `Stop` | Botao de confirmar stop |
| `confirm_stop_continue` | `Continue` | Botao de cancelar |

**Dimensoes novas (a adicionar em `Dimensions.mc`):**

| Funcao | small | medium | large | Uso |
|---|---|---|---|---|
| `confirmDialogWidth` | 160 | 200 | 280 | Largura do dialog overlay |
| `confirmDialogHeight` | 110 | 130 | 180 | Altura do dialog overlay |
| `confirmTitleY` | 15 | 20 | 30 | Y do titulo dentro do dialog |
| `confirmButton1Y` | 50 | 60 | 85 | Y do primeiro botao |
| `confirmButton2Y` | 76 | 92 | 130 | Y do segundo botao |
| `confirmButtonWidth` | 120 | 150 | 210 | Largura dos botoes do dialog |
| `confirmButtonHeight` | 22 | 26 | 38 | Altura dos botoes do dialog |

**Cores:** nenhuma nova necessaria. Usar `Colors.BG` (fundo), `Colors.BORDER` (borda do dialog), `Colors.TEXT_PRIMARY` (titulo), `Colors.ACCENT`/`Colors.TEXT_MUTED` (botoes).

---

## 3. Decisoes a tomar

### D1: Parar TimerService durante pause?

| Opcao | Pro | Contra |
|---|---|---|
| **A) Manter rodando (recomendado)** | Simples, sem bugs de restart, ja funciona (early return no tick) | Gasto minimo de CPU (1 callback/s com return imediato) |
| B) Stop/Start no pause/resume | Zero CPU durante pause | Complexidade extra, risco de bugs em start rapido |

**Recomendacao:** Opcao A. O custo e desprezivel e o codigo ja funciona assim.

### D2: Navegacao no ON_PHASE_CHANGE — pushView ou switchToView?

| Opcao | Pro | Contra |
|---|---|---|
| **A) pushView PhaseTransition sobre TimerView (recomendado)** | TimerView fica na pilha, PhaseTransition faz popView apos 3s, retorna naturalmente | Precisa garantir que nao duplica |
| B) switchToView para PhaseTransition, depois switchToView para Timer | Pilha limpa | Perde estado da TimerView, mais complexo |

**Recomendacao:** Opcao A. Ja e o pattern da PhaseTransitionView existente (tem dismiss() com popView).

### D3: Navegacao "Start again" no CycleComplete

| Opcao | Pro | Contra |
|---|---|---|
| **A) switchToView para novo TimerView (recomendado)** | Pilha limpa: troca tudo por nova TimerView. Home fica fora da pilha (nao e problema: ao fazer Back no Timer, ConfirmStop + "Stop" pode fazer switchToView para Home) | Precisa garantir que Home e restauravel |
| B) popView ate Home, depois pushView TimerView | Mantem Home na pilha | Loop de popView e fragil, depende da pilha |

**Recomendacao:** Opcao A. `switchToView` reseta a pilha de forma limpa. Ao stopSession, tambem usar `switchToView` para Home.

### D4: ConfirmStop — custom View ou WatchUi.Confirmation nativo?

| Opcao | Pro | Contra |
|---|---|---|
| A) WatchUi.Confirmation nativo | Menos codigo | Estilo nao segue brand Toma, layout fixo |
| **B) Custom ConfirmStopView (recomendado)** | Respeita design system (bg, border, botoes), controle total | Mais codigo (mas simples) |

**Recomendacao:** Opcao B. A task especifica layout custom (C13) e a brand exige consistencia visual.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | `pushView` durante callback de observer pode causar race condition se multiplos eventos emitirem em sequencia | Model emite ON_PHASE_CHANGE uma unica vez por transicao. Testar no simulador. |
| 2 | PhaseTransition popView pode conflitar se usuario abriu ConfirmStop no exato momento da transicao | Verificar estado antes do dismiss: se view ativa nao e PhaseTransition, nao fazer popView. |
| 3 | `switchToView` pode nao existir em SDK antigo | Documentado desde SDK 3.x. Nosso minSdkVersion e 4.1.0 — seguro. |
| 4 | Stack de views pode ficar inconsistente se PhaseTransition push acontece durante pause | ON_PHASE_CHANGE so emite em `_transitionPhase()` que so roda se `!_paused` e `isRunning()`. Seguro: pause impede transicao. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Acao | Responsabilidade |
|---|---|---|
| `source/views/ConfirmStopView.mc` | **Criar** | Overlay visual: fundo, borda, titulo "Stop session?", 2 botoes com focus |
| `source/delegates/ConfirmStopDelegate.mc` | **Criar** | Input: Up/Down alterna foco, Select ativa, Back = Continue |
| `source/delegates/TimerDelegate.mc` | **Modificar** | `onBack()`: trocar stop direto por `pushView(ConfirmStopView)` |
| `source/delegates/CycleCompleteDelegate.mc` | **Modificar** | `onSelect()`: implementar "Start again" e "Done" reais |
| `source/TomaApp.mc` | **Modificar** | (1) Guardar `_lastPreset`. (2) `onModelEvent`: em ON_PHASE_CHANGE, pushView PhaseTransitionView. (3) Em `stopSession()`, fazer switchToView para Home. (4) Metodo `getLastPreset()`. |
| `source/ui/layout/Dimensions.mc` | **Modificar** | Adicionar dimensoes do ConfirmDialog |
| `resources/strings/strings.xml` | **Modificar** | Adicionar 3 strings do ConfirmDialog |
| `tests/PomodoroModelTest.mc` | **Modificar** | Adicionar testes: stop durante pause, stop durante break, eventos emitidos em stop |

---

## 6. Arquitetura do fluxo

```
[P3 TimerView running]
    │
    ├── Enter ──► Model.pause() ──► [P3/P4 TimerView paused]
    │                                    │
    │                                    ├── Enter ──► Model.resume() ──► [P3 running]
    │                                    │
    │                                    └── Back ──► pushView(ConfirmStopView)
    │                                                    │
    │                                                    ├── "Continue" ──► popView ──► [P4 paused]
    │                                                    │
    │                                                    └── "Stop" ──► app.stopSession()
    │                                                                    ──► switchToView(HomeView)
    │
    ├── Back ──► pushView(ConfirmStopView)
    │               │
    │               ├── "Continue" ──► popView ──► [P3 running]
    │               │
    │               └── "Stop" ──► app.stopSession() ──► switchToView(HomeView)
    │
    └── [remaining == 0] ──► Model._transitionPhase()
                               │
                               ├── (not completed) ──► TomaApp.onModelEvent(ON_PHASE_CHANGE)
                               │                         ──► pushView(PhaseTransitionView)
                               │                              ──► 3s auto-dismiss ──► popView
                               │                              ──► TimerView agora mostra nova fase
                               │
                               └── (completed) ──► TomaApp.onModelEvent(ON_COMPLETE)
                                                    ──► timerService.stop()
                                                    ──► switchToView(CycleCompleteView)
                                                         │
                                                         ├── "Start again" ──► app.startSession(lastPreset)
                                                         │                     ──► switchToView(TimerView)
                                                         │
                                                         └── "Done" / Back ──► switchToView(HomeView)
```

---

## 7. Referencias para o plan.md

- `source/model/PomodoroModel.mc` — estado atual do Model (nao precisa mudar).
- `source/TomaApp.mc` — ponto principal de modificacao (orquestracao).
- `source/delegates/TimerDelegate.mc` — trocar onBack.
- `source/delegates/CycleCompleteDelegate.mc` — implementar acoes reais.
- `source/views/PhaseTransitionView.mc` — ja completa, ver como e chamada.
- `source/views/CycleCompleteView.mc` — ja completa visualmente.
- `source/ui/components/PrimaryButton.mc` — reutilizar no ConfirmStopView.
- `references/architecture.md` secao 3 — regras de separacao View/Delegate/Model.
- `spec/spec.md` secoes B5, B6, P5, P6 — requisitos de produto.

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
