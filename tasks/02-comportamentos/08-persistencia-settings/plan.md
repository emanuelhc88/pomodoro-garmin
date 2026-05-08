# Plan — Task 02-08: Persistência de Settings + Recovery

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Substituir o módulo `SettingsState` in-memory pelo `SettingsRepository` (leitura/escrita em `Application.Properties`), criar o sistema de recovery que persiste o estado do timer a cada 5s em `Application.Storage` e oferece diálogo "Resume session?" ao reabrir, e persistir os valores do custom preset em Properties.

---

## 2. Cenários

### Caminho feliz

1. **Settings persistentes:** Usuário abre Settings, altera toggle de vibração → fecha app → reabre → toggle mantém valor alterado.
2. **Custom preset persistente:** Usuário edita Custom Builder (work=50, break=10, cycles=3) → confirma → fecha app → reabre → Custom preset mostra 50/10/3.
3. **Recovery — resume:** Usuário está em RUNNING_WORK (remaining 20min) → app é killed → reabre 5min depois → diálogo "Resume session? Remaining: 15:00" → tap Resume → timer retoma em ~15:00.
4. **Recovery — discard:** Mesmo cenário mas tap Discard → vai para HomeView, Storage limpo.
5. **lastSelectedPreset:** Usuário seleciona preset index 2 → inicia sessão → fecha → reabre → Home abre com preset 2 selecionado.

### Edge cases

- **Primeira execução:** `Properties.getValue` retorna null → todos os getters retornam default hardcoded.
- **Recovery com remaining < 60s:** estado descartado automaticamente, usuário vai direto para Home.
- **Recovery com remaining <= 0:** timer expirou enquanto app estava morto → descarta, mostra Home.
- **Recovery com dados corrompidos:** Storage dict sem keys esperadas → descarta silenciosamente.
- **Custom preset nunca editado:** Properties retornam defaults (25/5/4).

### Erros

- `Properties.setValue` pode falhar silenciosamente em edge cases de memória — aceitar risco V1 (não há mecanismo de retry).
- `Storage.setValue` com Dictionary muito grande — mitigado por serializar apenas primitivos.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/repositories/SettingsRepository.mc` | Read/write todas as settings via Properties. Centraliza keys e defaults. |
| 2 | `source/services/RecoveryService.mc` | checkOnStart, persistThrottled, clear. Serializa/deserializa estado do model. |
| 3 | `source/model/RecoveryState.mc` | Tipo de dados que representa o estado recuperável. |
| 4 | `source/views/RecoveryView.mc` | Diálogo C14: título, subtitle (remaining), 2 botões. |
| 5 | `source/delegates/RecoveryDelegate.mc` | Input do RecoveryView: Resume → hydrate; Discard → clear. |
| 6 | `resources/settings/properties.xml` | Declarar defaults de todas as Properties keys. |
| 7 | `tests/SettingsRepositoryTest.mc` | Testes de get defaults, set/get round-trip. |
| 8 | `tests/RecoveryServiceTest.mc` | Testes de check empty, check valid, check expired, throttle. |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/model/Preset.mc` | Adicionar `toDict()` e `fromDict()` |
| 2 | `source/model/SettingsState.mc` | **REMOVER** completamente |
| 3 | `source/TomaApp.mc` | Adicionar `_settingsRepo`, `_recoveryService`. Lógica de recovery em `getInitialView`. Persist throttled no `onTimerTick`. Clear no `onModelEvent`. |
| 4 | `source/services/AttentionService.mc` | Trocar `SettingsState.*` por `SettingsRepository.get*()` |
| 5 | `source/views/SettingsMenu.mc` | Ler iniciais de `SettingsRepository` em vez de `SettingsState` |
| 6 | `source/delegates/SettingsMenuDelegate.mc` | Escrever via `SettingsRepository.set*()` |
| 7 | `source/delegates/LanguageMenuDelegate.mc` | Escrever via `SettingsRepository.setLanguage()` |
| 8 | `source/delegates/HomeDelegate.mc` | Persistir `lastSelectedPreset` ao iniciar sessão |
| 9 | `source/views/HomeView.mc` | Ler `lastSelectedPreset` no initialize para selecionar default |
| 10 | `source/delegates/CustomBuilderDelegate.mc` | Persistir custom values em Properties ao confirmar |
| 11 | `source/views/CustomBuilderView.mc` | Receber valores iniciais de Properties no constructor |
| 12 | `source/ui/layout/Dimensions.mc` | Adicionar `confirmSubtitleY` |
| 13 | `resources/strings/strings.xml` | Adicionar 4 strings de recovery |

---

### 4.1 `source/repositories/SettingsRepository.mc` (CRIAR)

```monkeyc
using Toybox.Application as App;
using Toybox.Lang;

class SettingsRepository {
    function getSoundEnabled() as Lang.Boolean {
        var v = App.Properties.getValue("soundEnabled");
        return (v != null) ? (v as Lang.Boolean) : false;
    }

    function setSoundEnabled(value as Lang.Boolean) as Void {
        App.Properties.setValue("soundEnabled", value);
    }

    function getVibrationEnabled() as Lang.Boolean {
        var v = App.Properties.getValue("vibrationEnabled");
        return (v != null) ? (v as Lang.Boolean) : true;
    }

    function setVibrationEnabled(value as Lang.Boolean) as Void {
        App.Properties.setValue("vibrationEnabled", value);
    }

    function getBacklightOnAlert() as Lang.Boolean {
        var v = App.Properties.getValue("backlightOnAlert");
        return (v != null) ? (v as Lang.Boolean) : true;
    }

    function setBacklightOnAlert(value as Lang.Boolean) as Void {
        App.Properties.setValue("backlightOnAlert", value);
    }

    function getRecordAsActivity() as Lang.Boolean {
        var v = App.Properties.getValue("recordAsActivity");
        return (v != null) ? (v as Lang.Boolean) : true;
    }

    function setRecordAsActivity(value as Lang.Boolean) as Void {
        App.Properties.setValue("recordAsActivity", value);
    }

    function getLanguage() as Lang.String {
        var v = App.Properties.getValue("language");
        return (v != null && v instanceof Lang.String) ? (v as Lang.String) : "auto";
    }

    function setLanguage(value as Lang.String) as Void {
        App.Properties.setValue("language", value);
    }

    function getLastSelectedPreset() as Lang.Number {
        var v = App.Properties.getValue("lastSelectedPreset");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 0;
    }

    function setLastSelectedPreset(value as Lang.Number) as Void {
        App.Properties.setValue("lastSelectedPreset", value);
    }

    function getCustomWorkMin() as Lang.Number {
        var v = App.Properties.getValue("customWorkMin");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 25;
    }

    function setCustomWorkMin(value as Lang.Number) as Void {
        App.Properties.setValue("customWorkMin", value);
    }

    function getCustomBreakMin() as Lang.Number {
        var v = App.Properties.getValue("customBreakMin");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 5;
    }

    function setCustomBreakMin(value as Lang.Number) as Void {
        App.Properties.setValue("customBreakMin", value);
    }

    function getCustomCycles() as Lang.Number {
        var v = App.Properties.getValue("customCycles");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 4;
    }

    function setCustomCycles(value as Lang.Number) as Void {
        App.Properties.setValue("customCycles", value);
    }
}
```

---

### 4.2 `source/model/RecoveryState.mc` (CRIAR)

```monkeyc
using Toybox.Lang;

class RecoveryState {
    var preset as Preset;
    var state as Lang.Number;
    var remainingSeconds as Lang.Number;
    var cyclesCompleted as Lang.Number;
    var currentCycle as Lang.Number;

    function initialize(preset as Preset, state as Lang.Number, remainingSeconds as Lang.Number, cyclesCompleted as Lang.Number, currentCycle as Lang.Number) {
        self.preset = preset;
        self.state = state;
        self.remainingSeconds = remainingSeconds;
        self.cyclesCompleted = cyclesCompleted;
        self.currentCycle = currentCycle;
    }
}
```

---

### 4.3 `source/services/RecoveryService.mc` (CRIAR)

```monkeyc
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Lang;

class RecoveryService {
    private const STORAGE_KEY = "activeSession";
    private const MIN_RESUME_SECONDS = 60;
    private const THROTTLE_SECONDS = 5;
    private var _lastSavedAt as Lang.Number = 0;

    function checkOnStart() as RecoveryState or Null {
        var saved = App.Storage.getValue(STORAGE_KEY);
        if (saved == null || !(saved instanceof Lang.Dictionary)) {
            return null;
        }
        var dict = saved as Lang.Dictionary;

        if (!dict.hasKey("savedAt") || !dict.hasKey("remaining") ||
            !dict.hasKey("state") || !dict.hasKey("cyclesCompleted") ||
            !dict.hasKey("currentCycle") || !dict.hasKey("workMin") ||
            !dict.hasKey("breakMin") || !dict.hasKey("cycles") ||
            !dict.hasKey("isCustom")) {
            clear();
            return null;
        }

        var savedAt = dict["savedAt"] as Lang.Number;
        var remaining = dict["remaining"] as Lang.Number;
        var elapsed = Time.now().value() - savedAt;
        var newRemaining = remaining - elapsed;

        if (newRemaining < MIN_RESUME_SECONDS) {
            clear();
            return null;
        }

        var preset = new Preset(
            dict["workMin"] as Lang.Number,
            dict["breakMin"] as Lang.Number,
            dict["cycles"] as Lang.Number,
            dict["isCustom"] as Lang.Boolean
        );

        return new RecoveryState(
            preset,
            dict["state"] as Lang.Number,
            newRemaining,
            dict["cyclesCompleted"] as Lang.Number,
            dict["currentCycle"] as Lang.Number
        );
    }

    function persistThrottled(model as PomodoroModel) as Void {
        var now = Time.now().value();
        if (now - _lastSavedAt < THROTTLE_SECONDS) {
            return;
        }
        _lastSavedAt = now;

        var preset = model.getPreset();
        if (preset == null) {
            return;
        }
        var p = preset as Preset;

        var dict = {
            "savedAt" => now,
            "remaining" => model.getRemainingSeconds(),
            "state" => model.getState(),
            "cyclesCompleted" => model.getCyclesCompleted(),
            "currentCycle" => model.getCurrentCycle(),
            "workMin" => p.workMin,
            "breakMin" => p.breakMin,
            "cycles" => p.cycles,
            "isCustom" => p.isCustom
        };
        App.Storage.setValue(STORAGE_KEY, dict);
    }

    function clear() as Void {
        App.Storage.deleteValue(STORAGE_KEY);
        _lastSavedAt = 0;
    }
}
```

---

### 4.4 `source/views/RecoveryView.mc` (CRIAR)

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class RecoveryView extends Ui.View {
    private var _focusIdx as Lang.Number = 0;
    private var _titleText as Lang.String;
    private var _resumeText as Lang.String;
    private var _discardText as Lang.String;
    private var _remainingFormatted as Lang.String;

    function initialize(remainingSeconds as Lang.Number) {
        View.initialize();
        _titleText = Ui.loadResource(Rez.Strings.recovery_title) as Lang.String;
        _resumeText = Ui.loadResource(Rez.Strings.recovery_resume) as Lang.String;
        _discardText = Ui.loadResource(Rez.Strings.recovery_discard) as Lang.String;

        var mins = remainingSeconds / 60;
        var secs = remainingSeconds % 60;
        var timeStr = Lang.format("$1$:$2$", [mins.format("%02d"), secs.format("%02d")]);
        var pattern = Ui.loadResource(Rez.Strings.recovery_remaining) as Lang.String;
        _remainingFormatted = Lang.format(pattern, [timeStr]);
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

        var subtitleY = dlgY + Dimensions.confirmSubtitleY(bucket);
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, subtitleY, Gfx.FONT_TINY, _remainingFormatted, Gfx.TEXT_JUSTIFY_CENTER);

        var btnW = Dimensions.confirmButtonWidth(bucket);
        var btnH = Dimensions.confirmButtonHeight(bucket);
        var btnX = centerX - btnW / 2;

        var btn1Y = dlgY + Dimensions.confirmButton1Y(bucket);
        PrimaryButton.draw(dc, btnX, btn1Y, btnW, btnH, _resumeText, _focusIdx == 0, bucket);

        var btn2Y = dlgY + Dimensions.confirmButton2Y(bucket);
        PrimaryButton.draw(dc, btnX, btn2Y, btnW, btnH, _discardText, _focusIdx == 1, bucket);
    }
}
```

---

### 4.5 `source/delegates/RecoveryDelegate.mc` (CRIAR)

```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class RecoveryDelegate extends Ui.BehaviorDelegate {
    private var _view as RecoveryView;
    private var _recoveryState as RecoveryState;

    function initialize(view as RecoveryView, recoveryState as RecoveryState) {
        BehaviorDelegate.initialize();
        _view = view;
        _recoveryState = recoveryState;
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
        var app = App.getApp() as TomaApp;

        if (idx == 0) {
            app.resumeFromRecovery(_recoveryState);
            var model = app.getModel();
            Ui.switchToView(new TimerView(model), new TimerDelegate(), Ui.SLIDE_LEFT);
        } else {
            app.getRecoveryService().clear();
            var view = new HomeView();
            Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        app.getRecoveryService().clear();
        var view = new HomeView();
        Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
        return true;
    }
}
```

---

### 4.6 `resources/settings/properties.xml` (CRIAR)

```xml
<resources>
    <properties>
        <property id="soundEnabled" type="boolean">false</property>
        <property id="vibrationEnabled" type="boolean">true</property>
        <property id="backlightOnAlert" type="boolean">true</property>
        <property id="recordAsActivity" type="boolean">true</property>
        <property id="language" type="string">auto</property>
        <property id="lastSelectedPreset" type="number">0</property>
        <property id="customWorkMin" type="number">25</property>
        <property id="customBreakMin" type="number">5</property>
        <property id="customCycles" type="number">4</property>
    </properties>
</resources>
```

---

### 4.7 `source/model/Preset.mc`

**Antes:**
```monkeyc
    function getLongBreakSeconds() as Lang.Number {
        return breakMin * 60 * 3;
    }
}
```

**Depois:**
```monkeyc
    function getLongBreakSeconds() as Lang.Number {
        return breakMin * 60 * 3;
    }

    function toDict() as Lang.Dictionary {
        return {
            "workMin" => workMin,
            "breakMin" => breakMin,
            "cycles" => cycles,
            "isCustom" => isCustom
        };
    }

    static function fromDict(dict as Lang.Dictionary) as Preset {
        return new Preset(
            dict["workMin"] as Lang.Number,
            dict["breakMin"] as Lang.Number,
            dict["cycles"] as Lang.Number,
            dict["isCustom"] as Lang.Boolean
        );
    }
}
```

---

### 4.8 `source/model/SettingsState.mc`

**Ação: REMOVER este arquivo completamente.**

---

### 4.9 `source/TomaApp.mc`

**Antes:**
```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
    private var _counterRepo as CounterRepository;
    private var _lastPreset as Preset or Null;
    private var _customPreset as Preset or Null = null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _attentionService = new AttentionService();
        _counterRepo = new CounterRepository();
        _model.addObserver(method(:onModelEvent));
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }
```

**Depois:**
```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
    private var _counterRepo as CounterRepository;
    private var _settingsRepo as SettingsRepository;
    private var _recoveryService as RecoveryService;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _attentionService = new AttentionService();
        _counterRepo = new CounterRepository();
        _settingsRepo = new SettingsRepository();
        _recoveryService = new RecoveryService();
        _model.addObserver(method(:onModelEvent));
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var recovery = _recoveryService.checkOnStart();
        if (recovery != null) {
            var rs = recovery as RecoveryState;
            var view = new RecoveryView(rs.remainingSeconds);
            var delegate = new RecoveryDelegate(view, rs);
            return [view, delegate];
        }
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }
```

**Antes (onTimerTick):**
```monkeyc
    function onTimerTick() as Void {
        if (_model.isPaused()) {
            return;
        }
        _model.tick();
        Ui.requestUpdate();
    }
```

**Depois (onTimerTick):**
```monkeyc
    function onTimerTick() as Void {
        if (_model.isPaused()) {
            return;
        }
        _model.tick();
        _recoveryService.persistThrottled(_model);
        Ui.requestUpdate();
    }
```

**Antes (stopSession):**
```monkeyc
    function stopSession() as Void {
        _model.stop();
        _timerService.stop();
    }
```

**Depois (stopSession):**
```monkeyc
    function stopSession() as Void {
        _model.stop();
        _timerService.stop();
        _recoveryService.clear();
    }
```

**Antes (onModelEvent — ON_COMPLETE block):**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            var todaySessions = _counterRepo.getTodayCount();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), todaySessions);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
```

**Depois (onModelEvent — ON_COMPLETE block):**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            _recoveryService.clear();
            var todaySessions = _counterRepo.getTodayCount();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), todaySessions);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
```

**Remover (getCustomPreset e setCustomPreset):**
```monkeyc
    function getCustomPreset() as Preset or Null {
        return _customPreset;
    }

    function setCustomPreset(preset as Preset) as Void {
        _customPreset = preset;
    }
```

**Adicionar (novos métodos públicos):**
```monkeyc
    function getSettingsRepo() as SettingsRepository {
        return _settingsRepo;
    }

    function getRecoveryService() as RecoveryService {
        return _recoveryService;
    }

    function resumeFromRecovery(recovery as RecoveryState) as Void {
        _skipNextPhaseChange = true;
        _model.hydrate(recovery.preset, recovery.state, recovery.remainingSeconds, recovery.cyclesCompleted, recovery.currentCycle);
        _timerService.start(method(:onTimerTick), 1000);
    }
```

---

### 4.10 `source/model/PomodoroModel.mc`

**Adicionar método `hydrate` (após `stop()`):**

**Depois de:**
```monkeyc
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
```

**Inserir:**
```monkeyc
    function hydrate(preset as Preset, state as Lang.Number, remainingSeconds as Lang.Number, cyclesCompleted as Lang.Number, currentCycle as Lang.Number) as Void {
        _preset = preset;
        _state = state;
        _remainingSeconds = remainingSeconds;
        _cyclesCompleted = cyclesCompleted;
        _currentCycle = currentCycle;
        _paused = false;
        if (state == PomodoroState.RUNNING_WORK) {
            _totalPhaseSeconds = preset.workMin * 60;
        } else if (state == PomodoroState.RUNNING_SHORT_BREAK) {
            _totalPhaseSeconds = preset.breakMin * 60;
        } else if (state == PomodoroState.RUNNING_LONG_BREAK) {
            _totalPhaseSeconds = preset.getLongBreakSeconds();
        } else {
            _totalPhaseSeconds = remainingSeconds;
        }
        _emit(PomodoroEvent.ON_START);
        _emit(PomodoroEvent.ON_PHASE_CHANGE);
    }
```

---

### 4.11 `source/services/AttentionService.mc`

**Antes:**
```monkeyc
class AttentionService {
    function initialize() {
    }
```

**Depois:**
```monkeyc
class AttentionService {
    private var _settingsRepo as SettingsRepository;

    function initialize(settingsRepo as SettingsRepository) {
        _settingsRepo = settingsRepo;
    }
```

**Antes (_vibrate):**
```monkeyc
    private function _vibrate(profile as Lang.Array<Attention.VibeProfile>) as Void {
        if (!SettingsState.vibrationEnabled) {
            return;
        }
```

**Depois (_vibrate):**
```monkeyc
    private function _vibrate(profile as Lang.Array<Attention.VibeProfile>) as Void {
        if (!_settingsRepo.getVibrationEnabled()) {
            return;
        }
```

**Antes (_playTone):**
```monkeyc
    private function _playTone() as Void {
        if (!SettingsState.soundEnabled) {
            return;
        }
```

**Depois (_playTone):**
```monkeyc
    private function _playTone() as Void {
        if (!_settingsRepo.getSoundEnabled()) {
            return;
        }
```

**Antes (_flashBacklight):**
```monkeyc
    private function _flashBacklight() as Void {
        if (!SettingsState.backlightOnAlert) {
            return;
        }
```

**Depois (_flashBacklight):**
```monkeyc
    private function _flashBacklight() as Void {
        if (!_settingsRepo.getBacklightOnAlert()) {
            return;
        }
```

---

### 4.12 `source/views/SettingsMenu.mc`

**Antes:**
```monkeyc
class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});

        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound) as Lang.String,
            null,
            :soundEnabled,
            SettingsState.soundEnabled,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration) as Lang.String,
            null,
            :vibrationEnabled,
            SettingsState.vibrationEnabled,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_backlight) as Lang.String,
            null,
            :backlightOnAlert,
            SettingsState.backlightOnAlert,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_record_activity) as Lang.String,
            null,
            :recordAsActivity,
            SettingsState.recordAsActivity,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language) as Lang.String,
            getLanguageSubLabel(),
            :language,
            null
        ));
```

**Depois:**
```monkeyc
class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});

        var app = App.getApp() as TomaApp;
        var repo = app.getSettingsRepo();

        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound) as Lang.String,
            null,
            :soundEnabled,
            repo.getSoundEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration) as Lang.String,
            null,
            :vibrationEnabled,
            repo.getVibrationEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_backlight) as Lang.String,
            null,
            :backlightOnAlert,
            repo.getBacklightOnAlert(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_record_activity) as Lang.String,
            null,
            :recordAsActivity,
            repo.getRecordAsActivity(),
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language) as Lang.String,
            getLanguageSubLabel(repo),
            :language,
            null
        ));
```

**Antes (getLanguageSubLabel):**
```monkeyc
    function getLanguageSubLabel() as Lang.String {
        if (SettingsState.language.equals("en")) {
            return Ui.loadResource(Rez.Strings.language_en) as Lang.String;
        }
        if (SettingsState.language.equals("pt")) {
            return Ui.loadResource(Rez.Strings.language_pt) as Lang.String;
        }
        return Ui.loadResource(Rez.Strings.language_auto) as Lang.String;
    }
```

**Depois (getLanguageSubLabel):**
```monkeyc
    function getLanguageSubLabel(repo as SettingsRepository) as Lang.String {
        var lang = repo.getLanguage();
        if (lang.equals("en")) {
            return Ui.loadResource(Rez.Strings.language_en) as Lang.String;
        }
        if (lang.equals("pt")) {
            return Ui.loadResource(Rez.Strings.language_pt) as Lang.String;
        }
        return Ui.loadResource(Rez.Strings.language_auto) as Lang.String;
    }
```

**Adicionar import no topo:**
```monkeyc
using Toybox.Application as App;
```

---

### 4.13 `source/delegates/SettingsMenuDelegate.mc`

**Antes:**
```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (item instanceof Ui.ToggleMenuItem) {
            var toggle = item as Ui.ToggleMenuItem;
            if (id == :soundEnabled) {
                SettingsState.soundEnabled = toggle.isEnabled();
            } else if (id == :vibrationEnabled) {
                SettingsState.vibrationEnabled = toggle.isEnabled();
            } else if (id == :backlightOnAlert) {
                SettingsState.backlightOnAlert = toggle.isEnabled();
            } else if (id == :recordAsActivity) {
                SettingsState.recordAsActivity = toggle.isEnabled();
            }
            return;
        }
```

**Depois:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (item instanceof Ui.ToggleMenuItem) {
            var toggle = item as Ui.ToggleMenuItem;
            var app = App.getApp() as TomaApp;
            var repo = app.getSettingsRepo();
            if (id == :soundEnabled) {
                repo.setSoundEnabled(toggle.isEnabled());
            } else if (id == :vibrationEnabled) {
                repo.setVibrationEnabled(toggle.isEnabled());
            } else if (id == :backlightOnAlert) {
                repo.setBacklightOnAlert(toggle.isEnabled());
            } else if (id == :recordAsActivity) {
                repo.setRecordAsActivity(toggle.isEnabled());
            }
            return;
        }
```

---

### 4.14 `source/delegates/LanguageMenuDelegate.mc`

**Antes:**
```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (id == :auto) {
            SettingsState.language = "auto";
        } else if (id == :en) {
            SettingsState.language = "en";
        } else if (id == :pt) {
            SettingsState.language = "pt";
        }

        Ui.popView(Ui.SLIDE_RIGHT);
    }
}
```

**Depois:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();
        var app = App.getApp() as TomaApp;
        var repo = app.getSettingsRepo();

        if (id == :auto) {
            repo.setLanguage("auto");
        } else if (id == :en) {
            repo.setLanguage("en");
        } else if (id == :pt) {
            repo.setLanguage("pt");
        }

        Ui.popView(Ui.SLIDE_RIGHT);
    }
}
```

---

### 4.15 `source/delegates/HomeDelegate.mc`

**Antes (onSelect — bloco de preset index 0-2):**
```monkeyc
        var presets = Presets.builtinList();
        var preset = presets[selectedIndex] as Preset;
        var app = App.getApp() as TomaApp;
        app.startSession(preset);
        Ui.pushView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
        return true;
    }
```

**Depois:**
```monkeyc
        var presets = Presets.builtinList();
        var preset = presets[selectedIndex] as Preset;
        var app = App.getApp() as TomaApp;
        app.getSettingsRepo().setLastSelectedPreset(selectedIndex);
        app.startSession(preset);
        Ui.pushView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
        return true;
    }
```

**Antes (onSelect — bloco de preset index 3 / custom):**
```monkeyc
        if (selectedIndex == 3) {
            var app = App.getApp() as TomaApp;
            var customPreset = app.getCustomPreset();
            if (customPreset != null) {
                app.startSession(customPreset);
                Ui.pushView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
            } else {
                var view = new CustomBuilderView();
                Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            }
            return true;
        }
```

**Depois:**
```monkeyc
        if (selectedIndex == 3) {
            var app = App.getApp() as TomaApp;
            var repo = app.getSettingsRepo();
            var customPreset = new Preset(repo.getCustomWorkMin(), repo.getCustomBreakMin(), repo.getCustomCycles(), true);
            var view = new CustomBuilderView(customPreset.workMin, customPreset.breakMin, customPreset.cycles);
            Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }
```

---

### 4.16 `source/views/HomeView.mc`

**Antes (initialize):**
```monkeyc
    function initialize() {
        View.initialize();
        _presets = Presets.builtinList();
        _cyclesLabel = Ui.loadResource(Rez.Strings.unit_cycles) as Lang.String;
        _customLabel = Ui.loadResource(Rez.Strings.preset_custom_label) as Lang.String;
        _settingsLabel = Ui.loadResource(Rez.Strings.settings_label) as Lang.String;
    }
```

**Depois (initialize):**
```monkeyc
    function initialize() {
        View.initialize();
        _presets = Presets.builtinList();
        _cyclesLabel = Ui.loadResource(Rez.Strings.unit_cycles) as Lang.String;
        _customLabel = Ui.loadResource(Rez.Strings.preset_custom_label) as Lang.String;
        _settingsLabel = Ui.loadResource(Rez.Strings.settings_label) as Lang.String;
        var app = App.getApp() as TomaApp;
        var savedIdx = app.getSettingsRepo().getLastSelectedPreset();
        if (savedIdx >= 0 && savedIdx < _totalItems) {
            _selectedIndex = savedIdx;
        }
    }
```

**Adicionar import no topo:**
```monkeyc
using Toybox.Application as App;
```

---

### 4.17 `source/delegates/CustomBuilderDelegate.mc`

**Antes (onBack — else branch):**
```monkeyc
    function onBack() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.cancelEdit();
        } else {
            var app = App.getApp() as TomaApp;
            app.setCustomPreset(_view.buildPreset());
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
```

**Depois:**
```monkeyc
    function onBack() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.cancelEdit();
        } else {
            var app = App.getApp() as TomaApp;
            var preset = _view.buildPreset();
            var repo = app.getSettingsRepo();
            repo.setCustomWorkMin(preset.workMin);
            repo.setCustomBreakMin(preset.breakMin);
            repo.setCustomCycles(preset.cycles);
            repo.setLastSelectedPreset(3);
            app.startSession(preset);
            Ui.switchToView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
        }
        return true;
    }
```

---

### 4.18 `source/views/CustomBuilderView.mc`

**Antes (constructor):**
```monkeyc
class CustomBuilderView extends Ui.View {
    private var _selectedLine as Lang.Number = 0;
    private var _editing as Lang.Boolean = false;
    private var _workMin as Lang.Number = 25;
    private var _breakMin as Lang.Number = 5;
    private var _cycles as Lang.Number = 4;
    private var _editStartValue as Lang.Number = 0;

    private var _titleStr as Lang.String;
    private var _labelWork as Lang.String;
    private var _labelBreak as Lang.String;
    private var _labelCycles as Lang.String;
    private var _unitMin as Lang.String;
    private var _hintsNav as Lang.String;
    private var _hintsEdit as Lang.String;

    function initialize() {
        View.initialize();
```

**Depois:**
```monkeyc
class CustomBuilderView extends Ui.View {
    private var _selectedLine as Lang.Number = 0;
    private var _editing as Lang.Boolean = false;
    private var _workMin as Lang.Number;
    private var _breakMin as Lang.Number;
    private var _cycles as Lang.Number;
    private var _editStartValue as Lang.Number = 0;

    private var _titleStr as Lang.String;
    private var _labelWork as Lang.String;
    private var _labelBreak as Lang.String;
    private var _labelCycles as Lang.String;
    private var _unitMin as Lang.String;
    private var _hintsNav as Lang.String;
    private var _hintsEdit as Lang.String;

    function initialize(workMin as Lang.Number, breakMin as Lang.Number, cycles as Lang.Number) {
        View.initialize();
        _workMin = workMin;
        _breakMin = breakMin;
        _cycles = cycles;
```

---

### 4.19 `source/ui/layout/Dimensions.mc`

**Adicionar após `confirmTitleY`:**

**Antes:**
```monkeyc
    function confirmTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 15; }
        if (bucket == :large) { return 30; }
        return 20;
    }

    function confirmButton1Y(bucket as Lang.Symbol) as Lang.Number {
```

**Depois:**
```monkeyc
    function confirmTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 15; }
        if (bucket == :large) { return 30; }
        return 20;
    }

    function confirmSubtitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 33; }
        if (bucket == :large) { return 55; }
        return 40;
    }

    function confirmButton1Y(bucket as Lang.Symbol) as Lang.Number {
```

---

### 4.20 `resources/strings/strings.xml`

**Antes (final):**
```xml
    <string id="confirm_stop_continue">Continue</string>
</resources>
```

**Depois:**
```xml
    <string id="confirm_stop_continue">Continue</string>
    <string id="recovery_title">Resume session?</string>
    <string id="recovery_remaining">Remaining: $1$</string>
    <string id="recovery_resume">Resume</string>
    <string id="recovery_discard">Discard</string>
</resources>
```

---

### 4.21 `source/TomaApp.mc` — atualizar `AttentionService` initialization

**Antes:**
```monkeyc
        _attentionService = new AttentionService();
```

**Depois:**
```monkeyc
        _attentionService = new AttentionService(_settingsRepo);
```

---

### 4.22 `tests/SettingsRepositoryTest.mc` (CRIAR)

```monkeyc
using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testGetSoundEnabledDefault(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("soundEnabled", null);
    var repo = new SettingsRepository();
    Test.assertEqualMessage(false, repo.getSoundEnabled(), "Default soundEnabled should be false");
    return true;
}

(:test)
function testSetGetSoundEnabled(logger as Test.Logger) as Lang.Boolean {
    var repo = new SettingsRepository();
    repo.setSoundEnabled(true);
    Test.assertEqualMessage(true, repo.getSoundEnabled(), "Should read back true after set");
    repo.setSoundEnabled(false);
    Test.assertEqualMessage(false, repo.getSoundEnabled(), "Should read back false after set");
    return true;
}

(:test)
function testGetCustomWorkMinDefault(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("customWorkMin", null);
    var repo = new SettingsRepository();
    Test.assertEqualMessage(25, repo.getCustomWorkMin(), "Default customWorkMin should be 25");
    return true;
}

(:test)
function testSetGetCustomValues(logger as Test.Logger) as Lang.Boolean {
    var repo = new SettingsRepository();
    repo.setCustomWorkMin(50);
    repo.setCustomBreakMin(10);
    repo.setCustomCycles(3);
    Test.assertEqualMessage(50, repo.getCustomWorkMin(), "Work should be 50");
    Test.assertEqualMessage(10, repo.getCustomBreakMin(), "Break should be 10");
    Test.assertEqualMessage(3, repo.getCustomCycles(), "Cycles should be 3");
    return true;
}

(:test)
function testGetLastSelectedPresetDefault(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("lastSelectedPreset", null);
    var repo = new SettingsRepository();
    Test.assertEqualMessage(0, repo.getLastSelectedPreset(), "Default lastSelectedPreset should be 0");
    return true;
}
```

---

### 4.23 `tests/RecoveryServiceTest.mc` (CRIAR)

```monkeyc
using Toybox.Test;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Lang;

(:test)
function testCheckOnStartEmpty(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("activeSession");
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result == null);
    return true;
}

(:test)
function testCheckOnStartExpired(logger as Test.Logger) as Lang.Boolean {
    var now = Time.now().value();
    App.Storage.setValue("activeSession", {
        "savedAt" => now - 2000,
        "remaining" => 100,
        "state" => PomodoroState.RUNNING_WORK,
        "cyclesCompleted" => 0,
        "currentCycle" => 1,
        "workMin" => 25,
        "breakMin" => 5,
        "cycles" => 4,
        "isCustom" => false
    });
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result == null);
    return true;
}

(:test)
function testCheckOnStartValid(logger as Test.Logger) as Lang.Boolean {
    var now = Time.now().value();
    App.Storage.setValue("activeSession", {
        "savedAt" => now - 60,
        "remaining" => 600,
        "state" => PomodoroState.RUNNING_WORK,
        "cyclesCompleted" => 1,
        "currentCycle" => 2,
        "workMin" => 25,
        "breakMin" => 5,
        "cycles" => 4,
        "isCustom" => false
    });
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result != null);
    var rs = result as RecoveryState;
    Test.assert(rs.remainingSeconds >= 539 && rs.remainingSeconds <= 540);
    Test.assertEqualMessage(1, rs.cyclesCompleted, "cyclesCompleted should be 1");
    Test.assertEqualMessage(2, rs.currentCycle, "currentCycle should be 2");
    return true;
}

(:test)
function testCheckOnStartBelowThreshold(logger as Test.Logger) as Lang.Boolean {
    var now = Time.now().value();
    App.Storage.setValue("activeSession", {
        "savedAt" => now - 10,
        "remaining" => 65,
        "state" => PomodoroState.RUNNING_WORK,
        "cyclesCompleted" => 0,
        "currentCycle" => 1,
        "workMin" => 25,
        "breakMin" => 5,
        "cycles" => 4,
        "isCustom" => false
    });
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result == null);
    return true;
}

(:test)
function testClearDeletesStorage(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("activeSession", { "savedAt" => 123 });
    var service = new RecoveryService();
    service.clear();
    Test.assert(App.Storage.getValue("activeSession") == null);
    return true;
}
```

---

## 5. Storage/Properties

| Key | Tipo | Default | Onde lido | Onde escrito |
|---|---|---|---|---|
| `soundEnabled` | Boolean | false | SettingsRepository, AttentionService (via repo) | SettingsMenuDelegate |
| `vibrationEnabled` | Boolean | true | SettingsRepository, AttentionService (via repo) | SettingsMenuDelegate |
| `backlightOnAlert` | Boolean | true | SettingsRepository, AttentionService (via repo) | SettingsMenuDelegate |
| `recordAsActivity` | Boolean | true | SettingsRepository | SettingsMenuDelegate |
| `language` | String | "auto" | SettingsRepository, SettingsMenu | LanguageMenuDelegate |
| `lastSelectedPreset` | Number | 0 | HomeView | HomeDelegate, CustomBuilderDelegate |
| `customWorkMin` | Number | 25 | HomeDelegate, CustomBuilderView | CustomBuilderDelegate |
| `customBreakMin` | Number | 5 | HomeDelegate, CustomBuilderView | CustomBuilderDelegate |
| `customCycles` | Number | 4 | HomeDelegate, CustomBuilderView | CustomBuilderDelegate |
| `activeSession` (Storage) | Dictionary | null | RecoveryService.checkOnStart | RecoveryService.persistThrottled |

---

## 6. Checklist de execução

- [x] 1. Criar `resources/settings/` directory
- [x] 2. Criar `resources/settings/properties.xml`
- [x] 3. Criar `source/repositories/SettingsRepository.mc`
- [x] 4. Criar `source/model/RecoveryState.mc`
- [x] 5. Criar `source/services/RecoveryService.mc`
- [x] 6. Modificar `source/model/Preset.mc` (adicionar `toDict()` e `fromDict()`)
- [x] 7. Modificar `source/model/PomodoroModel.mc` (adicionar método `hydrate`)
- [x] 8. Modificar `source/services/AttentionService.mc` (injetar SettingsRepository, remover SettingsState refs)
- [x] 9. Modificar `source/TomaApp.mc` (adicionar repos, recovery lógica, remover _customPreset)
- [x] 10. Modificar `source/views/SettingsMenu.mc` (usar SettingsRepository)
- [x] 11. Modificar `source/delegates/SettingsMenuDelegate.mc` (usar SettingsRepository)
- [x] 12. Modificar `source/delegates/LanguageMenuDelegate.mc` (usar SettingsRepository)
- [x] 13. Modificar `source/views/HomeView.mc` (ler lastSelectedPreset)
- [x] 14. Modificar `source/delegates/HomeDelegate.mc` (persistir lastSelectedPreset, usar custom de Properties)
- [x] 15. Modificar `source/views/CustomBuilderView.mc` (receber params no constructor)
- [x] 16. Modificar `source/delegates/CustomBuilderDelegate.mc` (persistir custom, iniciar sessão)
- [x] 17. Modificar `source/ui/layout/Dimensions.mc` (adicionar `confirmSubtitleY`)
- [x] 18. Modificar `resources/strings/strings.xml` (adicionar 4 strings recovery)
- [x] 19. Criar `source/views/RecoveryView.mc`
- [x] 20. Criar `source/delegates/RecoveryDelegate.mc`
- [x] 21. Remover `source/model/SettingsState.mc`
- [x] 22. Criar `tests/SettingsRepositoryTest.mc`
- [x] 23. Criar `tests/RecoveryServiceTest.mc`
- [x] 24. Build para fr255
- [x] 25. Build para fr265
- [ ] 26. Testar no simulador (caminho feliz)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [ ] Unit tests passam (SettingsRepositoryTest, RecoveryServiceTest)

### Manual (simulador)
- [ ] Alterar toggle em Settings → fechar app → reabrir → toggle mantém valor
- [ ] Editar Custom preset → confirmar → timer inicia → fechar app → reabrir → Custom Builder mostra valores salvos
- [ ] Iniciar sessão → esperar >5s → kill app → reabrir → diálogo "Resume session?" aparece com tempo correto
- [ ] No diálogo, selecionar Resume → timer retoma na fase correta com remaining recalculado
- [ ] No diálogo, selecionar Discard → vai para Home, nenhum recovery no próximo start
- [ ] Completar sessão → fechar → reabrir → sem diálogo recovery (storage limpo)
- [ ] Stop sessão via diálogo → fechar → reabrir → sem diálogo recovery (storage limpo)
- [ ] Selecionar preset index 2 → iniciar → fechar → reabrir → Home abre no preset 2

---

## 8. Out of scope

- Strings PT (task 02-12 — localização).
- `settings.xml` para UI de settings via Garmin Connect mobile (V1.1 se trivial).
- ActivityRecording integration com recovery (se user resume, não recria activity — V1 aceita perda).
- Schema versioning no recovery dict (overkill para V1).
- Múltiplos custom presets.
