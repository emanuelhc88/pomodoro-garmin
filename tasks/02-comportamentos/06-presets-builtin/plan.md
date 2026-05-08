# Plan — Task 02-06: Presets Builtin

> Spec Tatica gerada na FASE 2.3. Executar com `/execute` na proxima sessao.

---

## 1. Resumo

Fechar o ciclo dos presets builtin: adicionar `getLongBreakSeconds()` ao `Preset`, refatorar `PomodoroModel` para usa-lo, habilitar o fluxo "Custom editado → startSession" via estado in-memory no `TomaApp`, e validar tudo com testes unitarios.

## 2. Cenarios

### Caminho feliz
1. Usuario abre app → Home lista 5 itens (3 builtin + Custom + Settings).
2. Seleciona preset 25/5 → `startSession` chamado, TimerView abre com 25:00.
3. Seleciona preset 30/5 → TimerView com 30:00.
4. Seleciona preset 50/10 → TimerView com 50:00.
5. Seleciona Custom (nunca editado) → abre CustomBuilderView.
6. Edita valores (ex: 40/8/3), dá Back → volta ao Home, custom preset armazenado em memória.
7. Seleciona Custom novamente → `startSession` com 40/8/3, TimerView com 40:00.
8. Timer chega ao final de todos os work phases → long break = breakMin * 3 minutos.

### Edge cases
- Custom nunca editado: `app.getCustomPreset()` é null → abre builder sempre.
- Custom editado mas app reiniciado (sem persistência): perde custom, volta a abrir builder — comportamento aceito (persistência é task 02-07).
- Preset com cycles=1: não entra em long break, vai direto para COMPLETED (já implementado).

### Erros
- Nenhum cenário de erro de runtime novo. O código existente já protege contra `start()` fora de IDLE/COMPLETED.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `tests/PresetsTest.mc` | Testes unitários: builtinList, isCustom, formatPrimary/Secondary, getLongBreakSeconds |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/model/Preset.mc` | Adicionar `getLongBreakSeconds()` |
| 2 | `source/model/PomodoroModel.mc` | Usar `preset.getLongBreakSeconds()` em vez de cálculo inline |
| 3 | `source/views/CustomBuilderView.mc` | Adicionar `buildPreset()` público |
| 4 | `source/delegates/CustomBuilderDelegate.mc` | No `onBack` sem editing: salvar custom preset no app antes de popView |
| 5 | `source/delegates/HomeDelegate.mc` | No `onSelect` index 3: checar `app.getCustomPreset()` → startSession ou builder |
| 6 | `source/TomaApp.mc` | Adicionar `_customPreset`, `getCustomPreset()`, `setCustomPreset()` |

---

### 4.1 `source/model/Preset.mc`

**Antes:**
```monkeyc
    function formatSecondary(cyclesLabel as Lang.String) as Lang.String {
        return Lang.format("$1$ $2$", [cycles, cyclesLabel]);
    }
}
```

**Depois:**
```monkeyc
    function formatSecondary(cyclesLabel as Lang.String) as Lang.String {
        return Lang.format("$1$ $2$", [cycles, cyclesLabel]);
    }

    function getLongBreakSeconds() as Lang.Number {
        return breakMin * 60 * 3;
    }
}
```

---

### 4.2 `source/model/PomodoroModel.mc`

**Antes (L149-151):**
```monkeyc
                    _state = PomodoroState.RUNNING_LONG_BREAK;
                    _remainingSeconds = preset.breakMin * 3 * 60;
                    _totalPhaseSeconds = _remainingSeconds;
```

**Depois:**
```monkeyc
                    _state = PomodoroState.RUNNING_LONG_BREAK;
                    _remainingSeconds = preset.getLongBreakSeconds();
                    _totalPhaseSeconds = _remainingSeconds;
```

---

### 4.3 `source/views/CustomBuilderView.mc`

**Antes (final do arquivo, L147-148):**
```monkeyc
    private function _getMax() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_MAX; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_MAX; }
        return PresetLimits.CYCLES_MAX;
    }
}
```

**Depois:**
```monkeyc
    private function _getMax() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_MAX; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_MAX; }
        return PresetLimits.CYCLES_MAX;
    }

    function buildPreset() as Preset {
        return new Preset(_workMin, _breakMin, _cycles, true);
    }
}
```

---

### 4.4 `source/delegates/CustomBuilderDelegate.mc`

**Antes (L1-2):**
```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;
```

**Depois:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;
```

**Antes (L39-44, `onBack`):**
```monkeyc
    function onBack() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.cancelEdit();
        } else {
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
            app.setCustomPreset(_view.buildPreset());
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
```

---

### 4.5 `source/delegates/HomeDelegate.mc`

**Antes (L23-41, `onSelect`):**
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

**Depois:**
```monkeyc
    function onSelect() as Lang.Boolean {
        var selectedIndex = _view.getSelectedIndex();

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

---

### 4.6 `source/TomaApp.mc`

**Antes (L10-11):**
```monkeyc
    private var _counterRepo as CounterRepository;
    private var _lastPreset as Preset or Null;
```

**Depois:**
```monkeyc
    private var _counterRepo as CounterRepository;
    private var _lastPreset as Preset or Null;
    private var _customPreset as Preset or Null = null;
```

**Antes (L101-104, final do arquivo):**
```monkeyc
    function getLastPreset() as Preset or Null {
        return _lastPreset;
    }
}
```

**Depois:**
```monkeyc
    function getLastPreset() as Preset or Null {
        return _lastPreset;
    }

    function getCustomPreset() as Preset or Null {
        return _customPreset;
    }

    function setCustomPreset(preset as Preset) as Void {
        _customPreset = preset;
    }
}
```

---

## 5. Storage/Properties

Nenhum. Custom preset é armazenado apenas em memória nesta task. Persistência via Properties é task 02-07.

---

## 6. Checklist de execucao

- [x] 1. Modificar `source/model/Preset.mc` — adicionar `getLongBreakSeconds()`
- [x] 2. Modificar `source/model/PomodoroModel.mc` — substituir cálculo inline por `preset.getLongBreakSeconds()`
- [x] 3. Modificar `source/views/CustomBuilderView.mc` — adicionar `buildPreset()`
- [x] 4. Modificar `source/TomaApp.mc` — adicionar `_customPreset`, `getCustomPreset()`, `setCustomPreset()`
- [x] 5. Modificar `source/delegates/CustomBuilderDelegate.mc` — adicionar import App, salvar custom no `onBack`
- [x] 6. Modificar `source/delegates/HomeDelegate.mc` — lógica condicional no `onSelect` index 3
- [x] 7. Criar `tests/PresetsTest.mc` com 4 testes
- [x] 8. Build para fr255 — `monkeyc -d fr255`
- [x] 9. Build para fr255s — `monkeyc -d fr255s`
- [x] 10. Build para fr265 — `monkeyc -d fr265`
- [x] 11. Rodar testes — `monkeyc --unit-test`
- [ ] 12. Testar no simulador (caminho feliz)

---

## 7. Criterios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [x] `--typecheck=Strict` passa
- [x] Testes em `tests/PresetsTest.mc` passam:
  - `testBuiltinPresets` — 4 entries, valores corretos
  - `testBuiltinPresetsIsCustom` — 3 primeiros `isCustom == false`, ultimo `true`
  - `testLongBreakDuration` — preset 25/5 → 900s, preset 50/10 → 1800s
  - `testFormatMethods` — formatPrimary/formatSecondary retornam strings esperadas

### Manual (simulador)
- [ ] Selecionar preset 25/5 → TimerView abre com 25:00, anel work, 4 pills com primeiro highlighted
- [ ] Selecionar preset 30/5 → 30:00
- [ ] Selecionar preset 50/10 → 50:00
- [ ] Custom (nunca editado) → abre CustomBuilderView
- [ ] Editar Custom (ex: 40/8/3), dar Back → volta ao Home
- [ ] Selecionar Custom de novo → TimerView roda com 40:00
- [ ] Long break com preset 25/5 dura 15:00 (verificar no debug ou acelerando timer)

---

## 8. Out of scope

- Persistir custom preset em Properties (task 02-07)
- Persistir `lastSelectedPreset` (task 02-08)
- Path de re-edição do custom após configurado (futuro — via Settings ou long-press)
- Múltiplos custom presets (V2)
