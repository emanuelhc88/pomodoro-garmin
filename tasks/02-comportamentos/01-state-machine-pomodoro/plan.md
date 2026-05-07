# Plan — Task 02-01: State Machine Pomodoro

> Spec Tatica gerada na FASE 2.3. Executar com `/execute` na proxima sessao.

---

## 1. Resumo

Implementar `PomodoroModel` — a state machine pura (sem dependencias Toybox alem de `Lang`) que governa toda a logica de dominio do timer Pomodoro. Cobre transicoes IDLE -> RUNNING_WORK -> RUNNING_SHORT_BREAK -> ... -> RUNNING_LONG_BREAK -> COMPLETED, incluindo pause/resume/stop. Observer pattern via `Method` callbacks. Acompanha testes unitarios completos.

---

## 2. Cenarios

### Caminho feliz

1. App cria `PomodoroModel`.
2. Chama `model.start(preset)` com preset 25/5/4.
3. Estado muda para `:running_work`, `remainingSeconds = 1500`, `currentCycle = 1`.
4. A cada segundo, servico externo chama `model.tick()`. Model decrementa remaining e emite `:onTick`.
5. Ao zerar remaining na work phase: `cyclesCompleted` incrementa, transiciona para `:running_short_break` (5min).
6. Ao zerar short break: `currentCycle` incrementa, transiciona para `:running_work` novamente.
7. Repete ate `cyclesCompleted == preset.cycles` (4). Ultimo work -> `:running_long_break` (15min).
8. Ao zerar long break: transiciona para `:completed`, emite `:onComplete`.

### Edge cases

- **Preset com cycles == 1:** Apos unica work phase, vai direto para `:completed` (sem long break).
- **pause() durante qualquer fase:** Congela remaining, muda flag `_paused = true`, emite `:onPause`. `tick()` vira no-op enquanto pausado.
- **resume() apos pause:** Retoma, emite `:onResume`. `tick()` volta a decrementar.
- **stop() durante qualquer fase:** Reseta tudo para IDLE, emite `:onStop`.
- **Acoes invalidas (ex: pause() em IDLE, start() em RUNNING_WORK):** No-op silencioso. Debug log via `System.println` com annotation `(:debug)`.
- **tick() em IDLE ou COMPLETED:** No-op.
- **Multiplos observers:** Todos recebem todos os eventos na ordem de registro.
- **removeObserver com Method nao registrado:** No-op.

### Erros

- Nenhuma excecao lancada pelo Model. Acoes invalidas sao no-op (per architecture.md §4).
- Se `preset` passado a `start()` tiver valores fora dos limites de `PresetLimits`, o Model aceita mesmo assim (validacao e responsabilidade da UI/P2 — Model nao valida).

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/model/PomodoroState.mc` | Module com constantes Symbol para estados + funcao helper `isRunning(state)` |
| 2 | `source/model/PomodoroEvent.mc` | Module com constantes Symbol para eventos emitidos |
| 3 | `source/model/PomodoroModel.mc` | Classe principal: state machine, tick, pause/resume/stop/start, observer pattern |
| 4 | `tests/PomodoroModelTest.mc` | Testes unitarios cobrindo todas as transicoes e edge cases |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `monkey.jungle` | Adicionar `base.barrelPath` e sourcePath para testes |

### 4.1 `monkey.jungle`

**Antes:**
```
project.manifest = manifest.xml

base.sourcePath = source
base.resourcePath = resources;resources-por
```

**Depois:**
```
project.manifest = manifest.xml

base.sourcePath = source;tests
base.resourcePath = resources;resources-por
```

---

## 5. Storage/Properties (se aplicavel)

Nenhum. Esta task e pure logic sem persistencia. Storage sera adicionado em tasks futuras (B3 throttle, B16 recovery).

---

## 6. Checklist de execucao

- [x] 1. Criar diretorio `tests/` na raiz do projeto
- [x] 2. Criar `source/model/PomodoroState.mc`
- [x] 3. Criar `source/model/PomodoroEvent.mc`
- [x] 4. Criar `source/model/PomodoroModel.mc`
- [x] 5. Criar `tests/PomodoroModelTest.mc`
- [x] 6. Modificar `monkey.jungle` (adicionar `tests` ao sourcePath)
- [x] 7. Build para fr255 (`monkeyc -d fr255 -f monkey.jungle -o bin/app.prg -y developer_key.der`)
- [x] 8. Build para fr255s
- [x] 9. Build para fr265
- [x] 10. Build com `--unit-test` e rodar testes no simulador

---

## 7. Criterios de aceite

### Automated
- [x] `monkeyc -d fr255 -f monkey.jungle -o bin/app.prg -y developer_key.der` compila sem erros
- [x] `monkeyc -d fr255s -f monkey.jungle -o bin/app.prg -y developer_key.der` compila sem erros
- [x] `monkeyc -d fr265 -f monkey.jungle -o bin/app.prg -y developer_key.der` compila sem erros
- [x] Build com `--unit-test` compila sem erros

### Manual (simulador)
- [ ] Testes unitarios passam (output do test runner mostra todos verdes)
- [ ] Nenhuma regressao nas telas existentes (app abre em P1 normalmente)

---

## 8. Out of scope

- TimerService (wrapper Toybox.Timer) — task 02-02.
- Persistencia de estado em Storage (recovery B16) — task 02-10.
- Emissao de vibracoes/sons (B7/B8) — tasks 02-04/02-05.
- Contagem diaria de sessoes (B9) — task 02-06.
- Gravacao FIT (B11) — task 02-08.
- Integracao com Views (registrar observer no onShow/onHide) — task 02-02+.
- Validacao de limites do preset (responsabilidade da UI em P2/B2).

---

## Apendice A: Codigo completo dos arquivos a criar

### A.1 `source/model/PomodoroState.mc`

```monkeyc
using Toybox.Lang;

module PomodoroState {
    enum {
        IDLE,
        RUNNING_WORK,
        RUNNING_SHORT_BREAK,
        RUNNING_LONG_BREAK,
        PAUSED,
        COMPLETED
    }

    function isRunning(state as Lang.Number) as Lang.Boolean {
        return (state == RUNNING_WORK || state == RUNNING_SHORT_BREAK || state == RUNNING_LONG_BREAK);
    }
}
```

### A.2 `source/model/PomodoroEvent.mc`

```monkeyc
module PomodoroEvent {
    enum {
        ON_START,
        ON_TICK,
        ON_PHASE_CHANGE,
        ON_WORK_PHASE_COMPLETE,
        ON_PAUSE,
        ON_RESUME,
        ON_STOP,
        ON_COMPLETE
    }
}
```

### A.3 `source/model/PomodoroModel.mc`

```monkeyc
using Toybox.Lang;
using Toybox.System;

class PomodoroModel {
    var _state as Lang.Number = PomodoroState.IDLE;
    var _preset as Preset or Null = null;
    var _remainingSeconds as Lang.Number = 0;
    var _totalPhaseSeconds as Lang.Number = 0;
    var _currentCycle as Lang.Number = 0;
    var _cyclesCompleted as Lang.Number = 0;
    var _paused as Lang.Boolean = false;
    var _observers as Lang.Array<Lang.Method> = [] as Lang.Array<Lang.Method>;

    function initialize() {
    }

    // --- Public API ---

    function start(preset as Preset) as Void {
        if (_state != PomodoroState.IDLE && _state != PomodoroState.COMPLETED) {
            _debugLog("start() ignored: not in IDLE or COMPLETED");
            return;
        }
        _preset = preset;
        _cyclesCompleted = 0;
        _currentCycle = 1;
        _paused = false;
        _state = PomodoroState.RUNNING_WORK;
        _remainingSeconds = preset.workMin * 60;
        _totalPhaseSeconds = _remainingSeconds;
        _emit(PomodoroEvent.ON_START);
        _emit(PomodoroEvent.ON_PHASE_CHANGE);
    }

    function tick() as Void {
        if (!PomodoroState.isRunning(_state) || _paused) {
            return;
        }
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _transitionPhase();
        } else {
            _emit(PomodoroEvent.ON_TICK);
        }
    }

    function pause() as Void {
        if (!PomodoroState.isRunning(_state) || _paused) {
            _debugLog("pause() ignored: not running or already paused");
            return;
        }
        _paused = true;
        _state = PomodoroState.PAUSED;
        _emit(PomodoroEvent.ON_PAUSE);
    }

    function resume() as Void {
        if (_state != PomodoroState.PAUSED) {
            _debugLog("resume() ignored: not paused");
            return;
        }
        _paused = false;
        _state = _getRunningStateForResume();
        _emit(PomodoroEvent.ON_RESUME);
    }

    function stop() as Void {
        if (_state == PomodoroState.IDLE || _state == PomodoroState.COMPLETED) {
            _debugLog("stop() ignored: already idle or completed");
            return;
        }
        _state = PomodoroState.IDLE;
        _paused = false;
        _remainingSeconds = 0;
        _totalPhaseSeconds = 0;
        _currentCycle = 0;
        _cyclesCompleted = 0;
        _preset = null;
        _emit(PomodoroEvent.ON_STOP);
    }

    // --- Observers ---

    function addObserver(callback as Lang.Method) as Void {
        _observers.add(callback);
    }

    function removeObserver(callback as Lang.Method) as Void {
        var idx = _observers.indexOf(callback);
        if (idx != -1) {
            _observers.remove(callback);
        }
    }

    // --- Getters ---

    function getState() as Lang.Number {
        return _state;
    }

    function getRemainingSeconds() as Lang.Number {
        return _remainingSeconds;
    }

    function getTotalPhaseSeconds() as Lang.Number {
        return _totalPhaseSeconds;
    }

    function getCurrentCycle() as Lang.Number {
        return _currentCycle;
    }

    function getCyclesCompleted() as Lang.Number {
        return _cyclesCompleted;
    }

    function getTotalCycles() as Lang.Number {
        if (_preset != null) {
            return (_preset as Preset).cycles;
        }
        return 0;
    }

    function isPaused() as Lang.Boolean {
        return _paused;
    }

    function getPreset() as Preset or Null {
        return _preset;
    }

    // --- Private ---

    hidden function _transitionPhase() as Void {
        var preset = _preset as Preset;

        if (_state == PomodoroState.RUNNING_WORK) {
            _cyclesCompleted += 1;
            _emit(PomodoroEvent.ON_WORK_PHASE_COMPLETE);

            if (_cyclesCompleted >= preset.cycles) {
                if (preset.cycles == 1) {
                    _state = PomodoroState.COMPLETED;
                    _totalPhaseSeconds = 0;
                    _emit(PomodoroEvent.ON_PHASE_CHANGE);
                    _emit(PomodoroEvent.ON_COMPLETE);
                } else {
                    _state = PomodoroState.RUNNING_LONG_BREAK;
                    _remainingSeconds = preset.breakMin * 3 * 60;
                    _totalPhaseSeconds = _remainingSeconds;
                    _emit(PomodoroEvent.ON_PHASE_CHANGE);
                }
            } else {
                _state = PomodoroState.RUNNING_SHORT_BREAK;
                _remainingSeconds = preset.breakMin * 60;
                _totalPhaseSeconds = _remainingSeconds;
                _emit(PomodoroEvent.ON_PHASE_CHANGE);
            }
        } else if (_state == PomodoroState.RUNNING_SHORT_BREAK) {
            _currentCycle += 1;
            _state = PomodoroState.RUNNING_WORK;
            _remainingSeconds = preset.workMin * 60;
            _totalPhaseSeconds = _remainingSeconds;
            _emit(PomodoroEvent.ON_PHASE_CHANGE);
        } else if (_state == PomodoroState.RUNNING_LONG_BREAK) {
            _state = PomodoroState.COMPLETED;
            _totalPhaseSeconds = 0;
            _emit(PomodoroEvent.ON_PHASE_CHANGE);
            _emit(PomodoroEvent.ON_COMPLETE);
        }
    }

    hidden function _getRunningStateForResume() as Lang.Number {
        if (_cyclesCompleted >= (_preset as Preset).cycles) {
            return PomodoroState.RUNNING_LONG_BREAK;
        }
        if (_currentCycle > _cyclesCompleted) {
            return PomodoroState.RUNNING_WORK;
        }
        return PomodoroState.RUNNING_SHORT_BREAK;
    }

    hidden function _emit(event as Lang.Number) as Void {
        for (var i = 0; i < _observers.size(); i++) {
            (_observers[i] as Lang.Method).invoke(event);
        }
    }

    (:debug)
    hidden function _debugLog(msg as Lang.String) as Void {
        System.println("[PomodoroModel] " + msg);
    }
}
```

### A.4 `tests/PomodoroModelTest.mc`

```monkeyc
using Toybox.Test;
using Toybox.Lang;

(:test)
function testStartSetsRunningWork(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(25, 5, 4, false);
    model.start(preset);
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "State should be RUNNING_WORK");
    Test.assertEqualMessage(1500, model.getRemainingSeconds(), "Remaining should be 25*60=1500");
    Test.assertEqualMessage(1, model.getCurrentCycle(), "Current cycle should be 1");
    Test.assertEqualMessage(0, model.getCyclesCompleted(), "Cycles completed should be 0");
    return true;
}

(:test)
function testTickDecrementsRemaining(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick();
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "After 1 tick, remaining should be 1499");
    return true;
}

(:test)
function testTickNoOpWhenIdle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.tick();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should remain IDLE");
    Test.assertEqualMessage(0, model.getRemainingSeconds(), "Remaining should stay 0");
    return true;
}

(:test)
function testTickNoOpWhenPaused(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.pause();
    var remaining = model.getRemainingSeconds();
    model.tick();
    Test.assertEqualMessage(remaining, model.getRemainingSeconds(), "Remaining should not change while paused");
    return true;
}

(:test)
function testWorkToShortBreakTransition(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    // Simulate all ticks of first work phase
    for (var i = 0; i < 1500; i++) {
        model.tick();
    }
    Test.assertEqualMessage(PomodoroState.RUNNING_SHORT_BREAK, model.getState(), "Should transition to SHORT_BREAK");
    Test.assertEqualMessage(300, model.getRemainingSeconds(), "Short break should be 5*60=300");
    Test.assertEqualMessage(1, model.getCyclesCompleted(), "Cycles completed should be 1");
    return true;
}

(:test)
function testShortBreakToWorkTransition(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    // Complete first work phase
    for (var i = 0; i < 1500; i++) {
        model.tick();
    }
    // Complete short break
    for (var i = 0; i < 300; i++) {
        model.tick();
    }
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "Should transition back to RUNNING_WORK");
    Test.assertEqualMessage(1500, model.getRemainingSeconds(), "New work phase should be 25*60=1500");
    Test.assertEqualMessage(2, model.getCurrentCycle(), "Current cycle should be 2");
    return true;
}

(:test)
function testLastWorkToLongBreakTransition(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete 3 work + 3 short break cycles
    for (var cycle = 0; cycle < 3; cycle++) {
        for (var i = 0; i < 60; i++) { model.tick(); } // work (1min)
        for (var i = 0; i < 60; i++) { model.tick(); } // short break (1min)
    }
    // Complete 4th (last) work phase
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should transition to LONG_BREAK");
    Test.assertEqualMessage(180, model.getRemainingSeconds(), "Long break should be 1*3*60=180");
    return true;
}

(:test)
function testLongBreakToCompleted(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete 3 work + 3 short break + 4th work
    for (var cycle = 0; cycle < 3; cycle++) {
        for (var i = 0; i < 60; i++) { model.tick(); }
        for (var i = 0; i < 60; i++) { model.tick(); }
    }
    for (var i = 0; i < 60; i++) { model.tick(); }
    // Complete long break (3min)
    for (var i = 0; i < 180; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Should be COMPLETED");
    return true;
}

(:test)
function testSingleCycleNoLongBreak(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 1, false);
    model.start(preset);
    // Complete the single work phase (1min)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Single cycle should go directly to COMPLETED");
    return true;
}

(:test)
function testPauseAndResume(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick(); // remaining = 1499
    model.pause();
    Test.assertEqualMessage(PomodoroState.PAUSED, model.getState(), "Should be PAUSED");
    Test.assertEqualMessage(true, model.isPaused(), "isPaused should be true");
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "Should resume to RUNNING_WORK");
    Test.assertEqualMessage(false, model.isPaused(), "isPaused should be false");
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "Remaining should not change during pause");
    return true;
}

(:test)
function testPauseInShortBreakResumesCorrectly(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete first work phase
    for (var i = 0; i < 60; i++) { model.tick(); }
    // Now in short break, pause
    model.pause();
    Test.assertEqualMessage(PomodoroState.PAUSED, model.getState(), "Should be PAUSED");
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_SHORT_BREAK, model.getState(), "Should resume to SHORT_BREAK");
    return true;
}

(:test)
function testPauseInLongBreakResumesCorrectly(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete 3 work + 3 short break + 4th work to get to long break
    for (var cycle = 0; cycle < 3; cycle++) {
        for (var i = 0; i < 60; i++) { model.tick(); }
        for (var i = 0; i < 60; i++) { model.tick(); }
    }
    for (var i = 0; i < 60; i++) { model.tick(); }
    // Now in long break
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should be in LONG_BREAK");
    model.pause();
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should resume to LONG_BREAK");
    return true;
}

(:test)
function testStopResetsEverything(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick();
    model.stop();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should be IDLE after stop");
    Test.assertEqualMessage(0, model.getRemainingSeconds(), "Remaining should be 0");
    Test.assertEqualMessage(0, model.getCurrentCycle(), "Cycle should be 0");
    Test.assertEqualMessage(0, model.getCyclesCompleted(), "CyclesCompleted should be 0");
    Test.assertEqualMessage(null, model.getPreset(), "Preset should be null");
    return true;
}

(:test)
function testStartIgnoredWhenRunning(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick();
    model.start(new Preset(50, 10, 4, false));
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "Should not restart — remaining stays at 1499");
    return true;
}

(:test)
function testPauseIgnoredWhenIdle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.pause();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should remain IDLE");
    return true;
}

(:test)
function testResumeIgnoredWhenNotPaused(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "Should remain RUNNING_WORK");
    return true;
}

(:test)
function testStopIgnoredWhenIdle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.stop();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should remain IDLE");
    return true;
}

(:test)
function testObserverReceivesEvents(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var tracker = new EventTracker();
    model.addObserver(tracker.method(:onEvent));
    model.start(new Preset(25, 5, 4, false));
    // Should have received ON_START and ON_PHASE_CHANGE
    Test.assertEqualMessage(2, tracker.events.size(), "Should receive 2 events on start");
    Test.assertEqualMessage(PomodoroEvent.ON_START, tracker.events[0], "First event should be ON_START");
    Test.assertEqualMessage(PomodoroEvent.ON_PHASE_CHANGE, tracker.events[1], "Second event should be ON_PHASE_CHANGE");
    return true;
}

(:test)
function testRemoveObserverStopsEvents(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var tracker = new EventTracker();
    var cb = tracker.method(:onEvent);
    model.addObserver(cb);
    model.start(new Preset(25, 5, 4, false));
    model.removeObserver(cb);
    model.tick();
    // After remove, should NOT get ON_TICK
    Test.assertEqualMessage(2, tracker.events.size(), "Should still have only 2 events from start");
    return true;
}

(:test)
function testFullCycle25_5_4(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);

    // Cycle 1: work(60s) + short break(60s)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(1, model.getCyclesCompleted(), "After 1st work: completed=1");
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(2, model.getCurrentCycle(), "After 1st break: cycle=2");

    // Cycle 2: work(60s) + short break(60s)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(2, model.getCyclesCompleted(), "After 2nd work: completed=2");
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(3, model.getCurrentCycle(), "After 2nd break: cycle=3");

    // Cycle 3: work(60s) + short break(60s)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(3, model.getCyclesCompleted(), "After 3rd work: completed=3");
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(4, model.getCurrentCycle(), "After 3rd break: cycle=4");

    // Cycle 4 (last): work(60s) -> long break(180s) -> completed
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(4, model.getCyclesCompleted(), "After 4th work: completed=4");
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should be in LONG_BREAK");
    for (var i = 0; i < 180; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Should be COMPLETED");

    return true;
}

(:test)
function testTotalPhaseSecondsUpdates(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    Test.assertEqualMessage(1500, model.getTotalPhaseSeconds(), "Total phase seconds should be 1500 for work");
    // Transition to short break
    for (var i = 0; i < 1500; i++) { model.tick(); }
    Test.assertEqualMessage(300, model.getTotalPhaseSeconds(), "Total phase seconds should be 300 for short break");
    return true;
}

// --- Helper class for observer testing ---
class EventTracker {
    var events as Lang.Array<Lang.Number> = [] as Lang.Array<Lang.Number>;

    function initialize() {
    }

    function onEvent(event as Lang.Number) as Void {
        events.add(event);
    }
}
```

---

## Notas de implementacao

### Decisao: enum vs Symbol para estados/eventos

O PRD recomendava Symbols (`:idle`, `:running_work`, etc.). Porem, apos analisar o codigo existente e as melhores praticas de Connect IQ com typecheck strict:

**Decisao final: usar `enum` (inteiros) em modules.**

Justificativa:
- `enum` em Monkey C gera constantes inteiras — leve, comparavel com `==`, compativel com typecheck strict.
- Symbols requerem type `Symbol` que nao suporta comparacoes tipadas limpa com typecheck.
- O padrao architecture.md §4 define "constantes: UPPER_SNAKE_CASE" — alinha com enum values.
- Observers recebem `Lang.Number` (o event ID) — uniforme e sem alocacao extra.

### Decisao: estado PAUSED como estado proprio vs flag

**Decisao: PAUSED e um estado na enum + flag `_paused` interno.**

Justificativa:
- Views precisam distinguir visualmente PAUSED de running (P4 vs P3).
- Ao fazer resume, o Model precisa saber *qual* running state restaurar. O metodo `_getRunningStateForResume()` usa `_cyclesCompleted` e `_currentCycle` para inferir isso sem guardar estado extra.

### Observer pattern: assinatura do callback

```monkeyc
function onEvent(event as Lang.Number) as Void
```

Observer consulta getters do model para dados adicionais (remaining, cycle, etc). Nenhum payload extra no evento.
