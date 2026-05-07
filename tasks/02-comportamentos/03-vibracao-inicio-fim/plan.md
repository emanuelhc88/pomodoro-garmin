# Plan — Task 02-03: Vibration & Sound (AttentionService)

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Criar `AttentionService` como wrapper stateless sobre `Toybox.Attention` e conectá-lo ao `TomaApp.onModelEvent`, de modo que eventos do `PomodoroModel` disparem vibração, som e backlight conforme settings do usuário e estado DND do device.

---

## 2. Cenários

### Caminho feliz

1. Usuário inicia sessão → `ON_START` emitido → `AttentionService.alertStart()` → 1 pulso curto de vibração + backlight flash.
2. Work phase termina → `ON_PHASE_CHANGE` emitido, model state = `RUNNING_SHORT_BREAK` ou `RUNNING_LONG_BREAK` → `alertEndOfWork()` → 2 pulsos médios + tone (se speaker) + backlight.
3. Break termina → `ON_PHASE_CHANGE` emitido, model state = `RUNNING_WORK` → `alertEndOfBreak()` → 1 pulso longo + backlight.
4. Ciclo completo → `ON_COMPLETE` emitido → `alertCycleComplete()` → 3 pulsos longos + tone + backlight.

### Edge cases

- `vibrationEnabled == false` → vibração suprimida, mas som e backlight permanecem (se habilitados).
- `soundEnabled == false` (default) → tone suprimido.
- `backlightOnAlert == false` → backlight suprimido.
- Device sem `:vibrate` → vibração silenciosamente ignorada via `has` check.
- Device sem `:playTone` (sem speaker) → tone ignorado.
- Device sem `:backlight` → backlight ignorado.
- `doNotDisturb == true` → suprime vibração e som, mas backlight permitido (não incomoda terceiros).
- `doNotDisturb` não existe no firmware → tratar como `false` via `has` check no field.

### Erros

- Nenhum erro fatal possível — todas as APIs Attention são fire-and-forget. Se capability não existe, no-op silencioso.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/services/AttentionService.mc` | Wrapper sobre `Toybox.Attention`. Métodos públicos: `alertStart`, `alertEndOfWork`, `alertEndOfBreak`, `alertCycleComplete`. Consulta `SettingsState` e DND antes de executar. |
| 2 | `tests/AttentionServiceTest.mc` | Testes unitários verificando que os métodos respeitam settings e DND. |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/TomaApp.mc` | Instanciar `AttentionService` + expandir `onModelEvent` para despachar alertas. |
| 2 | `manifest.xml` | Adicionar permissão `Attention`. |

### 4.1 `source/services/AttentionService.mc` (CRIAR)

```monkeyc
using Toybox.Attention;
using Toybox.System;
using Toybox.Lang;

class AttentionService {
    function initialize() {
    }

    function alertStart() as Void {
        _vibrate([new Attention.VibeProfile(75, 200)]);
        _flashBacklight();
    }

    function alertEndOfWork() as Void {
        _vibrate([
            new Attention.VibeProfile(100, 400),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 400)
        ]);
        _playTone();
        _flashBacklight();
    }

    function alertEndOfBreak() as Void {
        _vibrate([new Attention.VibeProfile(100, 600)]);
        _flashBacklight();
    }

    function alertCycleComplete() as Void {
        _vibrate([
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 500)
        ]);
        _playTone();
        _flashBacklight();
    }

    private function _vibrate(profile as Lang.Array<Attention.VibeProfile>) as Void {
        if (!SettingsState.vibrationEnabled) {
            return;
        }
        if (_isDoNotDisturb()) {
            return;
        }
        if (Attention has :vibrate) {
            Attention.vibrate(profile);
        }
    }

    private function _playTone() as Void {
        if (!SettingsState.soundEnabled) {
            return;
        }
        if (_isDoNotDisturb()) {
            return;
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
    }

    private function _flashBacklight() as Void {
        if (!SettingsState.backlightOnAlert) {
            return;
        }
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
    }

    private function _isDoNotDisturb() as Lang.Boolean {
        var settings = System.getDeviceSettings();
        if (settings has :doNotDisturb) {
            return settings.doNotDisturb;
        }
        return false;
    }
}
```

### 4.2 `source/TomaApp.mc`

**Antes:**

```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _model.addObserver(method(:onModelEvent));
    }
```

**Depois:**

```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _attentionService = new AttentionService();
        _model.addObserver(method(:onModelEvent));
    }
```

**Antes (onModelEvent):**

```monkeyc
    function onModelEvent(event as Lang.Number) as Void {
        if (event == PomodoroEvent.ON_COMPLETE) {
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

### 4.3 `manifest.xml`

**Antes:**

```xml
        <iq:permissions>
        </iq:permissions>
```

**Depois:**

```xml
        <iq:permissions>
            <iq:uses-permission id="Attention"/>
        </iq:permissions>
```

### 4.4 `tests/AttentionServiceTest.mc` (CRIAR)

```monkeyc
using Toybox.Test;
using Toybox.Lang;

(:test)
function testAlertStartRespectsVibrationDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = false;
    SettingsState.backlightOnAlert = true;
    var service = new AttentionService();
    // Should not crash — vibration suppressed, backlight still fires
    service.alertStart();
    SettingsState.vibrationEnabled = true;
    return true;
}

(:test)
function testAlertEndOfWorkRespectsSoundDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.soundEnabled = false;
    SettingsState.vibrationEnabled = true;
    SettingsState.backlightOnAlert = true;
    var service = new AttentionService();
    // Should not crash — sound suppressed
    service.alertEndOfWork();
    return true;
}

(:test)
function testAlertEndOfBreakRespectsBacklightDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = true;
    SettingsState.backlightOnAlert = false;
    var service = new AttentionService();
    // Should not crash — backlight suppressed
    service.alertEndOfBreak();
    SettingsState.backlightOnAlert = true;
    return true;
}

(:test)
function testAlertCycleCompleteWithAllEnabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = true;
    SettingsState.soundEnabled = true;
    SettingsState.backlightOnAlert = true;
    var service = new AttentionService();
    // Should not crash — all alerts fire
    service.alertCycleComplete();
    SettingsState.soundEnabled = false;
    return true;
}

(:test)
function testAllAlertsSuppressedWhenAllDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = false;
    SettingsState.soundEnabled = false;
    SettingsState.backlightOnAlert = false;
    var service = new AttentionService();
    // None should crash — all suppressed
    service.alertStart();
    service.alertEndOfWork();
    service.alertEndOfBreak();
    service.alertCycleComplete();
    SettingsState.vibrationEnabled = true;
    SettingsState.backlightOnAlert = true;
    return true;
}
```

---

## 5. Storage/Properties

N/A — esta task não introduz persistência. `SettingsState` é in-memory (task 02-08 migrará para Properties).

---

## 6. Checklist de execução

- [x] 1. Criar `source/services/AttentionService.mc` com código exato da seção 4.1
- [x] 2. Modificar `source/TomaApp.mc` — adicionar field `_attentionService` e instanciar no `initialize()` (seção 4.2)
- [x] 3. Modificar `source/TomaApp.mc` — expandir `onModelEvent` com despacho de alertas (seção 4.2)
- [x] 4. ~~Modificar `manifest.xml`~~ — SDK não requer permissão para Attention (revertido)
- [x] 5. Criar `tests/AttentionServiceTest.mc` com código exato da seção 4.4
- [x] 6. Build para fr255 — verificar que compila sem erros
- [x] 7. Build para fr255s — verificar que compila sem erros
- [x] 8. Build para fr265 — verificar que compila sem erros
- [ ] 9. Testar no simulador (caminho feliz: iniciar sessão, verificar logs) — MANUAL

---

## 7. Critérios de aceite

### Automated

- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [ ] Testes unitários passam (`monkeyc --unit-test`)

### Manual (simulador)

- [ ] Iniciar sessão → log de vibração `alertStart` aparece (simulador não vibra, mas não crasha)
- [ ] Work phase completa → log de `alertEndOfWork` aparece na transição
- [ ] Break completa → log de `alertEndOfBreak` aparece na transição de volta para work
- [ ] Ciclo completo (4 works + long break) → `alertCycleComplete` é chamado
- [ ] Desativar `vibrationEnabled` via SettingsMenu → vibração não é chamada (verificar via debug print ou ausência de log)
- [ ] App não crasha em nenhuma transição

---

## 8. Out of scope

- Persistência de settings (task 02-08)
- SettingsRepository (task 02-08)
- Custom vibration profiles editáveis pelo usuário (V2)
- Padrões diferenciados para short break vs long break (decisão D1: mesmo padrão em V1)
- ActivityRecording/FIT (task 02-11)
- Recovery após kill (task 02-12)
