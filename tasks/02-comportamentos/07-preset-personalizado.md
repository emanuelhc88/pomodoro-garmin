# Task 02-07: Preset Personalizado (persistência)

## Objetivo

Implementar persistência completa do preset Custom: valores editados em `CustomBuilderView` (P2) são salvos em `Application.Properties` e carregados ao abrir o app. Iniciar sessão com Custom usa os valores persistidos.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B2** Construir preset personalizado — `spec/spec.md` §4.B2 (parte de persistência)

## Dependências

- `tasks/01-prototipos-visuais/06-tela-personalizado.md` (UI do Custom Builder existe).
- `tasks/02-comportamentos/06-presets-builtin.md` (struct Preset existe).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings, `--typecheck=Strict` passa.
- [ ] Testes em `tests/PresetRepositoryTest.mc`:
  - Get inicial retorna defaults (25/5/4) se nada foi salvo.
  - Save persiste e Get subsequente retorna valores salvos.
  - Valores fora de range são clamp-ed (se input externo passar inválido).

### Manual

- [ ] Editar Custom em P2 (mudar work para 45 min, break para 8 min, cycles para 5).
- [ ] Voltar para Home (P1).
- [ ] Selecionar Custom novamente — P2 mostra os valores editados (45/8/5), não os defaults.
- [ ] Iniciar sessão com Custom → TimerView roda com 45:00 (não 25:00).
- [ ] Fechar e reabrir app → Custom mantém os valores salvos.

## Arquivos esperados

### Novos

- `source/repositories/PresetRepository.mc` — leitura/escrita do Custom em Properties.
- `tests/PresetRepositoryTest.mc`.

### Modificados

- `source/views/CustomBuilderView.mc` — carregar valores iniciais de `PresetRepository.loadCustom()`.
- `source/delegates/CustomBuilderDelegate.mc` — ao confirmar (Back em navigation mode), chamar `PresetRepository.saveCustom(preset)`.
- `source/delegates/HomeDelegate.mc` — para preset Custom selecionado em P1, sessão usa `PresetRepository.loadCustom()` em vez do default.
- `source/model/Preset.mc` — adicionar validações se necessário (clamp de valores).

## Referências obrigatórias

- `references/architecture.md` §3 (Repository pattern).
- `references/garmin_platform.md` §2.3 (Properties).
- `spec/spec.md` §4.B2, §6 (limites Custom).

## Especificação técnica

### Properties keys

```
customWorkMin    : Number, default 25, range 5-90
customBreakMin   : Number, default 5,  range 1-30
customCycles     : Number, default 4,  range 1-10
```

### PresetRepository API

```monkeyc
using Toybox.Application as App;

class PresetRepository {
    function loadCustom() as Preset {
        var work = _getOr("customWorkMin", 25);
        var brk = _getOr("customBreakMin", 5);
        var cycles = _getOr("customCycles", 4);
        return new Preset(_clampWork(work), _clampBreak(brk), _clampCycles(cycles), true);
    }

    function saveCustom(preset as Preset) as Void {
        App.Properties.setValue("customWorkMin", _clampWork(preset.workMin));
        App.Properties.setValue("customBreakMin", _clampBreak(preset.breakMin));
        App.Properties.setValue("customCycles", _clampCycles(preset.cycles));
    }

    private function _getOr(key as String, default as Number) as Number {
        var v = App.Properties.getValue(key);
        return v == null ? default : v as Number;
    }

    private function _clampWork(v as Number) as Number {
        return v.max(5).min(90);
    }

    private function _clampBreak(v as Number) as Number {
        return v.max(1).min(30);
    }

    private function _clampCycles(v as Number) as Number {
        return v.max(1).min(10);
    }
}
```

**Nota Monkey C:** `Number.max` e `Number.min` clamp invertido — `v.max(5)` retorna `max(v, 5)` (lower bound), `v.min(90)` retorna `min(v, 90)` (upper bound). Verificar API exata.

### settings.xml — exposição via Garmin Connect mobile (V1.x ou V2)

Como bonus, expor as settings via Garmin Connect mobile permite o usuário editar Custom pelo celular sem precisar de menu confuso no relógio. Isso requer arquivos:
- `resources/settings/settings.xml` — UI declarativa.
- `resources/settings/properties.xml` — defaults.

**Decisão V1:** **não** implementar settings via mobile nesta task. Foca em editing via P2 no relógio. Se sobrar tempo no final do projeto, adicionar como V1.0.1.

### CustomBuilderDelegate — save no confirm

```monkeyc
function onBack() as Boolean {
    if (_view.isEditing()) {
        // Cancela edição da linha atual
        _view.cancelEdit();
    } else {
        // Salva e volta
        var preset = _view.buildPreset();
        _presetRepo.saveCustom(preset);
        Ui.popView(Ui.SLIDE_RIGHT);
    }
    return true;
}
```

## Out of scope desta task

- Múltiplos custom presets (V2).
- Settings Garmin Connect mobile (V1.x).
