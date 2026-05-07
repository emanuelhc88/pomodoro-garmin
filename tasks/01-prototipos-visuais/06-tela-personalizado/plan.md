# Plan — Task 01-06: Tela Custom Builder

> Spec Tatica gerada na FASE 2.3. Executar com `/execute` na proxima sessao.

---

## 1. Resumo

Implementar a pagina P2 (Custom Builder): 3 linhas editaveis (WORK, BREAK, CYCLES) com navegacao Up/Down, modo edicao via Enter, e 2 novos componentes reutilizaveis (SpecLine, Hints). Integrar com HomeDelegate para que o preset Custom (indice 3) abra esta tela.

---

## 2. Cenarios

### Caminho feliz

1. Usuario esta na Home (P1) com preset Custom selecionado (indice 3).
2. Pressiona Enter → pushView para CustomBuilderView.
3. Ve 3 linhas: WORK 25 min, BREAK 5 min, CYCLES 4. Primeira linha selecionada (cor ACCENT).
4. Pressiona Down → selecao move para BREAK.
5. Pressiona Enter → entra em edit mode (cor muda para BRAND, hints mudam).
6. Pressiona Up → valor incrementa (BREAK: 5 → 6).
7. Pressiona Enter → confirma, volta para modo navigating.
8. Pressiona Back → popView, volta para Home.

### Edge cases

- **Clamp nos limites:** Up em WORK=90 mantem 90; Down em WORK=5 mantem 5. Idem para BREAK (1-30) e CYCLES (1-10).
- **Wrap na navegacao:** Up em linha 0 (WORK) vai para linha 2 (CYCLES). Down em linha 2 vai para linha 0.
- **Back em edit mode:** restaura valor anterior (backup) e volta para navigating sem sair da tela.
- **Small bucket (218x218):** titulo "Custom" oculto; hints em FONT_XTINY.

### Erros

- **Triangulos Unicode nao renderizam:** fallback em SpecLine — se nao renderizar, o valor aparece sem setas (apenas cor BRAND indica edicao). Testar no simulador.
- **Touch em device sem touch:** `onTap` nao e chamado; inputs fisicos funcionam normalmente via BehaviorDelegate.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/ui/components/SpecLine.mc` | Modulo stateless: renderiza uma linha "LABEL valor unidade" com highlight condicional |
| 2 | `source/ui/components/Hints.mc` | Modulo stateless: renderiza texto de hint no rodape |
| 3 | `source/views/CustomBuilderView.mc` | View P2: mantem estado local, renderiza titulo + 3 SpecLines + Hints |
| 4 | `source/delegates/CustomBuilderDelegate.mc` | Delegate P2: interpreta inputs conforme modo (navigating/editing) |

### 3.1 `source/ui/components/SpecLine.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module SpecLine {
    function draw(
        dc as Gfx.Dc,
        x as Lang.Number,
        y as Lang.Number,
        w as Lang.Number,
        h as Lang.Number,
        label as Lang.String,
        value as Lang.Number,
        unit as Lang.String,
        isSelected as Lang.Boolean,
        isEditing as Lang.Boolean,
        bucket as Lang.Symbol
    ) as Void {
        var labelFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        var valueFont = (bucket == :small) ? Gfx.FONT_MEDIUM : Gfx.FONT_NUMBER_MEDIUM;
        var centerY = y + h / 2;

        if (isSelected || isEditing) {
            var highlightColor = isEditing ? Colors.BRAND : Colors.ACCENT;
            dc.setColor(highlightColor, highlightColor);
            dc.fillRectangle(x, y, w, h);
        }

        var labelColor = (isSelected || isEditing) ? Colors.TEXT_PRIMARY : Colors.TEXT_MUTED;
        dc.setColor(labelColor, Gfx.COLOR_TRANSPARENT);
        var labelX = x + 12;
        dc.drawText(labelX, centerY, labelFont, label, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        var valueColor = (isSelected || isEditing) ? Colors.TEXT_PRIMARY : Colors.TEXT_MUTED;
        dc.setColor(valueColor, Gfx.COLOR_TRANSPARENT);
        var valueX = x + w - 12;
        var valueStr = "";
        if (unit.length() > 0) {
            valueStr = Lang.format("$1$ $2$", [value, unit]);
        } else {
            valueStr = value.toString();
        }
        dc.drawText(valueX, centerY, valueFont, valueStr, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}
```

### 3.2 `source/ui/components/Hints.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module Hints {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        text as Lang.String,
        bucket as Lang.Symbol
    ) as Void {
        var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}
```

### 3.3 `source/views/CustomBuilderView.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

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
        _titleStr = Ui.loadResource(Rez.Strings.custom_builder_title) as Lang.String;
        _labelWork = Ui.loadResource(Rez.Strings.custom_label_work) as Lang.String;
        _labelBreak = Ui.loadResource(Rez.Strings.custom_label_break) as Lang.String;
        _labelCycles = Ui.loadResource(Rez.Strings.custom_label_cycles) as Lang.String;
        _unitMin = Ui.loadResource(Rez.Strings.unit_min) as Lang.String;
        _hintsNav = Ui.loadResource(Rez.Strings.hints_nav) as Lang.String;
        _hintsEdit = Ui.loadResource(Rez.Strings.hints_edit) as Lang.String;
    }

    function getSelectedLine() as Lang.Number {
        return _selectedLine;
    }

    function isEditing() as Lang.Boolean {
        return _editing;
    }

    function moveUp() as Void {
        _selectedLine = (_selectedLine - 1 + 3) % 3;
        Ui.requestUpdate();
    }

    function moveDown() as Void {
        _selectedLine = (_selectedLine + 1) % 3;
        Ui.requestUpdate();
    }

    function enterEdit() as Void {
        _editStartValue = _getCurrentValue();
        _editing = true;
        Ui.requestUpdate();
    }

    function confirmEdit() as Void {
        _editing = false;
        Ui.requestUpdate();
    }

    function cancelEdit() as Void {
        _setCurrentValue(_editStartValue);
        _editing = false;
        Ui.requestUpdate();
    }

    function incrementValue() as Void {
        var val = _getCurrentValue();
        var step = _getStep();
        var max = _getMax();
        val = val + step;
        if (val > max) { val = max; }
        _setCurrentValue(val);
        Ui.requestUpdate();
    }

    function decrementValue() as Void {
        var val = _getCurrentValue();
        var step = _getStep();
        var min = _getMin();
        val = val - step;
        if (val < min) { val = min; }
        _setCurrentValue(val);
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var lineH = Dimensions.customLineHeight(bucket);
        var line1Y = Dimensions.customLine1Y(bucket);
        var lineSpacing = Dimensions.customLineSpacing(bucket);
        var hintsY = Dimensions.customHintsY(bucket);
        var lineW = w * 80 / 100;
        var lineX = (w - lineW) / 2;

        if (bucket != :small) {
            var titleY = Dimensions.customTitleY(bucket);
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, titleY, Gfx.FONT_TINY, _titleStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var line2Y = line1Y + lineH + lineSpacing;
        var line3Y = line2Y + lineH + lineSpacing;

        SpecLine.draw(dc, lineX, line1Y, lineW, lineH, _labelWork, _workMin, _unitMin, _selectedLine == 0 && !_editing, _selectedLine == 0 && _editing, bucket);
        SpecLine.draw(dc, lineX, line2Y, lineW, lineH, _labelBreak, _breakMin, _unitMin, _selectedLine == 1 && !_editing, _selectedLine == 1 && _editing, bucket);
        SpecLine.draw(dc, lineX, line3Y, lineW, lineH, _labelCycles, _cycles, "", _selectedLine == 2 && !_editing, _selectedLine == 2 && _editing, bucket);

        var hintText = _editing ? _hintsEdit : _hintsNav;
        Hints.draw(dc, centerX, hintsY, hintText, bucket);
    }

    private function _getCurrentValue() as Lang.Number {
        if (_selectedLine == 0) { return _workMin; }
        if (_selectedLine == 1) { return _breakMin; }
        return _cycles;
    }

    private function _setCurrentValue(val as Lang.Number) as Void {
        if (_selectedLine == 0) { _workMin = val; }
        else if (_selectedLine == 1) { _breakMin = val; }
        else { _cycles = val; }
    }

    private function _getStep() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_STEP; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_STEP; }
        return PresetLimits.CYCLES_STEP;
    }

    private function _getMin() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_MIN; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_MIN; }
        return PresetLimits.CYCLES_MIN;
    }

    private function _getMax() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_MAX; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_MAX; }
        return PresetLimits.CYCLES_MAX;
    }
}
```

### 3.4 `source/delegates/CustomBuilderDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class CustomBuilderDelegate extends Ui.BehaviorDelegate {
    private var _view as CustomBuilderView;

    function initialize(view as CustomBuilderView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.incrementValue();
        } else {
            _view.moveUp();
        }
        return true;
    }

    function onNextPage() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.decrementValue();
        } else {
            _view.moveDown();
        }
        return true;
    }

    function onSelect() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.confirmEdit();
        } else {
            _view.enterEdit();
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.cancelEdit();
        } else {
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
}
```

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/model/Preset.mc` | Adicionar module `PresetLimits` com constantes |
| 2 | `source/ui/layout/Dimensions.mc` | Adicionar 7 funcoes para layout do CustomBuilder |
| 3 | `source/delegates/HomeDelegate.mc` | Condicionar onSelect: indice 3 abre CustomBuilder |
| 4 | `resources/strings/strings.xml` | Adicionar 7 strings EN |
| 5 | `resources-por/strings/strings.xml` | Adicionar 7 strings PT |

### 4.1 `source/model/Preset.mc`

**Antes:**
```monkeyc
module Presets {
    function builtinList() as Lang.Array<Preset> {
        return [
            new Preset(25, 5, 4, false),
            new Preset(30, 5, 4, false),
            new Preset(50, 10, 4, false),
            new Preset(25, 5, 4, true)
        ];
    }
}
```

**Depois:**
```monkeyc
module PresetLimits {
    const WORK_MIN = 5;
    const WORK_MAX = 90;
    const WORK_STEP = 5;
    const BREAK_MIN = 1;
    const BREAK_MAX = 30;
    const BREAK_STEP = 1;
    const CYCLES_MIN = 1;
    const CYCLES_MAX = 10;
    const CYCLES_STEP = 1;
}

module Presets {
    function builtinList() as Lang.Array<Preset> {
        return [
            new Preset(25, 5, 4, false),
            new Preset(30, 5, 4, false),
            new Preset(50, 10, 4, false),
            new Preset(25, 5, 4, true)
        ];
    }
}
```

### 4.2 `source/ui/layout/Dimensions.mc`

**Adicionar ao final do module (antes do `}` final):**

```monkeyc
    function customTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :large) { return 40; }
        return 25;
    }

    function customLineHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 38; }
        if (bucket == :large) { return 70; }
        return 48;
    }

    function customLine1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 40; }
        if (bucket == :large) { return 90; }
        return 60;
    }

    function customLineSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 4; }
        if (bucket == :large) { return 12; }
        return 8;
    }

    function customHintsY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 170; }
        if (bucket == :large) { return 360; }
        return 210;
    }
```

### 4.3 `source/delegates/HomeDelegate.mc`

**Antes (onSelect inteiro):**
```monkeyc
    function onSelect() as Lang.Boolean {
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

### 4.4 `resources/strings/strings.xml`

**Antes (final do arquivo):**
```xml
    <string id="start_again">Start again</string>
    <string id="done">Done</string>
</resources>
```

**Depois:**
```xml
    <string id="start_again">Start again</string>
    <string id="done">Done</string>
    <string id="custom_builder_title">Custom</string>
    <string id="custom_label_work">WORK</string>
    <string id="custom_label_break">BREAK</string>
    <string id="custom_label_cycles">CYCLES</string>
    <string id="unit_min">min</string>
    <string id="hints_nav">SELECT to edit</string>
    <string id="hints_edit">SELECT to confirm</string>
</resources>
```

### 4.5 `resources-por/strings/strings.xml`

**Antes (final do arquivo):**
```xml
    <string id="start_again">Recomeçar</string>
    <string id="done">Pronto</string>
</resources>
```

**Depois:**
```xml
    <string id="start_again">Recomeçar</string>
    <string id="done">Pronto</string>
    <string id="custom_builder_title">Personalizado</string>
    <string id="custom_label_work">FOCO</string>
    <string id="custom_label_break">PAUSA</string>
    <string id="custom_label_cycles">CICLOS</string>
    <string id="unit_min">min</string>
    <string id="hints_nav">SELECT p/ editar</string>
    <string id="hints_edit">SELECT p/ confirmar</string>
</resources>
```

---

## 5. Storage/Properties

Nao aplicavel nesta task. Persistencia fica para task 02-08.

---

## 6. Checklist de execucao

- [x] 1. Criar `source/ui/components/SpecLine.mc` (codigo da secao 3.1)
- [x] 2. Criar `source/ui/components/Hints.mc` (codigo da secao 3.2)
- [x] 3. Modificar `source/model/Preset.mc` — adicionar module `PresetLimits` (secao 4.1)
- [x] 4. Modificar `source/ui/layout/Dimensions.mc` — adicionar 5 funcoes custom* (secao 4.2)
- [x] 5. Modificar `resources/strings/strings.xml` — adicionar 7 strings EN (secao 4.4)
- [x] 6. Modificar `resources-por/strings/strings.xml` — adicionar 7 strings PT (secao 4.5)
- [x] 7. Criar `source/views/CustomBuilderView.mc` (codigo da secao 3.3)
- [x] 8. Criar `source/delegates/CustomBuilderDelegate.mc` (codigo da secao 3.4)
- [x] 9. Modificar `source/delegates/HomeDelegate.mc` — condicionar onSelect para indice 3 (secao 4.3)
- [x] 10. Build e validar compilacao

---

## 7. Criterios de aceite

### Automated

- [x] Compila sem erros (monkeyc)
- [x] `--typecheck=Strict` passa

### Manual (simulador)

- [ ] Tela mostra 3 linhas: WORK 25 min, BREAK 5 min, CYCLES 4
- [ ] Up/Down navega entre linhas com highlight ACCENT
- [ ] Enter entra em edit mode (highlight muda para BRAND)
- [ ] Em edit mode, Up/Down ajusta valor com step correto (WORK ±5, BREAK ±1, CYCLES ±1)
- [ ] Valores sao clamped nos limites (WORK 5-90, BREAK 1-30, CYCLES 1-10)
- [ ] Enter em edit mode confirma e volta ao navigating
- [ ] Back em edit mode cancela (restaura valor anterior)
- [ ] Back em navigating volta para Home (P1)
- [ ] Hints no rodape mudam conforme contexto (nav vs edit)
- [ ] Layout cabe no small bucket (FR255S) — sem titulo, 3 linhas + hints visiveis
- [ ] No medium bucket (FR255) titulo "Custom" aparece no topo
- [ ] Na Home, selecionar preset Custom (indice 3) abre CustomBuilderView
- [ ] Na Home, outros presets continuam abrindo demo (TimerView etc)

---

## 8. Out of scope

- Persistencia dos valores (task 02-08)
- Touch/tap para selecionar linha (pode ser adicionado depois; esta task foca nos inputs fisicos)
- Setas Unicode no valor em edicao (decisao D2 — implementar se sobrar tempo, nao e blocker)
- Validacao com mensagens de erro UI (apenas clamp silencioso)
- Navegacao entre Custom Builder e Timer (nesta task Custom Builder e terminal — Back volta para Home)
