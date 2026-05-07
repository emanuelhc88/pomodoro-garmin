# Task 02-02: Timer Loop

## Objetivo

Implementar o **TimerService** — wrapper sobre `Toybox.Timer.Timer` que conecta o tick periódico ao `PomodoroModel`. Integrar TimerService + PomodoroModel + TimerView para que o countdown real funcione no simulador.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B3** Loop de countdown — `spec/spec.md` §4.B3
- Conecta `02-01-state-machine-pomodoro` ao mundo real (Toybox).

## Dependências

- `tasks/02-comportamentos/01-state-machine-pomodoro.md`.
- `tasks/01-prototipos-visuais/02-tela-timer-rodando.md`.
- `tasks/01-prototipos-visuais/05-tela-presets.md`.

## Critério de aceitação

### Automated

- [ ] Compila sem warnings.
- [ ] `--typecheck=Strict` passa.
- [ ] Testes existentes continuam passando.

### Manual

- [ ] Selecionar preset 25/5/4 em Home, pressionar Enter.
- [ ] TimerView abre com 25:00 e começa a contar (24:59, 24:58, ...).
- [ ] Anel circular preenche progressivamente (no simulador, acelerar pelo botão "speed up" ou usar preset Custom 1/1/2 para teste rápido).
- [ ] Ao chegar em 00:00, transição automática para break (visualmente: cor do anel muda, label muda, novo tempo aparece).
- [ ] Após 4 work-breaks, long break ativa.
- [ ] Após long break, navega para CycleCompleteView.
- [ ] Ao sair com Back (sem confirmar stop), timer continua rodando? **Decisão:** Back direto deve ir para confirm dialog (futuro `02-04`). Por ora, Back popView pausa? — definir aqui.

## Arquivos esperados

### Novos

- `source/services/TimerService.mc` — wrapper Toybox.Timer.

### Modificados

- `source/TomaApp.mc` — instanciar PomodoroModel + TimerService como singletons da app, expor via getters.
- `source/views/TimerView.mc` — usar dados reais do PomodoroModel em vez de hardcoded. Registrar observer no `onShow`, remover no `onHide`.
- `source/delegates/HomeDelegate.mc` — `onSelect` para preset agora chama `app.startSession(preset)` que coordena Model + TimerService.
- `tests/PomodoroModelTest.mc` — adicionar testes de tick em batch (não testa Timer real, testa Model.tick() chamado N vezes).

## Referências obrigatórias

- `references/architecture.md` §3 (Model não usa Toybox; Service sim), §4.
- `references/garmin_platform.md` §2.1 (Toybox.Timer).
- `spec/spec.md` §4.B3.

## Especificação técnica

### TimerService API

```monkeyc
using Toybox.Timer;

class TimerService {
    private var _timer as Timer.Timer;
    private var _onTick as Method?;

    function initialize() {
        _timer = new Timer.Timer();
    }

    function start(onTickCallback as Method) as Void {
        _onTick = onTickCallback;
        _timer.start(method(:_internalTick), 1000, true);
    }

    function stop() as Void {
        _timer.stop();
        _onTick = null;
    }

    function isRunning() as Boolean {
        // Toybox não expõe este check direto; manter flag interna.
        return _onTick != null;
    }

    private function _internalTick() as Void {
        if (_onTick != null) {
            _onTick.invoke();
        }
    }
}
```

### Conexão Model ↔ TimerService

`TomaApp` orquestra:

```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;

    function startSession(preset as Preset) as Void {
        _model.start(preset);
        _timerService.start(method(:onTimerTick));
    }

    function onTimerTick() as Void {
        if (_model.isPaused()) {
            return;
        }
        _model.tick();
        if (_model.getState() == :completed) {
            _timerService.stop();
            // Navigate to CycleComplete será feito na próxima task ou aqui.
        }
    }

    function pauseSession() as Void {
        _model.pause();
        // Timer continua rodando, mas onTimerTick respeita isPaused.
    }

    function stopSession() as Void {
        _model.stop();
        _timerService.stop();
    }
}
```

### View atualiza com dados reais

`TimerView` agora:

```monkeyc
class TimerView extends Ui.View {
    private var _model as PomodoroModel;

    function initialize(model as PomodoroModel) {
        Ui.View.initialize();
        _model = model;
    }

    function onShow() {
        _model.addObserver(method(:_onModelEvent));
    }

    function onHide() {
        _model.removeObserver(method(:_onModelEvent));
    }

    function onUpdate(dc) {
        var phase = _model.getState();
        var remaining = _model.getRemainingSeconds();
        var total = _model.getTotalSeconds();
        var progress = 1.0 - (remaining.toFloat() / total.toFloat());
        // ... draw ring, display, label, pills
    }

    function _onModelEvent(eventType as Symbol) as Void {
        Ui.requestUpdate();
        // Se phase mudou, próxima task pode disparar PhaseTransitionView.
    }
}
```

### Decisão: Back em P3 sem confirm dialog ainda

Como a task `02-04` cobre confirm dialog, nesta task o Back popView direto e **chama `stopSession()`**. Documentar no PRD que isso é provisório.

## Out of scope desta task

- Confirm dialog para Stop (`02-04`).
- Pausa/Resume real (`02-04`).
- Vibração nas transições (`02-03`).
- Navegação automática para PhaseTransitionView entre fases (`02-04` ou separar — definir).
- ActivityRecording (`02-10`).
