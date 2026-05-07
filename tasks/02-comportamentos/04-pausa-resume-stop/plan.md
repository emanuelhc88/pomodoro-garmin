# Plan — Task 02-04: Pause / Resume / Stop

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar o ciclo completo Pause/Resume/Stop: dialog de confirmação custom (ConfirmStopView) ao pressionar Back, auto-navegação para PhaseTransitionView entre fases, e ações funcionais "Start again" / "Done" no CycleCompleteView. O toggle pause/resume via Enter já funciona.

---

## 2. Cenários

### Caminho feliz
1. Usuário está em P3 (timer rodando), pressiona Back → aparece ConfirmStopView sobreposto.
2. Botão "Continue" focado por default. Pressiona Select → popView, timer continua.
3. Pressiona Down para focar "Stop", Select → `app.stopSession()` + `switchToView(HomeView)`.
4. Timer roda e fase acaba → PhaseTransitionView aparece sobre TimerView por 3s → popView automático → TimerView mostra nova fase.
5. Ciclo completo → CycleCompleteView. "Start again" reinicia com mesmo preset. "Done" volta para Home.

### Edge cases
- Back durante pause (P4): mesma lógica — pushView ConfirmStopView.
- "Start again" no CycleComplete: cria nova sessão com `_lastPreset`, switchToView para novo TimerView.
- Back no CycleCompleteView: equivalente a "Done" → switchToView HomeView.
- ON_PHASE_CHANGE emitido por `start()` (primeiro phase change da sessão): **não** exibir PhaseTransitionView.
- ON_PHASE_CHANGE para state COMPLETED: **não** exibir PhaseTransitionView (ON_COMPLETE lida).

### Erros
- `getLastPreset()` retorna null no "Start again": não deveria acontecer (preset é salvo no startSession). Safety: se null, navegar para Home.
- Stack de views inconsistente se PhaseTransition push acontece durante pause: impossível — ON_PHASE_CHANGE só emite em `_transitionPhase()` que requer `!_paused`.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/views/ConfirmStopView.mc` | Overlay visual: fundo bg, borda, título "Stop session?", 2 botões com focus (Continue/Stop) |
| 2 | `source/delegates/ConfirmStopDelegate.mc` | Input: Up/Down alterna foco, Select ativa botão, Back = Continue (popView) |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/delegates/TimerDelegate.mc` | `onBack()`: trocar stop+popView por pushView(ConfirmStopView) |
| 2 | `source/delegates/CycleCompleteDelegate.mc` | `onSelect()`: implementar "Start again" e "Done" reais; `onBack()`: switchToView HomeView |
| 3 | `source/TomaApp.mc` | (1) Campo `_lastPreset`, (2) `startSession` guarda preset, (3) `onModelEvent` ON_PHASE_CHANGE push PhaseTransitionView, (4) `getLastPreset()` |
| 4 | `source/ui/layout/Dimensions.mc` | Adicionar 7 funções de dimensão do ConfirmDialog |
| 5 | `resources/strings/strings.xml` | Adicionar 3 strings (confirm_stop_title, confirm_stop_stop, confirm_stop_continue) |

---

### 4.1 `source/delegates/TimerDelegate.mc`

**Antes:**
```monkeyc
function onBack() as Lang.Boolean {
    var app = App.getApp() as TomaApp;
    app.stopSession();
    Ui.popView(Ui.SLIDE_RIGHT);
    return true;
}
```

**Depois:**
```monkeyc
function onBack() as Lang.Boolean {
    var view = new ConfirmStopView();
    Ui.pushView(view, new ConfirmStopDelegate(view), Ui.SLIDE_UP);
    return true;
}
```

---

### 4.2 `source/delegates/CycleCompleteDelegate.mc`

**Antes:**
```monkeyc
function onSelect() as Lang.Boolean {
    if (_view != null) {
        var idx = _view.getFocusIdx();
        if (idx == 0) {
            Sys.println("Start again pressed");
        } else {
            Sys.println("Done pressed");
        }
    }
    Ui.popView(Ui.SLIDE_RIGHT);
    return true;
}

function onBack() as Lang.Boolean {
    Ui.popView(Ui.SLIDE_RIGHT);
    return true;
}
```

**Depois:**
```monkeyc
function onSelect() as Lang.Boolean {
    if (_view != null) {
        var idx = _view.getFocusIdx();
        if (idx == 0) {
            var app = App.getApp() as TomaApp;
            var preset = app.getLastPreset();
            if (preset != null) {
                app.startSession(preset);
                Ui.switchToView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
            } else {
                _navigateHome();
            }
        } else {
            _navigateHome();
        }
    }
    return true;
}

function onBack() as Lang.Boolean {
    _navigateHome();
    return true;
}

private function _navigateHome() as Void {
    var view = new HomeView();
    Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
}
```

**Imports a adicionar no topo:**
```monkeyc
using Toybox.Application as App;
```

**Import a remover:**
```monkeyc
using Toybox.System as Sys;
```

---

### 4.3 `source/TomaApp.mc`

**Antes (campos):**
```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
```

**Depois (campos):**
```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;
```

---

**Antes (startSession):**
```monkeyc
function startSession(preset as Preset) as Void {
    _model.start(preset);
    _timerService.start(method(:onTimerTick), 1000);
}
```

**Depois (startSession):**
```monkeyc
function startSession(preset as Preset) as Void {
    _lastPreset = preset;
    _skipNextPhaseChange = true;
    _model.start(preset);
    _timerService.start(method(:onTimerTick), 1000);
}
```

---

**Antes (onModelEvent):**
```monkeyc
function onModelEvent(event as Lang.Number) as Void {
    if (event == PomodoroEvent.ON_START) {
        _attentionService.alertStart();
    } else if (event == PomodoroEvent.ON_PHASE_CHANGE) {
        var state = _model.getState();
        if (state == PomodoroState.RUNNING_SHORT_BREAK || state == PomodoroState.RUNNING_LONG_BREAK) {
            _attentionService.alertEndOfWork();
        } else if (state == PomodoroState.RUNNING_WORK) {
            _attentionService.alertEndOfBreak();
        }
    } else if (event == PomodoroEvent.ON_COMPLETE) {
        _attentionService.alertCycleComplete();
        _timerService.stop();
        var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), 0);
        var delegate = new CycleCompleteDelegate();
        delegate.setView(view);
        Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
    }
}
```

**Depois (onModelEvent):**
```monkeyc
function onModelEvent(event as Lang.Number) as Void {
    if (event == PomodoroEvent.ON_START) {
        _attentionService.alertStart();
    } else if (event == PomodoroEvent.ON_PHASE_CHANGE) {
        if (_skipNextPhaseChange) {
            _skipNextPhaseChange = false;
            return;
        }
        var state = _model.getState();
        if (state == PomodoroState.COMPLETED) {
            return;
        }
        if (state == PomodoroState.RUNNING_SHORT_BREAK || state == PomodoroState.RUNNING_LONG_BREAK) {
            _attentionService.alertEndOfWork();
        } else if (state == PomodoroState.RUNNING_WORK) {
            _attentionService.alertEndOfBreak();
        }
        var phase = _stateToTransitionPhase(state);
        var view = new PhaseTransitionView(phase, _model.getCurrentCycle(), _model.getTotalCycles());
        Ui.pushView(view, new PhaseTransitionDelegate(), Ui.SLIDE_LEFT);
    } else if (event == PomodoroEvent.ON_COMPLETE) {
        _attentionService.alertCycleComplete();
        _timerService.stop();
        var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), 0);
        var delegate = new CycleCompleteDelegate();
        delegate.setView(view);
        Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
    }
}

private function _stateToTransitionPhase(state as Lang.Number) as Lang.Symbol {
    if (state == PomodoroState.RUNNING_WORK) { return :focus; }
    if (state == PomodoroState.RUNNING_SHORT_BREAK) { return :break; }
    return :long_break;
}

function getLastPreset() as Preset or Null {
    return _lastPreset;
}
```

---

### 4.4 `source/ui/layout/Dimensions.mc`

**Adicionar ao final do module (antes do `}` final):**
```monkeyc
function confirmDialogWidth(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 160; }
    if (bucket == :large) { return 280; }
    return 200;
}

function confirmDialogHeight(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 110; }
    if (bucket == :large) { return 180; }
    return 130;
}

function confirmTitleY(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 15; }
    if (bucket == :large) { return 30; }
    return 20;
}

function confirmButton1Y(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 50; }
    if (bucket == :large) { return 85; }
    return 60;
}

function confirmButton2Y(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 76; }
    if (bucket == :large) { return 130; }
    return 92;
}

function confirmButtonWidth(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 120; }
    if (bucket == :large) { return 210; }
    return 150;
}

function confirmButtonHeight(bucket as Lang.Symbol) as Lang.Number {
    if (bucket == :small) { return 22; }
    if (bucket == :large) { return 38; }
    return 26;
}
```

---

### 4.5 `resources/strings/strings.xml`

**Antes (final do arquivo):**
```xml
    <string id="about_credits">Made with focus</string>
</resources>
```

**Depois:**
```xml
    <string id="about_credits">Made with focus</string>
    <string id="confirm_stop_title">Stop session?</string>
    <string id="confirm_stop_stop">Stop</string>
    <string id="confirm_stop_continue">Continue</string>
</resources>
```

---

## 5. Arquivos a CRIAR — Código completo

### 5.1 `source/views/ConfirmStopView.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class ConfirmStopView extends Ui.View {
    private var _focusIdx as Lang.Number = 0;
    private var _titleText as Lang.String;
    private var _stopText as Lang.String;
    private var _continueText as Lang.String;

    function initialize() {
        View.initialize();
        _titleText = Ui.loadResource(Rez.Strings.confirm_stop_title) as Lang.String;
        _stopText = Ui.loadResource(Rez.Strings.confirm_stop_stop) as Lang.String;
        _continueText = Ui.loadResource(Rez.Strings.confirm_stop_continue) as Lang.String;
    }

    function setFocusIdx(idx as Lang.Number) as Void {
        _focusIdx = idx;
        Ui.requestUpdate();
    }

    function getFocusIdx() as Lang.Number {
        return _focusIdx;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var dlgW = Dimensions.confirmDialogWidth(bucket);
        var dlgH = Dimensions.confirmDialogHeight(bucket);
        var dlgX = centerX - dlgW / 2;
        var dlgY = h / 2 - dlgH / 2;
        var radius = Dimensions.cardRadius(bucket);
        var border = Dimensions.cardBorder(bucket);

        dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dlgX, dlgY, dlgW, dlgH, radius);
        dc.setColor(Colors.BG, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dlgX + border, dlgY + border, dlgW - border * 2, dlgH - border * 2, radius);

        var titleY = dlgY + Dimensions.confirmTitleY(bucket);
        var titleFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, titleFont, _titleText, Gfx.TEXT_JUSTIFY_CENTER);

        var btnW = Dimensions.confirmButtonWidth(bucket);
        var btnH = Dimensions.confirmButtonHeight(bucket);
        var btnX = centerX - btnW / 2;

        var btn1Y = dlgY + Dimensions.confirmButton1Y(bucket);
        PrimaryButton.draw(dc, btnX, btn1Y, btnW, btnH, _continueText, _focusIdx == 0, bucket);

        var btn2Y = dlgY + Dimensions.confirmButton2Y(bucket);
        PrimaryButton.draw(dc, btnX, btn2Y, btnW, btnH, _stopText, _focusIdx == 1, bucket);
    }
}
```

---

### 5.2 `source/delegates/ConfirmStopDelegate.mc`

```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class ConfirmStopDelegate extends Ui.BehaviorDelegate {
    private var _view as ConfirmStopView;

    function initialize(view as ConfirmStopView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.setFocusIdx(0);
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.setFocusIdx(1);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var idx = _view.getFocusIdx();
        if (idx == 0) {
            Ui.popView(Ui.SLIDE_DOWN);
        } else {
            var app = App.getApp() as TomaApp;
            app.stopSession();
            var view = new HomeView();
            Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_DOWN);
        return true;
    }
}
```

---

## 5. Storage/Properties

Nenhum. Não há persistência nesta task.

---

## 6. Checklist de execução

- [x] 1. Criar `source/views/ConfirmStopView.mc`
- [x] 2. Criar `source/delegates/ConfirmStopDelegate.mc`
- [x] 3. Modificar `resources/strings/strings.xml` (adicionar 3 strings)
- [x] 4. Modificar `source/ui/layout/Dimensions.mc` (adicionar 7 funções)
- [x] 5. Modificar `source/delegates/TimerDelegate.mc` (onBack → pushView ConfirmStopView)
- [x] 6. Modificar `source/TomaApp.mc` (campo _lastPreset, _skipNextPhaseChange, startSession guarda preset, onModelEvent push PhaseTransitionView, getLastPreset, _stateToTransitionPhase)
- [x] 7. Modificar `source/delegates/CycleCompleteDelegate.mc` (onSelect funcional, onBack → Home, remover Sys import)
- [x] 8. Build para fr255
- [x] 9. Build para fr255s
- [x] 10. Build para fr265

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros

### Manual (simulador)
- [ ] Timer rodando → Back → ConfirmStopView aparece com "Continue" focado
- [ ] ConfirmStop → Select em "Continue" → dialog fecha, timer continua
- [ ] ConfirmStop → Down → "Stop" focado → Select → volta para Home, timer parado
- [ ] ConfirmStop → Back → dialog fecha (equivale a Continue)
- [ ] Timer paused → Back → ConfirmStopView aparece (mesmo comportamento)
- [ ] Fase work acaba → PhaseTransitionView aparece com fase correta → 3s → popView → TimerView mostra nova fase
- [ ] Ciclo completo → CycleCompleteView → "Start again" → nova sessão começa com mesmo preset
- [ ] CycleCompleteView → "Done" → volta para Home
- [ ] CycleCompleteView → Back → volta para Home
- [ ] Iniciar sessão NÃO mostra PhaseTransitionView (skip do primeiro ON_PHASE_CHANGE)

---

## 8. Out of scope
- Parar/reiniciar TimerService durante pause (decisão D1: manter rodando).
- ActivityService.pause()/resume()/discard() — será implementado em task futura (B11).
- Persistência de estado para recovery (B16) — task futura.
- Contagem diária de sessões no CycleCompleteView (parâmetro `todaySessions` hardcoded em 0) — task futura (B9).
- Touch delegates (`:hasTouch`) — task futura.
