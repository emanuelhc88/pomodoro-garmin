# Plan — Task 02-07: Preset Personalizado (persistência)

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Criar `PresetRepository` com clamping de valores sobre `SettingsRepository`, e refatorar `CustomBuilderDelegate.onBack()` para salvar via `PresetRepository` (mantendo início de sessão). `HomeDelegate` passa a carregar Custom via `PresetRepository.loadCustom()` para garantir clamping.

---

## 2. Cenários

### Caminho feliz
1. Usuário seleciona Custom (index=3) em P1 → `PresetRepository.loadCustom()` carrega valores persistidos com clamping → abre CustomBuilderView com valores corretos.
2. Usuário edita work=45, break=8, cycles=5 no P2.
3. Usuário pressiona Back (fora de editing) → `PresetRepository.saveCustom(preset)` persiste com clamping → sessão inicia com 45:00.
4. App reaberta → Custom carrega 45/8/5 (não defaults).

### Edge cases
- Valores corrompidos em Properties (ex: work=200) → clamped para WORK_MAX (90).
- Valores null em Properties → fallback para defaults (25/5/4).
- Valor abaixo do mínimo (ex: break=0) → clamped para BREAK_MIN (1).

### Erros
- Properties.getValue retorna null ou tipo errado: `SettingsRepository` já trata null com instanceof check. `PresetRepository` aplica clamping adicional como segunda camada de defesa.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/repositories/PresetRepository.mc` | `loadCustom()` lê de SettingsRepo + clamp. `saveCustom(preset)` clamp + escreve via SettingsRepo. |
| 2 | `tests/PresetRepositoryTest.mc` | Testes: defaults, save/load round-trip, clamping. |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/TomaApp.mc` | Adicionar `_presetRepo` e `getPresetRepo()` |
| 2 | `source/delegates/CustomBuilderDelegate.mc` | `onBack()` usa `PresetRepository.saveCustom()` em vez de `SettingsRepository` direto |
| 3 | `source/delegates/HomeDelegate.mc` | `onSelect()` index==3 usa `PresetRepository.loadCustom()` |

### 4.1 `source/TomaApp.mc`

**Antes:**
```monkeyc
    private var _settingsRepo as SettingsRepository;
    private var _recoveryService as RecoveryService;
```

**Depois:**
```monkeyc
    private var _settingsRepo as SettingsRepository;
    private var _presetRepo as PresetRepository;
    private var _recoveryService as RecoveryService;
```

**Antes (dentro de `initialize()`):**
```monkeyc
        _settingsRepo = new SettingsRepository();
        _recoveryService = new RecoveryService();
```

**Depois:**
```monkeyc
        _settingsRepo = new SettingsRepository();
        _presetRepo = new PresetRepository(_settingsRepo);
        _recoveryService = new RecoveryService();
```

**Antes (getter):**
```monkeyc
    function getSettingsRepo() as SettingsRepository {
        return _settingsRepo;
    }
```

**Depois (adicionar logo após `getSettingsRepo`):**
```monkeyc
    function getSettingsRepo() as SettingsRepository {
        return _settingsRepo;
    }

    function getPresetRepo() as PresetRepository {
        return _presetRepo;
    }
```

### 4.2 `source/delegates/CustomBuilderDelegate.mc`

**Antes:**
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

**Depois:**
```monkeyc
    function onBack() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.cancelEdit();
        } else {
            var app = App.getApp() as TomaApp;
            var preset = _view.buildPreset();
            app.getPresetRepo().saveCustom(preset);
            app.getSettingsRepo().setLastSelectedPreset(3);
            app.startSession(preset);
            Ui.switchToView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
        }
        return true;
    }
```

### 4.3 `source/delegates/HomeDelegate.mc`

**Antes:**
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

**Depois:**
```monkeyc
        if (selectedIndex == 3) {
            var app = App.getApp() as TomaApp;
            var customPreset = app.getPresetRepo().loadCustom();
            var view = new CustomBuilderView(customPreset.workMin, customPreset.breakMin, customPreset.cycles);
            Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }
```

---

## 5. Storage/Properties

| Key | Tipo | Default | Onde lido | Onde escrito |
|---|---|---|---|---|
| `customWorkMin` | Number | 25 | `PresetRepository.loadCustom()` (via SettingsRepo) | `PresetRepository.saveCustom()` (via SettingsRepo) |
| `customBreakMin` | Number | 5 | `PresetRepository.loadCustom()` (via SettingsRepo) | `PresetRepository.saveCustom()` (via SettingsRepo) |
| `customCycles` | Number | 4 | `PresetRepository.loadCustom()` (via SettingsRepo) | `PresetRepository.saveCustom()` (via SettingsRepo) |

Nenhuma nova key — todas já declaradas em `resources/settings/properties.xml`.

---

## 6. Checklist de execução

- [x] 1. Criar `source/repositories/PresetRepository.mc`
- [x] 2. Criar `tests/PresetRepositoryTest.mc`
- [x] 3. Modificar `source/TomaApp.mc` (adicionar `_presetRepo` field, instanciação no `initialize()`, getter `getPresetRepo()`)
- [x] 4. Modificar `source/delegates/CustomBuilderDelegate.mc` (usar `PresetRepository.saveCustom()`)
- [x] 5. Modificar `source/delegates/HomeDelegate.mc` (usar `PresetRepository.loadCustom()`)
- [x] 6. Build para fr255: `monkeyc -d fr255`
- [x] 7. Build para fr255s: `monkeyc -d fr255s`
- [x] 8. Build para fr265: `monkeyc -d fr265`
- [ ] 9. Testar no simulador (caminho feliz)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [ ] Testes `PresetRepositoryTest`: defaults (25/5/4) retornados sem dados salvos
- [ ] Testes `PresetRepositoryTest`: save + load retorna valores salvos
- [ ] Testes `PresetRepositoryTest`: valores fora de range são clampados

### Manual (simulador)
- [ ] Editar Custom em P2 (work=45, break=8, cycles=5) → Back → sessão inicia com 45:00
- [ ] Selecionar Custom em P1 → Builder abre com valores persistidos (45/8/5)
- [ ] Fechar e reabrir app → Custom mantém valores salvos
- [ ] Valor corrompido (se testável): clamping funciona

---

## 8. Out of scope
- Múltiplos custom presets (V2).
- Settings Garmin Connect mobile (V1.x).
- Mudar fluxo UX — Back continua salvando + iniciando sessão (como está hoje).
- Modificar `CustomBuilderView.mc` — já recebe valores no `initialize()` e funciona corretamente.
- Modificar `Preset.mc` — clamping fica encapsulado no `PresetRepository`.

---

## Apêndice: Código completo dos arquivos novos

### `source/repositories/PresetRepository.mc`

```monkeyc
using Toybox.Lang;

class PresetRepository {
    private var _settings as SettingsRepository;

    function initialize(settings as SettingsRepository) {
        _settings = settings;
    }

    function loadCustom() as Preset {
        var work = _clampWork(_settings.getCustomWorkMin());
        var brk = _clampBreak(_settings.getCustomBreakMin());
        var cycles = _clampCycles(_settings.getCustomCycles());
        return new Preset(work, brk, cycles, true);
    }

    function saveCustom(preset as Preset) as Void {
        _settings.setCustomWorkMin(_clampWork(preset.workMin));
        _settings.setCustomBreakMin(_clampBreak(preset.breakMin));
        _settings.setCustomCycles(_clampCycles(preset.cycles));
    }

    private function _clampWork(v as Lang.Number) as Lang.Number {
        if (v < PresetLimits.WORK_MIN) { return PresetLimits.WORK_MIN; }
        if (v > PresetLimits.WORK_MAX) { return PresetLimits.WORK_MAX; }
        return v;
    }

    private function _clampBreak(v as Lang.Number) as Lang.Number {
        if (v < PresetLimits.BREAK_MIN) { return PresetLimits.BREAK_MIN; }
        if (v > PresetLimits.BREAK_MAX) { return PresetLimits.BREAK_MAX; }
        return v;
    }

    private function _clampCycles(v as Lang.Number) as Lang.Number {
        if (v < PresetLimits.CYCLES_MIN) { return PresetLimits.CYCLES_MIN; }
        if (v > PresetLimits.CYCLES_MAX) { return PresetLimits.CYCLES_MAX; }
        return v;
    }
}
```

### `tests/PresetRepositoryTest.mc`

```monkeyc
using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testLoadCustomDefaults(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("customWorkMin", null);
    App.Properties.setValue("customBreakMin", null);
    App.Properties.setValue("customCycles", null);
    var repo = new PresetRepository(new SettingsRepository());
    var preset = repo.loadCustom();
    Test.assertEqualMessage(25, preset.workMin, "Default work should be 25");
    Test.assertEqualMessage(5, preset.breakMin, "Default break should be 5");
    Test.assertEqualMessage(4, preset.cycles, "Default cycles should be 4");
    Test.assertEqualMessage(true, preset.isCustom, "Should be marked as custom");
    return true;
}

(:test)
function testSaveAndLoadCustom(logger as Test.Logger) as Lang.Boolean {
    var repo = new PresetRepository(new SettingsRepository());
    var preset = new Preset(45, 8, 5, true);
    repo.saveCustom(preset);
    var loaded = repo.loadCustom();
    Test.assertEqualMessage(45, loaded.workMin, "Work should be 45");
    Test.assertEqualMessage(8, loaded.breakMin, "Break should be 8");
    Test.assertEqualMessage(5, loaded.cycles, "Cycles should be 5");
    return true;
}

(:test)
function testClampWorkAboveMax(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomWorkMin(200);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(90, preset.workMin, "Work above max should clamp to 90");
    return true;
}

(:test)
function testClampWorkBelowMin(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomWorkMin(1);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(5, preset.workMin, "Work below min should clamp to 5");
    return true;
}

(:test)
function testClampBreakAboveMax(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomBreakMin(60);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(30, preset.breakMin, "Break above max should clamp to 30");
    return true;
}

(:test)
function testClampCyclesBelowMin(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomCycles(0);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(1, preset.cycles, "Cycles below min should clamp to 1");
    return true;
}

(:test)
function testSaveClampsToo(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    var repo = new PresetRepository(settings);
    var badPreset = new Preset(999, 0, 99, true);
    repo.saveCustom(badPreset);
    Test.assertEqualMessage(90, settings.getCustomWorkMin(), "Saved work should be clamped to 90");
    Test.assertEqualMessage(1, settings.getCustomBreakMin(), "Saved break should be clamped to 1");
    Test.assertEqualMessage(10, settings.getCustomCycles(), "Saved cycles should be clamped to 10");
    return true;
}
```
