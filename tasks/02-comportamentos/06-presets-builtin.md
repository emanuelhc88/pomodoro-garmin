# Task 02-06: Presets Builtin

## Objetivo

Consolidar os 4 presets builtin como **constantes do código**, garantindo que P1 (Home) lista corretamente os 3 builtins + Custom + Settings, e que B1 (iniciar sessão a partir de preset) está totalmente integrado: usuário escolhe preset → Model armado → Timer roda.

A maior parte do trabalho já foi feita em tasks anteriores (`01-05`, `02-02`). Esta task **fecha o ciclo** garantindo que tudo conecta corretamente e adiciona testes.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B1** Iniciar sessão a partir de preset — `spec/spec.md` §4.B1

## Dependências

- `tasks/01-prototipos-visuais/05-tela-presets.md`.
- `tasks/02-comportamentos/02-timer-loop.md`.
- `tasks/02-comportamentos/04-pausa-resume-stop.md`.

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets.
- [ ] `--typecheck=Strict` passa.
- [ ] Testes em `tests/PresetsTest.mc`:
  - `Presets.builtinList()` retorna 3 presets builtin com valores corretos.
  - Cada preset tem `isCustom == false` exceto o último.
  - `formatPrimary()` e `formatSecondary()` retornam strings esperadas.

### Manual

- [ ] Selecionar preset 25/5 em Home → TimerView abre com 25:00, anel work, 4 pills com primeiro highlighted.
- [ ] Selecionar preset 30/5 → 30:00.
- [ ] Selecionar preset 50/10 → 50:00.
- [ ] Custom preset abre `CustomBuilderView`, não TimerView (a menos que já configurado).
- [ ] Após editar Custom (ainda sem persistência real, OK), selecionar Custom no Home → TimerView roda com valores editados.

## Arquivos esperados

### Novos

- `tests/PresetsTest.mc`.

### Modificados

- `source/model/Preset.mc` — finalizar `Presets.builtinList()` se não estiver completo.
- `source/delegates/HomeDelegate.mc` — `onSelect` despacha:
  - Se `preset.isCustom`: pushView `CustomBuilderView`.
  - Senão: chama `app.startSession(preset)`.
- `source/views/HomeView.mc` — usar `Presets.builtinList()` consistentemente.

## Referências obrigatórias

- `spec/spec.md` §4.B1, §6.
- `references/architecture.md` §3 (Model design).

## Especificação técnica

### Presets.builtinList() final

```monkeyc
module Presets {
    function builtinList() as Array<Preset> {
        return [
            new Preset(25, 5, 4, false),   // Pomodoro clássico
            new Preset(30, 5, 4, false),   // Variação 30/5
            new Preset(50, 10, 4, false),  // Pomodoro estendido (Deep Work-style)
            // Custom preset é loaded de Properties em runtime — aqui retorna defaults.
            new Preset(25, 5, 4, true)
        ];
    }

    function customPreset(workMin, breakMin, cycles) as Preset {
        return new Preset(workMin, breakMin, cycles, true);
    }
}
```

### HomeDelegate.onSelect

```monkeyc
function onSelect() as Boolean {
    var presets = Presets.builtinList();
    if (_selectedIndex < presets.size()) {
        var preset = presets[_selectedIndex];
        if (preset.isCustom) {
            // Carregar valores reais de Properties (após task 02-08)
            // Nesta task, ainda usar defaults se Properties não disponível.
            Ui.pushView(new CustomBuilderView(), new CustomBuilderDelegate(_app), Ui.SLIDE_LEFT);
        } else {
            _app.startSession(preset);
        }
    } else if (_selectedIndex == presets.size()) {
        // Settings
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(_app), Ui.SLIDE_UP);
    }
    return true;
}
```

### Long break duration

Esta task **deve resolver definitivamente** a decisão pendente da task `02-01` sobre duração do long break.

**Decisão recomendada V1:** `longBreakMin = breakMin * 3`. Para os 3 presets builtin:
- 25/5/4 → long break = 15 min
- 30/5/4 → long break = 15 min
- 50/10/4 → long break = 30 min

Implementar em `Preset.mc`:
```monkeyc
class Preset {
    function getLongBreakSeconds() as Number {
        return breakMin * 60 * 3;
    }
}
```

`PomodoroModel._transitionPhase()` usa `_preset.getLongBreakSeconds()` quando entra em long break.

### Testes

```monkeyc
(:test)
function testBuiltinPresets(logger as Test.Logger) as Boolean {
    var presets = Presets.builtinList();
    Test.assertEqualMessage(4, presets.size(), "should have 4 entries");
    Test.assertEqualMessage(25, presets[0].workMin, "first is 25 min");
    Test.assertEqualMessage(false, presets[0].isCustom, "first is not custom");
    Test.assertEqualMessage(true, presets[3].isCustom, "fourth is custom placeholder");
    return true;
}

(:test)
function testLongBreakDuration(logger as Test.Logger) as Boolean {
    var p = new Preset(25, 5, 4, false);
    Test.assertEqualMessage(900, p.getLongBreakSeconds(), "long break = 5*60*3 = 900s");
    return true;
}
```

## Out of scope desta task

- Persistir Custom (próxima — `02-07`).
- Persistir lastSelectedPreset (`02-08`).
- Múltiplos custom presets (V2).
