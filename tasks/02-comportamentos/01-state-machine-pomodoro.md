# Task 02-01: State Machine Pomodoro

## Objetivo

Implementar o **PomodoroModel** — coração da lógica de domínio. State machine com transições rigorosas entre `IDLE → RUNNING_WORK → RUNNING_SHORT_BREAK → ... → RUNNING_LONG_BREAK → COMPLETED`. Sem dependências de Toybox APIs (puro Monkey C). Testável.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B4** Transição de fase (state machine) — `spec/spec.md` §4.B4

## Dependências

- `tasks/01-prototipos-visuais/05-tela-presets.md` (Preset.mc existente).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings.
- [ ] `--typecheck=Strict` passa.
- [ ] **Testes unitários** em `tests/PomodoroModelTest.mc` cobrem:
  - Transição IDLE → RUNNING_WORK ao chamar `start(preset)`.
  - Transição RUNNING_WORK → RUNNING_SHORT_BREAK quando work termina e cycles_done < total - 1.
  - Transição RUNNING_SHORT_BREAK → RUNNING_WORK ao terminar break.
  - Transição RUNNING_WORK → RUNNING_LONG_BREAK no último ciclo.
  - Transição RUNNING_LONG_BREAK → COMPLETED ao terminar.
  - Início inválido em estado != IDLE retorna sem erro (ou loga e ignora — definir).
  - Tick decrementa `remainingSeconds`.
  - `cyclesCompleted` incrementa só após work-phase concluída.
- [ ] Testes rodam via `monkeyc --unit-test` e passam.

### Manual

- [ ] (Sem manual nesta task — pure logic.)

## Arquivos esperados

### Novos

- `source/model/PomodoroState.mc` — symbols `:idle, :running_work, :running_short_break, :running_long_break, :completed`.
- `source/model/PomodoroModel.mc` — classe principal com state machine.
- `source/model/PomodoroEvent.mc` — symbols `:onStart, :onPhaseChange, :onTick, :onWorkPhaseComplete, :onComplete, :onPause, :onResume, :onStop`.
- `tests/PomodoroModelTest.mc` — testes unitários.

### Modificados

- `monkey.jungle` — habilitar `--unit-test` para target test.

## Referências obrigatórias

- `references/architecture.md` §3 (Model — sem dependências externas), §4 (regras de naming, tipos).
- `references/workflow.md` §8 (testes obrigatórios em model/).
- `spec/spec.md` §4.B4, §6 (regras de negócio).

## Especificação técnica

### API pública do PomodoroModel

```monkeyc
class PomodoroModel {
    // --- State (read-only) ---
    function getState() as Symbol;
    function getRemainingSeconds() as Number;
    function getTotalSeconds() as Number;
    function getCyclesCompleted() as Number;
    function getCurrentCycle() as Number;
    function getPreset() as Preset?;
    function isPaused() as Boolean;

    // --- Actions ---
    function start(preset as Preset) as Void;
    function pause() as Void;
    function resume() as Void;
    function stop() as Void;
    function tick() as Void;

    // --- Observer pattern ---
    function addObserver(callback as Method) as Void;
    function removeObserver(callback as Method) as Void;
}
```

### Comportamento de cada ação

| Ação | Pre-condição | Pós-condição | Eventos emitidos |
|---|---|---|---|
| `start(preset)` | state == IDLE | state = RUNNING_WORK; remaining = preset.workMin*60; current_cycle = 1 | `:onStart`, `:onPhaseChange(null → :running_work)` |
| `tick()` | state in (RUNNING_*) and !paused | remaining -= 1; se remaining == 0 → transition | `:onTick`. Se transition: `:onWorkPhaseComplete` (se vinha de work), `:onPhaseChange`, e `:onComplete` se foi última. |
| `pause()` | state in (RUNNING_*) | paused = true | `:onPause` |
| `resume()` | state in (RUNNING_*) and paused | paused = false | `:onResume` |
| `stop()` | state in (RUNNING_*) | state = IDLE; reset estado interno | `:onStop` |

Outras combinações (ex: pause em IDLE) → no-op + log.

### Regra de transição de fase ao remaining == 0

```monkeyc
function _transitionPhase() as Void {
    if (_state == :running_work) {
        _cyclesCompleted += 1;
        _emit(:onWorkPhaseComplete);

        if (_cyclesCompleted < _preset.cycles - 1) {
            // Mais work-break a fazer; próxima é short break.
            _state = :running_short_break;
            _remainingSeconds = _preset.breakMin * 60;
        } else if (_cyclesCompleted == _preset.cycles - 1) {
            // Último work feito; agora long break (mas se cycles == 1, não há long break — só completa).
            // Atenção: para presets builtin de 4 ciclos, regra é: depois de 4 work-phases, vem o long break.
            // Reler regra em spec/spec.md §6.1.
            _state = :running_long_break;
            _remainingSeconds = _preset.breakMin * 60 * 3; // long break = 3x short break? CONFIRMAR.
        } else {
            // Já completamos tudo
            _state = :completed;
            _emit(:onComplete);
        }
    } else if (_state == :running_short_break) {
        _state = :running_work;
        _remainingSeconds = _preset.workMin * 60;
    } else if (_state == :running_long_break) {
        _state = :completed;
        _emit(:onComplete);
    }

    _emit(:onPhaseChange);
}
```

### ⚠️ Decisão pendente: Long break duration

A spec macro diz:
> Long break só após 4º work-break completo, não a cada 4 sessions de qualquer tipo.

Mas **não define** a duração do long break. Convenções comuns:
- Pomodoro original: long break = 15-30 min após 4 ciclos.
- Toma: provavelmente queremos uma duração derivada do preset.

**Decidir nesta task** (resolver no PRD da FASE 2.1):
- Opção A: long break duration é 3× short break (5min → 15min).
- Opção B: long break duration tem preset independente (ex: 15min fixo).
- Opção C: para presets builtin, hardcode (25/5 → long=15; 30/5 → long=15; 50/10 → long=20). Custom não tem long break (ou tem? user define?).

**Recomendação inicial:** opção A (long break = 3x short break). Simples, derivado, predizível. Pode revisar após validar com usuários.

Dependendo da decisão, atualizar `Preset.mc` para incluir `longBreakMin` calculado dinamicamente, ou adicionar campo separado.

### Observer pattern

Model **não chama** Toybox APIs (incluindo `Ui.requestUpdate`). Em vez disso, emite eventos para observadores. View do Timer registra-se como observer no `onShow` e remove no `onHide`. Quando recebe evento, chama `Ui.requestUpdate()`.

```monkeyc
class TimerView extends Ui.View {
    function onShow() {
        _model.addObserver(method(:onModelEvent));
    }

    function onModelEvent(eventType as Symbol) {
        Ui.requestUpdate();
    }
}
```

### Testes

```monkeyc
using Toybox.Test;

(:test)
function testStartFromIdle(logger as Test.Logger) as Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(25, 5, 4, false);
    model.start(preset);
    Test.assertEqualMessage(:running_work, model.getState(), "should be running_work");
    Test.assertEqualMessage(1500, model.getRemainingSeconds(), "should be 25*60s");
    Test.assertEqualMessage(0, model.getCyclesCompleted(), "no cycle done yet");
    return true;
}

(:test)
function testWorkToShortBreak(logger as Test.Logger) as Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 2, false); // 1 min para acelerar
    model.start(preset);
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(:running_short_break, model.getState(), "should transition to break");
    Test.assertEqualMessage(1, model.getCyclesCompleted(), "1 work done");
    return true;
}

// ... testes para todas as transições
```

## Out of scope desta task

- Integração com TimerService (`02-02-timer-loop`).
- Vibração ao transicionar (`02-03-vibracao-inicio-fim`).
- ActivityRecording (`02-10-fit-activity-recording`).
- Persistência de estado (`02-08`).
