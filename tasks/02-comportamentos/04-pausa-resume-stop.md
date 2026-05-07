# Task 02-04: Pause / Resume / Stop

## Objetivo

Implementar o ciclo completo de **Pause → Resume → Stop** com confirmação. Incluir:
- Toggle pause/resume via Enter no TimerView (sai e volta de P3 para P4).
- Stop com `Confirm Dialog` (C13) ao apertar Back em P3 ou P4.
- Auto-navegação para PhaseTransitionView (P5) entre fases e CycleCompleteView (P6) ao concluir.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B5** Pausa / Resume — `spec/spec.md` §4.B5
- **B6** Stop / Reset — `spec/spec.md` §4.B6
- **C13** Confirm Dialog
- Conecta P3 → P5 → P3 (transition) e P3/longBreak → P6 (cycle complete).

## Dependências

- `tasks/02-comportamentos/02-timer-loop.md`.
- `tasks/01-prototipos-visuais/03-tela-pausa.md`.
- `tasks/01-prototipos-visuais/04-tela-fim-sessao.md`.

## Critério de aceitação

### Automated

- [ ] Compila sem warnings.
- [ ] `--typecheck=Strict` passa.
- [ ] Testes do PomodoroModel cobrem pause/resume/stop em diferentes estados.

### Manual

- [ ] Em P3 (Timer rodando), pressionar Enter pausa: visual muda para P4 (paused), countdown congela.
- [ ] Em P4, pressionar Enter resume: countdown retoma de onde parou.
- [ ] Em P3 ou P4, pressionar Back abre dialog "Stop session? [Stop / Continue]".
- [ ] Selecionar "Continue" no dialog: dialog fecha, timer continua (se estava rodando).
- [ ] Selecionar "Stop": dialog fecha, navega para Home (P1), sessão é descartada (não vai para histórico).
- [ ] Quando uma fase termina (remaining → 0), automaticamente:
  - Vibração apropriada dispara.
  - PhaseTransitionView (P5) abre por 3s.
  - Após 3s, volta para TimerView com nova fase.
- [ ] Quando o último ciclo (long break) termina:
  - Vibração de cycle complete dispara.
  - CycleCompleteView (P6) abre.
- [ ] Em P6, "Start again" reinicia sessão com mesmo preset.
- [ ] Em P6, "Done" volta para Home.

## Arquivos esperados

### Novos

- `source/views/ConfirmStopView.mc` — overlay/view de confirmação.
- `source/delegates/ConfirmStopDelegate.mc`.

### Modificados

- `source/delegates/TimerDelegate.mc` — `onSelect`: toggle pause/resume. `onBack`: pushView de ConfirmStopView.
- `source/views/TimerView.mc` — refletir estado paused via observer do Model.
- `source/TomaApp.mc` — handler de eventos Model: ao `:onPhaseChange`, navegar para PhaseTransitionView (push) e depois pop+update; ao `:onComplete`, navegar para CycleCompleteView.
- `source/views/PhaseTransitionView.mc` — agora recebe Model em vez de mock; lê próxima fase do Model.
- `source/views/CycleCompleteView.mc` — receber session info do Model.

## Referências obrigatórias

- `references/architecture.md` §3 (Delegate input only; navigation via pushView/popView).
- `spec/spec.md` §4.B5, §4.B6, §2.P5, §2.P6.

## Especificação técnica

### TimerDelegate atualizado

```monkeyc
class TimerDelegate extends Ui.BehaviorDelegate {
    private var _app as TomaApp;

    function initialize(app as TomaApp) {
        Ui.BehaviorDelegate.initialize();
        _app = app;
    }

    function onSelect() as Boolean {
        if (_app.getModel().isPaused()) {
            _app.resumeSession();
        } else {
            _app.pauseSession();
        }
        Ui.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        Ui.pushView(
            new ConfirmStopView(),
            new ConfirmStopDelegate(_app),
            Ui.SLIDE_UP // overlay style
        );
        return true;
    }
}
```

### ConfirmStopView

Overlay simples:
- Fundo `surface` com border `border`.
- Título "Stop session?" / "Parar sessão?" centralizado.
- 2 botões: "Stop" (destacado) e "Continue".
- Up/Down alterna foco; Enter ativa; Back equivalente a "Continue".

### Auto-navegação ao mudar fase

Há tensão arquitetural: View não deveria iniciar navegações por conta própria; mas onde colocar essa lógica?

**Decisão:** o `TomaApp` (controller-like) escuta eventos do Model. Em `:onPhaseChange`:

```monkeyc
function _onModelEvent(eventType as Symbol) {
    if (eventType == :onPhaseChange) {
        if (_model.getState() != :idle && _model.getState() != :completed) {
            // Push transition view por 3s
            Ui.pushView(new PhaseTransitionView(_model.getState()),
                       new PhaseTransitionDelegate(),
                       Ui.SLIDE_LEFT);
            // PhaseTransitionView agenda popView automático após 3s.
        }
    } else if (eventType == :onComplete) {
        Ui.pushView(new CycleCompleteView(_model),
                   new CycleCompleteDelegate(_app),
                   Ui.SLIDE_LEFT);
    }
}
```

**Atenção:** popView automático da PhaseTransition deve voltar para TimerView que **continua** existindo na pilha. Validar que pilha não duplica TimerView.

### Estado paused do Model

`PomodoroModel.pause()` seta flag interna. `tick()` faz no-op se paused. Não para o TimerService (que continua rodando). Justificativa: simplifica recovery — `TimerService.stop` acidental não é problema, e ligar/desligar Timer com frequência tem custo.

Alternativa: parar TimerService no pause. **Decidir no PRD.**

### Comportamento "Start again" em CycleComplete

```monkeyc
class CycleCompleteDelegate extends Ui.BehaviorDelegate {
    private var _app as TomaApp;

    function initialize(app) { ... }

    function onSelect() {
        if (_focusedButton == :start_again) {
            // Pop até Home e re-startar com mesmo preset
            var preset = _app.getLastPreset();
            Ui.popView(Ui.SLIDE_RIGHT); // pop CycleComplete
            Ui.popView(Ui.SLIDE_RIGHT); // pop TimerView (estava embaixo)
            _app.startSession(preset);
        } else if (_focusedButton == :done) {
            // Pop tudo até Home
            while (Ui.getCurrentView()[0] is HomeView == false) {
                Ui.popView(Ui.SLIDE_RIGHT);
            }
        }
        return true;
    }
}
```

⚠️ Pseudocódigo. `Ui.getCurrentView()` retorna `[view, delegate]`. Comparação `is HomeView` pode ser `instanceof HomeView` em Monkey C — verificar sintaxe.

## Out of scope desta task

- Salvar sessão no histórico ao completar (`02-09`).
- ActivityRecording start/stop (`02-10`).
- Recovery após kill (`02-08`).
