# Task 02-08: Persistência de Settings + Recovery

## Objetivo

Implementar persistência completa das settings em `Application.Properties` e o sistema de **recovery** após kill (B16): se o app for fechado durante uma sessão, ao reabrir oferece "Resume?" com tempo restante calculado.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B12** Settings persistentes — `spec/spec.md` §4.B12
- **B16** Recovery após kill — `spec/spec.md` §4.B16
- **C14** Recovery Dialog

## Dependências

- `tasks/01-prototipos-visuais/08-tela-settings.md` (SettingsMenu existente).
- `tasks/02-comportamentos/02-timer-loop.md` (Timer roda).
- `tasks/02-comportamentos/04-pausa-resume-stop.md` (estados completos).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings, `--typecheck=Strict` passa.
- [ ] Testes em `tests/SettingsRepositoryTest.mc`:
  - Get sem dados retorna defaults documentados.
  - Set/Get round-trip preserva valor.
  - `onSettingsChanged` callback é invocado quando setting muda.
- [ ] Testes em `tests/RecoveryServiceTest.mc`:
  - Recovery state vazio → null.
  - Recovery state com remaining > 60 → retorna RecoveryState.
  - Recovery state com remaining < 60 → null (não vale interromper).
  - savedAt diff calculado corretamente.

### Manual

- [ ] Toggle "Sound" em Settings: valor persiste após reabrir app.
- [ ] Toggle "Vibration" off: vibrações suprimidas (validar em FR255 físico).
- [ ] Toggle "Record as activity" off: sessão não vira activity FIT (validar em `02-10`).
- [ ] Mudar Language em Settings → strings refletem (validar `02-12`).
- [ ] Iniciar sessão de 25 min, deixar rodar 10 min, **fechar app** (Back até sair, ou kill no simulador).
- [ ] Reabrir app → diálogo "Resume session?" aparece com tempo restante (~15 min).
- [ ] "Resume" → TimerView abre com 15:00 e continua.
- [ ] Iniciar sessão, deixar 5s, fechar → reabrir → diálogo aparece (vamos validar threshold de 60s? ajustar para teste).
- [ ] Sessão completada normalmente → next open NÃO mostra recovery dialog.

## Arquivos esperados

### Novos

- `source/repositories/SettingsRepository.mc`.
- `source/services/RecoveryService.mc`.
- `source/views/RecoveryView.mc` — diálogo de recovery.
- `source/delegates/RecoveryDelegate.mc`.
- `tests/SettingsRepositoryTest.mc`.
- `tests/RecoveryServiceTest.mc`.

### Modificados

- `source/TomaApp.mc`:
  - `getInitialView()` checa `RecoveryService.checkOnStart()` antes de retornar HomeView. Se há recovery, retorna RecoveryView.
  - Tick handler agora chama `RecoveryService.persistThrottled(model)` a cada 5s.
- `source/services/AttentionService.mc` — usar `SettingsRepository` real (era hardcoded).
- `source/views/SettingsMenu.mc` — `ToggleMenuItem` lê valor inicial de Repository, escreve via Repository.
- `source/delegates/SettingsMenuDelegate.mc` — `onSelect` em ToggleItem persiste via Repository.
- `source/delegates/HomeDelegate.mc` — ao iniciar sessão, lembrar último preset selecionado em Properties (`lastSelectedPreset`).
- `source/views/HomeView.mc` — ao mostrar, ler `lastSelectedPreset` para selecionar default.

## Referências obrigatórias

- `references/architecture.md` §3 (Repository).
- `references/garmin_platform.md` §2.3 (Properties), §2.4 (Storage), §6 (Recovery strategy).
- `spec/spec.md` §4.B12, §4.B16, §6 (regras de negócio).

## Especificação técnica

### SettingsRepository

Keys + defaults documentados em `references/garmin_platform.md` §2.3.

```monkeyc
using Toybox.Application as App;

class SettingsRepository {
    private var _onChange as Method?;

    function setChangeListener(callback as Method) {
        _onChange = callback;
    }

    function getSoundEnabled() as Boolean { return _getBool("soundEnabled", false); }
    function setSoundEnabled(v as Boolean) { _set("soundEnabled", v); }

    function getVibrationEnabled() as Boolean { return _getBool("vibrationEnabled", true); }
    function setVibrationEnabled(v as Boolean) { _set("vibrationEnabled", v); }

    function getBacklightOnAlert() as Boolean { return _getBool("backlightOnAlert", true); }
    function setBacklightOnAlert(v as Boolean) { _set("backlightOnAlert", v); }

    function getRecordAsActivity() as Boolean { return _getBool("recordAsActivity", true); }
    function setRecordAsActivity(v as Boolean) { _set("recordAsActivity", v); }

    function getLanguage() as String { return _getString("language", "auto"); }
    function setLanguage(v as String) { _set("language", v); }

    function getLastSelectedPreset() as Number { return _getNumber("lastSelectedPreset", 0); }
    function setLastSelectedPreset(v as Number) { _set("lastSelectedPreset", v); }

    private function _getBool(key, default) as Boolean {
        var v = App.Properties.getValue(key);
        return v == null ? default : v as Boolean;
    }
    private function _set(key, v) {
        App.Properties.setValue(key, v);
        if (_onChange != null) { _onChange.invoke(key, v); }
    }
    // ... outros _get*
}
```

### RecoveryService

```monkeyc
using Toybox.Application as App;
using Toybox.Time;

class RecoveryService {
    private const KEY = "activeSession";
    private const MIN_RESUME_SECONDS = 60;
    private var _lastSavedAt as Number = 0;

    function checkOnStart() as RecoveryState? {
        var saved = App.Storage.getValue(KEY);
        if (saved == null) { return null; }

        var savedAt = saved["savedAt"] as Number;
        var elapsed = Time.now().value() - savedAt;
        var remainingAtSave = saved["remaining"] as Number;
        var newRemaining = remainingAtSave - elapsed;

        if (newRemaining < MIN_RESUME_SECONDS) {
            // Não vale resumir; apaga
            App.Storage.deleteValue(KEY);
            return null;
        }

        return new RecoveryState(saved, newRemaining);
    }

    function persistThrottled(model as PomodoroModel) as Void {
        var now = Time.now().value();
        if (now - _lastSavedAt < 5) { return; }
        _lastSavedAt = now;

        if (model.getState() == :idle || model.getState() == :completed) {
            App.Storage.deleteValue(KEY);
            return;
        }

        App.Storage.setValue(KEY, {
            "preset" => model.getPreset().toDict(),
            "phase" => model.getState(),  // symbol — pode precisar serializar como string
            "remaining" => model.getRemainingSeconds(),
            "savedAt" => now,
            "cyclesCompleted" => model.getCyclesCompleted()
        });
    }

    function clear() as Void {
        App.Storage.deleteValue(KEY);
    }
}

class RecoveryState {
    public var preset as Preset;
    public var phase as Symbol;
    public var remaining as Number;
    public var cyclesCompleted as Number;

    function initialize(saved as Dictionary, newRemaining as Number) {
        // hidrata do dict
    }
}
```

**⚠️ Symbol em Storage:** Storage não serializa Symbols nativamente. Converter pra String:
```monkeyc
function _phaseToString(p as Symbol) as String {
    if (p == :running_work) { return "running_work"; }
    // ...
}
```

### TomaApp.getInitialView

```monkeyc
function getInitialView() as Array {
    var recovery = _recoveryService.checkOnStart();
    if (recovery != null) {
        return [new RecoveryView(recovery), new RecoveryDelegate(self, recovery)];
    }
    return [new HomeView(self), new HomeDelegate(self)];
}
```

### RecoveryView UI

Diálogo simples:
- Título: "Resume session?" / "Retomar sessão?"
- Subtitle: "Remaining: 14:23" / "Restante: 14:23"
- 2 botões: "Resume" (destacado) / "Discard"

### TomaApp tick handler

```monkeyc
function onTimerTick() as Void {
    if (_model.isPaused()) { return; }
    _model.tick();
    _recoveryService.persistThrottled(_model);
    if (_model.getState() == :completed) {
        _recoveryService.clear();
        _timerService.stop();
    }
}
```

### Settings change listener

Quando uma setting muda, AttentionService precisa recarregar (ou simplesmente lê on-demand a cada vez). Lê on-demand é mais simples — sem cache, sem bug de stale data.

## Out of scope desta task

- Settings via Garmin Connect mobile (V1.x).
- Migração de schema entre versões (V2).
- Multi-language em runtime (próxima task).
