# Plan — Task 02-10: FIT Activity Recording

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Criar `ActivityService` como wrapper sobre `Toybox.ActivityRecording` e conectá-lo aos eventos do `PomodoroModel` via `TomaApp.onModelEvent()`. Quando `recordAsActivity == true`, uma FIT Activity "Focus" é iniciada com a sessão Pomodoro, salva no complete, e descartada no stop.

---

## 2. Cenários

### Caminho feliz

1. Usuário abre app, seleciona preset, inicia sessão.
2. `onModelEvent(ON_START)` → `ActivityService.start()` cria session FIT "Focus" e inicia gravação.
3. Timer roda todos os ciclos (work/break/work/break/.../long break).
4. `onModelEvent(ON_COMPLETE)` → `ActivityService.stop()` salva a activity.
5. Activity aparece no Garmin Connect como "Focus" com duração, HR, calorias.

### Edge cases

| Caso | Comportamento esperado |
|------|----------------------|
| `recordAsActivity == false` | `start()` retorna imediatamente sem criar session |
| Pause/resume durante sessão | Activity continua gravando (sem pausa) |
| Recovery de sessão (app reaberto) | `hydrate()` emite `ON_START` → nova activity criada para tempo restante |
| Double-start (session já ativa) | Guard `_session != null` → retorna sem criar nova |
| Device sem ActivityRecording | Capability detection → retorna silenciosamente |
| `createSession` falha (outra activity ativa) | Try/catch → log + `_session` permanece null |
| `stop()`/`discard()` com `_session == null` | Guard → retorna sem ação |

### Erros

| Erro | Tratamento |
|------|-----------|
| Exception em `createSession` | Try/catch, `System.println` debug, `_session = null`, Pomodoro continua |
| Exception em `session.stop()` ou `session.save()` | Try/catch, `System.println` debug, `_session = null` |
| Exception em `session.discard()` | Try/catch, `System.println` debug, `_session = null` |

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|------|-----------------|
| 1 | `source/services/ActivityService.mc` | Wrapper sobre ActivityRecording. Métodos: `start()`, `stop()`, `discard()`. |
| 2 | `tests/ActivityServiceTest.mc` | Smoke tests para branch logic (enabled/disabled, guards). |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|------|-----------|
| 1 | `source/TomaApp.mc` | Adicionar campo `_activityService`, instanciar no `initialize()`, chamar nos eventos. |

---

### 3.1 `source/services/ActivityService.mc` (CRIAR)

```monkeyc
using Toybox.ActivityRecording;
using Toybox.Lang;
using Toybox.System;

class ActivityService {
    private var _session as ActivityRecording.Session?;
    private var _settingsRepo as SettingsRepository;

    function initialize(settingsRepo as SettingsRepository) {
        _settingsRepo = settingsRepo;
    }

    function start() as Void {
        if (!_settingsRepo.getRecordAsActivity()) {
            return;
        }
        if (_session != null) {
            return;
        }
        if (!(Toybox has :ActivityRecording) ||
            !(Toybox.ActivityRecording has :createSession)) {
            return;
        }
        try {
            _session = ActivityRecording.createSession({
                :name => "Focus",
                :sport => ActivityRecording.SPORT_GENERIC,
                :subSport => ActivityRecording.SUB_SPORT_GENERIC
            });
            (_session as ActivityRecording.Session).start();
        } catch (e instanceof Lang.Exception) {
            _debugLog("start failed: " + e.getErrorMessage());
            _session = null;
        }
    }

    function stop() as Void {
        if (_session == null) {
            return;
        }
        try {
            (_session as ActivityRecording.Session).stop();
            (_session as ActivityRecording.Session).save();
        } catch (e instanceof Lang.Exception) {
            _debugLog("stop failed: " + e.getErrorMessage());
        }
        _session = null;
    }

    function discard() as Void {
        if (_session == null) {
            return;
        }
        try {
            (_session as ActivityRecording.Session).stop();
            (_session as ActivityRecording.Session).discard();
        } catch (e instanceof Lang.Exception) {
            _debugLog("discard failed: " + e.getErrorMessage());
        }
        _session = null;
    }

    function isRecording() as Lang.Boolean {
        return _session != null;
    }

    (:debug)
    private function _debugLog(msg as Lang.String) as Void {
        System.println("[ActivityService] " + msg);
    }
}
```

### 3.2 `tests/ActivityServiceTest.mc` (CRIAR)

```monkeyc
using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testActivityServiceStartWhenDisabled(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("recordAsActivity", false);
    var repo = new SettingsRepository();
    var service = new ActivityService(repo);
    service.start();
    Test.assert(!service.isRecording());
    App.Properties.setValue("recordAsActivity", true);
    return true;
}

(:test)
function testActivityServiceStopWithNoSession(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("recordAsActivity", true);
    var repo = new SettingsRepository();
    var service = new ActivityService(repo);
    service.stop();
    Test.assert(!service.isRecording());
    return true;
}

(:test)
function testActivityServiceDiscardWithNoSession(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("recordAsActivity", true);
    var repo = new SettingsRepository();
    var service = new ActivityService(repo);
    service.discard();
    Test.assert(!service.isRecording());
    return true;
}
```

### 4.1 `source/TomaApp.mc`

**Antes (campo + initialize):**
```monkeyc
    private var _recoveryService as RecoveryService;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _settingsRepo = new SettingsRepository();
        _presetRepo = new PresetRepository(_settingsRepo);
        _recoveryService = new RecoveryService();
        _attentionService = new AttentionService(_settingsRepo);
        _counterRepo = new CounterRepository();
        _historyRepo = new HistoryRepository();
        _model.addObserver(method(:onModelEvent));
    }
```

**Depois (campo + initialize):**
```monkeyc
    private var _recoveryService as RecoveryService;
    private var _activityService as ActivityService;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _settingsRepo = new SettingsRepository();
        _presetRepo = new PresetRepository(_settingsRepo);
        _recoveryService = new RecoveryService();
        _attentionService = new AttentionService(_settingsRepo);
        _activityService = new ActivityService(_settingsRepo);
        _counterRepo = new CounterRepository();
        _historyRepo = new HistoryRepository();
        _model.addObserver(method(:onModelEvent));
    }
```

**Antes (onModelEvent — ON_START handler):**
```monkeyc
    function onModelEvent(event as Lang.Number) as Void {
        if (event == PomodoroEvent.ON_START) {
            _attentionService.alertStart();
        } else if (event == PomodoroEvent.ON_PHASE_CHANGE) {
```

**Depois (onModelEvent — ON_START handler):**
```monkeyc
    function onModelEvent(event as Lang.Number) as Void {
        if (event == PomodoroEvent.ON_START) {
            _attentionService.alertStart();
            _activityService.start();
        } else if (event == PomodoroEvent.ON_PHASE_CHANGE) {
```

**Antes (onModelEvent — ON_COMPLETE handler):**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _appendSessionToHistory();
            _timerService.stop();
            _recoveryService.clear();
```

**Depois (onModelEvent — ON_COMPLETE handler):**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _activityService.stop();
            _appendSessionToHistory();
            _timerService.stop();
            _recoveryService.clear();
```

**Antes (stopSession method):**
```monkeyc
    function stopSession() as Void {
        _model.stop();
        _timerService.stop();
        _recoveryService.clear();
    }
```

**Depois (stopSession method):**
```monkeyc
    function stopSession() as Void {
        _activityService.discard();
        _model.stop();
        _timerService.stop();
        _recoveryService.clear();
    }
```

---

## 5. Storage/Properties (se aplicável)

| Key | Tipo | Default | Onde lido | Onde escrito |
|-----|------|---------|-----------|-------------|
| `recordAsActivity` | Boolean | `true` | `SettingsRepository.getRecordAsActivity()` → `ActivityService.start()` | `SettingsRepository.setRecordAsActivity()` via SettingsMenu |

Já existente. Nenhuma mudança em `properties.xml`.

---

## 6. Checklist de execução

- [x] 1. Criar `source/services/ActivityService.mc` com conteúdo da seção 3.1.
- [x] 2. Criar `tests/ActivityServiceTest.mc` com conteúdo da seção 3.2.
- [x] 3. Modificar `source/TomaApp.mc` — adicionar campo `_activityService` (seção 4.1, primeiro diff).
- [x] 4. Modificar `source/TomaApp.mc` — adicionar `_activityService.start()` no handler ON_START (seção 4.1, segundo diff).
- [x] 5. Modificar `source/TomaApp.mc` — adicionar `_activityService.stop()` no handler ON_COMPLETE (seção 4.1, terceiro diff).
- [x] 6. Modificar `source/TomaApp.mc` — adicionar `_activityService.discard()` em `stopSession()` (seção 4.1, quarto diff).
- [x] 7. Build: `monkeyc -d fr255` compila sem erros.
- [x] 8. Build: `monkeyc -d fr265` compila sem erros.
- [ ] 9. Rodar testes unitários — 3 novos testes passam.
- [ ] 10. Testar no simulador: iniciar e completar sessão → checar FIT em `~/Library/Application Support/Garmin/ConnectIQ/Activities/`.
- [ ] 11. Testar no simulador: stopar sessão antes de completar → nenhum FIT novo gerado.
- [ ] 12. Testar no simulador: `recordAsActivity = false` → completar sessão → nenhum FIT novo gerado.

---

## 7. Critérios de aceite

### Automated

- [x] `monkeyc -d fr255` compila sem erros ou warnings.
- [x] `monkeyc -d fr255s` compila sem erros ou warnings.
- [x] `monkeyc -d fr265` compila sem erros ou warnings.
- [ ] Testes unitários passam (3 novos + todos existentes).

### Manual (simulador)

- [ ] Settings → "Record as activity" ON (default).
- [ ] Iniciar e completar sessão (preset rápido para teste) → arquivo FIT aparece em Activities.
- [ ] Sessão stopada (não completada) → NÃO gera FIT.
- [ ] Settings → "Record as activity" OFF → completar sessão → NÃO gera FIT.
- [ ] Recovery de sessão → nova activity criada para o tempo restante.

---

## 8. Out of scope

- Custom FIT fields via `FitContributor` (V1.1+).
- Permission `FitContributor` no manifest.
- `SPORT_FOCUS` ou sub-sport customizado (não existe no SDK).
- Pause/resume da ActivityRecording durante pause Pomodoro.
- GPS tracking (não queremos).
- Configuração do nome da activity pelo usuário (V2).
