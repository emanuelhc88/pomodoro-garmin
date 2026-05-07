# Plan — Task 02-02: Timer Loop

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar o `TimerService` (wrapper sobre `Toybox.Timer.Timer` com ticks de 1s), conectá-lo ao `PomodoroModel` existente via `TomaApp` como orquestrador, refatorar `TimerView` para ler estado real do Model, e transformar `HomeDelegate` para iniciar sessões reais ao invés de demos visuais.

---

## 2. Cenários

### Caminho feliz
1. Usuário seleciona preset na Home (índice 0–2) → Enter
2. App cria sessão: Model.start(preset) + TimerService.start(1000ms)
3. TimerView renderiza countdown em tempo real (1 tick/s)
4. Ao final de cada fase, transição automática (WORK→SHORT_BREAK→WORK→...→LONG_BREAK→COMPLETED)
5. Ao completar, App navega para CycleCompleteView

### Edge cases
- Enter durante sessão → toggle pause/resume (timer continua rodando, tick() faz noop quando paused)
- Back durante sessão → stopSession() + popView (sem confirm dialog — provisório até 02-04)
- Preset com cycles=1 → WORK → COMPLETED direto (sem breaks)
- Tick chega quando Model já está COMPLETED → noop (isRunning retorna false)

### Erros
- `getApp()` retorna `AppBase` → cast explícito `(App.getApp() as TomaApp)` em delegates
- Múltiplos requestUpdate() por segundo coalescem naturalmente — sem ação necessária

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/services/TimerService.mc` | Wrapper fino sobre Toybox.Timer.Timer. Expõe start(callback, intervalMs), stop(), isRunning(). |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/TomaApp.mc` | Adicionar singletons _model + _timerService. Métodos: getModel(), startSession(), onTimerTick(), pauseSession(), resumeSession(), stopSession(). Observer para ON_COMPLETE. |
| 2 | `source/views/TimerView.mc` | Refatorar construtor: receber PomodoroModel. onUpdate lê estado do Model. Mapear state→phase symbol internamente. |
| 3 | `source/delegates/TimerDelegate.mc` | onSelect: toggle pause/resume via App. onBack: stopSession + popView. |
| 4 | `source/delegates/HomeDelegate.mc` | Presets 0–2: startSession(preset) + pushView(TimerView(model)). Remover lógica demo (ciclo de 8 estados). |
| 5 | `tests/PomodoroModelTest.mc` | Adicionar testes: tick batch com transição rápida (1/1/2), tick durante pause é noop em batch, ciclo completo rápido com contagem de ON_COMPLETE. |

---

### 4.1 `source/services/TimerService.mc` (CRIAR)

```monkeyc
using Toybox.Timer;
using Toybox.Lang;

class TimerService {
    private var _timer as Timer.Timer;
    private var _running as Lang.Boolean = false;

    function initialize() {
        _timer = new Timer.Timer();
    }

    function start(callback as Lang.Method, intervalMs as Lang.Number) as Void {
        _timer.start(callback, intervalMs, true);
        _running = true;
    }

    function stop() as Void {
        _timer.stop();
        _running = false;
    }

    function isRunning() as Lang.Boolean {
        return _running;
    }
}
```

---

### 4.2 `source/TomaApp.mc`

**Antes:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class TomaApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }
}
```

**Depois:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _model.addObserver(method(:onModelEvent));
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }

    function getModel() as PomodoroModel {
        return _model;
    }

    function startSession(preset as Preset) as Void {
        _model.start(preset);
        _timerService.start(method(:onTimerTick), 1000);
    }

    function onTimerTick() as Void {
        if (_model.isPaused()) {
            return;
        }
        _model.tick();
        Ui.requestUpdate();
    }

    function pauseSession() as Void {
        _model.pause();
        Ui.requestUpdate();
    }

    function resumeSession() as Void {
        _model.resume();
        Ui.requestUpdate();
    }

    function stopSession() as Void {
        _model.stop();
        _timerService.stop();
    }

    function onModelEvent(event as Lang.Number) as Void {
        if (event == PomodoroEvent.ON_COMPLETE) {
            _timerService.stop();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), 0);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
    }
}
```

---

### 4.3 `source/views/TimerView.mc`

**Antes:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerView extends Ui.View {
    private var _phase as Lang.Symbol;
    private var _remaining as Lang.Number;
    private var _total as Lang.Number;
    private var _completedCycles as Lang.Number;
    private var _totalCycles as Lang.Number;
    private var _isPaused as Lang.Boolean;
    private var _pausedText as Lang.String;

    function initialize(
        phase as Lang.Symbol,
        remaining as Lang.Number,
        total as Lang.Number,
        completedCycles as Lang.Number,
        totalCycles as Lang.Number,
        isPaused as Lang.Boolean
    ) {
        View.initialize();
        _phase = phase;
        _remaining = remaining;
        _total = total;
        _completedCycles = completedCycles;
        _totalCycles = totalCycles;
        _isPaused = isPaused;
        _pausedText = Ui.loadResource(Rez.Strings.state_paused) as Lang.String;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var centerY = Dimensions.timerCenterY(bucket, h);
        var radius = Dimensions.ringRadius(bucket);
        var stroke = Dimensions.ringStroke(bucket);
        var labelOffsetY = Dimensions.phaseLabelOffsetY(bucket);
        var pOffsetY = Dimensions.pillsOffsetY(bucket);
        var pSize = Dimensions.pillSize(bucket);
        var pSpacing = Dimensions.pillSpacing(bucket);

        var ringColor = _isPaused ? getDimColor() : getPhaseColor();
        var displayColor = _isPaused ? Colors.TEXT_MUTED : Colors.TEXT_PRIMARY;
        var labelColor = _isPaused ? Colors.TEXT_MUTED : getPhaseColor();
        var phaseText = getPhaseText();
        var progress = (_total - _remaining).toFloat() / _total.toFloat();

        var labelY = centerY + labelOffsetY;
        PhaseLabel.draw(dc, centerX, labelY, phaseText, labelColor, bucket);

        TimerRing.draw(dc, centerX, centerY, radius, stroke, progress, ringColor);

        TimerDisplay.draw(dc, centerX, centerY, _remaining, bucket, displayColor);

        if (_isPaused) {
            var pausedY = centerY + Dimensions.pausedLabelOffsetY(bucket);
            var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, pausedY, font, _pausedText, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var pillsY = centerY + pOffsetY;
        SessionPills.draw(dc, centerX, pillsY, _totalCycles, _completedCycles, pSize, pSpacing);
    }

    private function getPhaseColor() as Lang.Number {
        if (_phase == :running_work) { return Colors.BRAND; }
        if (_phase == :running_short_break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

    private function getDimColor() as Lang.Number {
        if (_phase == :running_work) { return Colors.BRAND_DIM; }
        if (_phase == :running_short_break) { return Colors.TEXT_MUTED_DIM; }
        return Colors.ACCENT_DIM;
    }

    private function getPhaseText() as Lang.String {
        if (_phase == :running_work) { return "FOCUS"; }
        if (_phase == :running_short_break) { return "BREAK"; }
        return "LONG BREAK";
    }
}
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerView extends Ui.View {
    private var _model as PomodoroModel;
    private var _pausedText as Lang.String;

    function initialize(model as PomodoroModel) {
        View.initialize();
        _model = model;
        _pausedText = Ui.loadResource(Rez.Strings.state_paused) as Lang.String;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var centerY = Dimensions.timerCenterY(bucket, h);
        var radius = Dimensions.ringRadius(bucket);
        var stroke = Dimensions.ringStroke(bucket);
        var labelOffsetY = Dimensions.phaseLabelOffsetY(bucket);
        var pOffsetY = Dimensions.pillsOffsetY(bucket);
        var pSize = Dimensions.pillSize(bucket);
        var pSpacing = Dimensions.pillSpacing(bucket);

        var state = _model.getState();
        var remaining = _model.getRemainingSeconds();
        var total = _model.getTotalPhaseSeconds();
        var isPaused = _model.isPaused();
        var phase = _stateToPhase(state);

        var ringColor = isPaused ? _getDimColor(phase) : _getPhaseColor(phase);
        var displayColor = isPaused ? Colors.TEXT_MUTED : Colors.TEXT_PRIMARY;
        var labelColor = isPaused ? Colors.TEXT_MUTED : _getPhaseColor(phase);
        var phaseText = _getPhaseText(phase);
        var progress = (total > 0) ? (total - remaining).toFloat() / total.toFloat() : 0.0;

        var labelY = centerY + labelOffsetY;
        PhaseLabel.draw(dc, centerX, labelY, phaseText, labelColor, bucket);

        TimerRing.draw(dc, centerX, centerY, radius, stroke, progress, ringColor);

        TimerDisplay.draw(dc, centerX, centerY, remaining, bucket, displayColor);

        if (isPaused) {
            var pausedY = centerY + Dimensions.pausedLabelOffsetY(bucket);
            var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, pausedY, font, _pausedText, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var pillsY = centerY + pOffsetY;
        SessionPills.draw(dc, centerX, pillsY, _model.getTotalCycles(), _model.getCyclesCompleted(), pSize, pSpacing);
    }

    private function _stateToPhase(state as Lang.Number) as Lang.Symbol {
        if (state == PomodoroState.RUNNING_WORK) { return :running_work; }
        if (state == PomodoroState.RUNNING_SHORT_BREAK) { return :running_short_break; }
        if (state == PomodoroState.RUNNING_LONG_BREAK) { return :running_long_break; }
        if (state == PomodoroState.PAUSED) {
            var model = _model;
            var cycles = model.getCyclesCompleted();
            var total = model.getTotalCycles();
            if (cycles >= total) { return :running_long_break; }
            if (model.getCurrentCycle() > cycles) { return :running_work; }
            return :running_short_break;
        }
        return :running_work;
    }

    private function _getPhaseColor(phase as Lang.Symbol) as Lang.Number {
        if (phase == :running_work) { return Colors.BRAND; }
        if (phase == :running_short_break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

    private function _getDimColor(phase as Lang.Symbol) as Lang.Number {
        if (phase == :running_work) { return Colors.BRAND_DIM; }
        if (phase == :running_short_break) { return Colors.TEXT_MUTED_DIM; }
        return Colors.ACCENT_DIM;
    }

    private function _getPhaseText(phase as Lang.Symbol) as Lang.String {
        if (phase == :running_work) { return "FOCUS"; }
        if (phase == :running_short_break) { return "BREAK"; }
        return "LONG BREAK";
    }
}
```

---

### 4.4 `source/delegates/TimerDelegate.mc`

**Antes:**
```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onSelect() as Lang.Boolean {
        Sys.println("TODO: pause/resume");
        return true;
    }
}
```

**Depois:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        app.stopSession();
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        if (app.getModel().isPaused()) {
            app.resumeSession();
        } else {
            app.pauseSession();
        }
        return true;
    }
}
```

---

### 4.5 `source/delegates/HomeDelegate.mc`

**Antes:**
```monkeyc
    function onSelect() as Lang.Boolean {
        var selectedIndex = _view.getSelectedIndex();

        if (selectedIndex == 3) {
            var view = new CustomBuilderView();
            Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }

        if (selectedIndex == 4) {
            Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_LEFT);
            return true;
        }

        var idx = _demoIdx % 8;

        if (idx < 4) {
            var phases = [:running_work, :running_short_break, :running_long_break, :running_work];
            var remaining = [900, 180, 420, 900];
            var totals = [1500, 300, 600, 1500];
            var completed = [2, 2, 3, 2];
            var paused = [false, false, false, true];

            Ui.pushView(
                new TimerView(phases[idx], remaining[idx], totals[idx], completed[idx], 4, paused[idx]),
                new TimerDelegate(),
                Ui.SLIDE_LEFT
            );
        } else if (idx < 7) {
            var transPhases = [:focus, :break, :long_break];
            var sessionNums = [2, 3, 4];
            var phaseIdx = idx - 4;
            var view = new PhaseTransitionView(transPhases[phaseIdx], sessionNums[phaseIdx], 4);
            Ui.pushView(
                view,
                new PhaseTransitionDelegate(view),
                Ui.SLIDE_LEFT
            );
        } else {
            var view = new CycleCompleteView(4, 4, 8);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.pushView(view, delegate, Ui.SLIDE_LEFT);
        }

        _demoIdx++;
        return true;
    }
```

**Depois:**
```monkeyc
    function onSelect() as Lang.Boolean {
        var selectedIndex = _view.getSelectedIndex();

        if (selectedIndex == 3) {
            var view = new CustomBuilderView();
            Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }

        if (selectedIndex == 4) {
            Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_LEFT);
            return true;
        }

        var presets = Presets.builtinList();
        var preset = presets[selectedIndex] as Preset;
        var app = App.getApp() as TomaApp;
        app.startSession(preset);
        Ui.pushView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
        return true;
    }
```

Também remover o campo `_demoIdx` e o import `Toybox.System`:

**Antes (cabeçalho):**
```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class HomeDelegate extends Ui.BehaviorDelegate {
    private var _view as HomeView;
    private var _demoIdx as Lang.Number = 0;
```

**Depois (cabeçalho):**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HomeDelegate extends Ui.BehaviorDelegate {
    private var _view as HomeView;
```

---

### 4.6 `tests/PomodoroModelTest.mc`

Adicionar ao final do arquivo (antes do fechamento), após a classe `EventTracker`:

```monkeyc
(:test)
function testTickBatchFastCycle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 2, false);
    model.start(preset);
    // Cycle 1: work(60s) + short break(60s)
    for (var i = 0; i < 120; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "After cycle 1, should be in WORK again");
    Test.assertEqualMessage(2, model.getCurrentCycle(), "Should be cycle 2");
    // Cycle 2: work(60s) → long break(180s) → completed
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "After cycle 2 work, should be LONG_BREAK");
    for (var i = 0; i < 180; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "After long break, should be COMPLETED");
    return true;
}

(:test)
function testTickBatchDuringPauseIsNoop(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick(); // remaining = 1499
    model.pause();
    for (var i = 0; i < 100; i++) { model.tick(); }
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "100 ticks during pause should not change remaining");
    model.resume();
    model.tick();
    Test.assertEqualMessage(1498, model.getRemainingSeconds(), "After resume, tick should decrement again");
    return true;
}

(:test)
function testOnCompleteEventFired(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var tracker = new EventTracker();
    model.addObserver(tracker.method(:onEvent));
    var preset = new Preset(1, 1, 1, false);
    model.start(preset);
    // Single cycle: 60 ticks → COMPLETED
    for (var i = 0; i < 60; i++) { model.tick(); }
    var foundComplete = false;
    for (var i = 0; i < tracker.events.size(); i++) {
        if (tracker.events[i] == PomodoroEvent.ON_COMPLETE) {
            foundComplete = true;
        }
    }
    Test.assert(foundComplete);
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Should be COMPLETED");
    return true;
}
```

---

## 5. Storage/Properties

Nenhum. Esta task não persiste estado.

---

## 6. Checklist de execução

- [x] 1. Criar diretório `source/services/`
- [x] 2. Criar `source/services/TimerService.mc`
- [x] 3. Modificar `source/TomaApp.mc` (adicionar singletons, orquestração, observer)
- [x] 4. Modificar `source/views/TimerView.mc` (refatorar para receber Model)
- [x] 5. Modificar `source/delegates/TimerDelegate.mc` (conectar pause/resume/stop)
- [x] 6. Modificar `source/delegates/HomeDelegate.mc` (substituir demo por sessão real)
- [x] 7. Adicionar testes em `tests/PomodoroModelTest.mc`
- [x] 8. Build para todos os devices do jungle
- [ ] 9. Testar no simulador (caminho feliz: preset → countdown → transições → completed)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc` compila sem erros para todos os devices no manifest
- [x] Todos os testes unitários existentes continuam passando
- [x] Novos testes (`testTickBatchFastCycle`, `testTickBatchDuringPauseIsNoop`, `testOnCompleteEventFired`) passam

### Manual (simulador)
- [ ] Selecionar preset na Home → countdown inicia e decrementa a cada segundo
- [ ] Ring de progresso avança proporcionalmente
- [ ] Transição automática WORK→SHORT_BREAK (cor e label mudam)
- [ ] Transição automática SHORT_BREAK→WORK (volta cor BRAND + "FOCUS")
- [ ] Enter pausa (visual dim + "PAUSED") — countdown para
- [ ] Enter novamente resume (visual normal + countdown retoma)
- [ ] Back → volta pra Home (sessão parada)
- [ ] Ciclo completo (usar preset curto 1/1/1 no código temporariamente) → navega para CycleCompleteView

---

## 8. Out of scope

- PhaseTransitionView entre fases (task futura)
- Confirm dialog no Back (02-04)
- Tela de Pausa separada — P4 (02-04)
- Vibração nas transições de fase (02-03)
- Persistência de sessão / recovery de background (02-16)
- Contagem de `todaySessions` na CycleCompleteView (hardcoded 0 até task de persistência)
- Custom preset via CustomBuilderView → startSession (funcionalidade já navega para builder; integrar quando builder salvar preset)
