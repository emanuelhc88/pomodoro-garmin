# Plan — Task 01-03: Tela Pausa (Paused state)

> Spec Tatica gerada na FASE 2.3. Executar com `/execute` na proxima sessao.

---

## 1. Resumo

Adicionar estado visual "paused" ao `TimerView` existente. Quando `isPaused == true`, o anel usa cor dim, display e phase label ficam em `textMuted`, e uma label "PAUSED" aparece abaixo do timer. Demo acessivel via 4o clique no HomeDelegate.

---

## 2. Cenarios

### Caminho feliz
1. Usuario abre o app (HomeView).
2. Pressiona Enter 4 vezes (idx=3 no demo array).
3. TimerView abre com `isPaused=true`, fase `:running_work`.
4. Anel aparece em `BRAND_DIM` (vermelho escurecido).
5. Display "15:00" em cor `TEXT_MUTED`.
6. Phase label "FOCUS" em cor `TEXT_MUTED`.
7. Label "PAUSED" aparece abaixo do display em `FONT_TINY`, cor `TEXT_MUTED`.
8. Session pills permanecem visiveis e inalteradas.

### Edge cases
- Bucket small (218px): label "PAUSED" usa `FONT_XTINY` e offset menor (30px) para nao sobrepor pills.
- Phase `:running_short_break` pausada: anel usa `TEXT_MUTED_DIM` (distinto do `TEXT_MUTED` normal).
- Phase `:running_long_break` pausada: anel usa `ACCENT_DIM`.

### Erros
- Nenhum erro runtime possivel — tudo e render estatico com valores hardcoded.

---

## 3. Arquivos a CRIAR

Nenhum arquivo novo.

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/ui/layout/Colors.mc` | Adicionar 3 constantes dim |
| 2 | `source/ui/layout/Dimensions.mc` | Adicionar `pausedLabelOffsetY(bucket)` |
| 3 | `source/ui/components/TimerDisplay.mc` | Adicionar parametro `color` ao `draw()` |
| 4 | `source/views/TimerView.mc` | Adicionar `isPaused`, condicionar cores, render label |
| 5 | `source/delegates/HomeDelegate.mc` | Adicionar 4o estado demo (paused) |
| 6 | `resources/strings/strings.xml` | Adicionar `state_paused` |

---

### 4.1 `source/ui/layout/Colors.mc`

**Antes:**
```monkeyc
module Colors {
    const BG = 0x0C0C0C;
    const BRAND = 0xE8432D;
    const ACCENT = 0xFF6B47;
    const TEXT_PRIMARY = 0xF5F0EB;
    const TEXT_MUTED = 0x888888;
    const BORDER = 0x2A2A2A;
}
```

**Depois:**
```monkeyc
module Colors {
    const BG = 0x0C0C0C;
    const BRAND = 0xE8432D;
    const ACCENT = 0xFF6B47;
    const TEXT_PRIMARY = 0xF5F0EB;
    const TEXT_MUTED = 0x888888;
    const BORDER = 0x2A2A2A;

    const BRAND_DIM = 0x6E2017;
    const ACCENT_DIM = 0x803624;
    const TEXT_MUTED_DIM = 0x444444;
}
```

---

### 4.2 `source/ui/layout/Dimensions.mc`

**Adicionar ao final do module (antes do `}` final):**

```monkeyc
    function pausedLabelOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 30; }
        if (bucket == :large) { return 60; }
        return 35;
    }
```

---

### 4.3 `source/ui/components/TimerDisplay.mc`

**Antes:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module TimerDisplay {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        remainingSeconds as Lang.Number,
        bucket as Lang.Symbol
    ) as Void {
        var minutes = remainingSeconds / 60;
        var seconds = remainingSeconds % 60;
        var text = Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")]);

        var font = (bucket == :small) ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_THAI_HOT;
        var fontHeight = Gfx.getFontHeight(font);
        var y = centerY - fontHeight / 2;

        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module TimerDisplay {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        remainingSeconds as Lang.Number,
        bucket as Lang.Symbol,
        color as Lang.Number
    ) as Void {
        var minutes = remainingSeconds / 60;
        var seconds = remainingSeconds % 60;
        var text = Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")]);

        var font = (bucket == :small) ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_THAI_HOT;
        var fontHeight = Gfx.getFontHeight(font);
        var y = centerY - fontHeight / 2;

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}
```

---

### 4.4 `source/views/TimerView.mc`

**Antes (arquivo inteiro):**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerView extends Ui.View {
    private var _phase as Lang.Symbol;
    private var _remaining as Lang.Number;
    private var _total as Lang.Number;
    private var _completedCycles as Lang.Number;
    private var _totalCycles as Lang.Number;

    function initialize(
        phase as Lang.Symbol,
        remaining as Lang.Number,
        total as Lang.Number,
        completedCycles as Lang.Number,
        totalCycles as Lang.Number
    ) {
        View.initialize();
        _phase = phase;
        _remaining = remaining;
        _total = total;
        _completedCycles = completedCycles;
        _totalCycles = totalCycles;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var centerY = Dimensions.timerCenterY(bucket, h);
        var radius = Dimensions.ringRadius(bucket);
        var stroke = Dimensions.ringStroke(bucket);
        var labelOffsetY = Dimensions.phaseLabelOffsetY(bucket);
        var pOffsetY = Dimensions.pillsOffsetY(bucket);
        var pSize = Dimensions.pillSize(bucket);
        var pSpacing = Dimensions.pillSpacing(bucket);

        var phaseColor = getPhaseColor();
        var phaseText = getPhaseText();
        var progress = (_total - _remaining).toFloat() / _total.toFloat();

        var labelY = centerY + labelOffsetY;
        PhaseLabel.draw(dc, centerX, labelY, phaseText, phaseColor, bucket);

        TimerRing.draw(dc, centerX, centerY, radius, stroke, progress, phaseColor);

        TimerDisplay.draw(dc, centerX, centerY, _remaining, bucket);

        var pillsY = centerY + pOffsetY;
        SessionPills.draw(dc, centerX, pillsY, _totalCycles, _completedCycles, pSize, pSpacing);
    }

    private function getPhaseColor() as Lang.Number {
        if (_phase == :running_work) { return Colors.BRAND; }
        if (_phase == :running_short_break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

    private function getPhaseText() as Lang.String {
        if (_phase == :running_work) { return "FOCUS"; }
        if (_phase == :running_short_break) { return "BREAK"; }
        return "LONG BREAK";
    }
}
```

**Depois (arquivo inteiro):**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerView extends Ui.View {
    private var _phase as Lang.Symbol;
    private var _remaining as Lang.Number;
    private var _total as Lang.Number;
    private var _completedCycles as Lang.Number;
    private var _totalCycles as Lang.Number;
    private var _isPaused as Lang.Boolean;
    private var _pausedText as Lang.String;

    function initialize(
        phase as Lang.Symbol,
        remaining as Lang.Number,
        total as Lang.Number,
        completedCycles as Lang.Number,
        totalCycles as Lang.Number,
        isPaused as Lang.Boolean
    ) {
        View.initialize();
        _phase = phase;
        _remaining = remaining;
        _total = total;
        _completedCycles = completedCycles;
        _totalCycles = totalCycles;
        _isPaused = isPaused;
        _pausedText = Ui.loadResource(Rez.Strings.state_paused) as Lang.String;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var centerY = Dimensions.timerCenterY(bucket, h);
        var radius = Dimensions.ringRadius(bucket);
        var stroke = Dimensions.ringStroke(bucket);
        var labelOffsetY = Dimensions.phaseLabelOffsetY(bucket);
        var pOffsetY = Dimensions.pillsOffsetY(bucket);
        var pSize = Dimensions.pillSize(bucket);
        var pSpacing = Dimensions.pillSpacing(bucket);

        var ringColor = _isPaused ? getDimColor() : getPhaseColor();
        var displayColor = _isPaused ? Colors.TEXT_MUTED : Colors.TEXT_PRIMARY;
        var labelColor = _isPaused ? Colors.TEXT_MUTED : getPhaseColor();
        var phaseText = getPhaseText();
        var progress = (_total - _remaining).toFloat() / _total.toFloat();

        var labelY = centerY + labelOffsetY;
        PhaseLabel.draw(dc, centerX, labelY, phaseText, labelColor, bucket);

        TimerRing.draw(dc, centerX, centerY, radius, stroke, progress, ringColor);

        TimerDisplay.draw(dc, centerX, centerY, _remaining, bucket, displayColor);

        if (_isPaused) {
            var pausedY = centerY + Dimensions.pausedLabelOffsetY(bucket);
            var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, pausedY, font, _pausedText, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var pillsY = centerY + pOffsetY;
        SessionPills.draw(dc, centerX, pillsY, _totalCycles, _completedCycles, pSize, pSpacing);
    }

    private function getPhaseColor() as Lang.Number {
        if (_phase == :running_work) { return Colors.BRAND; }
        if (_phase == :running_short_break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

    private function getDimColor() as Lang.Number {
        if (_phase == :running_work) { return Colors.BRAND_DIM; }
        if (_phase == :running_short_break) { return Colors.TEXT_MUTED_DIM; }
        return Colors.ACCENT_DIM;
    }

    private function getPhaseText() as Lang.String {
        if (_phase == :running_work) { return "FOCUS"; }
        if (_phase == :running_short_break) { return "BREAK"; }
        return "LONG BREAK";
    }
}
```

---

### 4.5 `source/delegates/HomeDelegate.mc`

**Antes:**
```monkeyc
    function onSelect() as Lang.Boolean {
        var phases = [:running_work, :running_short_break, :running_long_break];
        var remaining = [900, 180, 420];
        var totals = [1500, 300, 600];
        var completed = [2, 2, 3];

        var idx = _demoIdx % 3;
        Ui.pushView(
            new TimerView(phases[idx], remaining[idx], totals[idx], completed[idx], 4),
            new TimerDelegate(),
            Ui.SLIDE_LEFT
        );
        _demoIdx++;
        return true;
    }
```

**Depois:**
```monkeyc
    function onSelect() as Lang.Boolean {
        var phases = [:running_work, :running_short_break, :running_long_break, :running_work];
        var remaining = [900, 180, 420, 900];
        var totals = [1500, 300, 600, 1500];
        var completed = [2, 2, 3, 2];
        var paused = [false, false, false, true];

        var idx = _demoIdx % 4;
        Ui.pushView(
            new TimerView(phases[idx], remaining[idx], totals[idx], completed[idx], 4, paused[idx]),
            new TimerDelegate(),
            Ui.SLIDE_LEFT
        );
        _demoIdx++;
        return true;
    }
```

---

### 4.6 `resources/strings/strings.xml`

**Antes:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d cycles</string>
    <string id="settings_label">Settings</string>
    <string id="phase_focus">FOCUS</string>
    <string id="phase_break">BREAK</string>
    <string id="phase_long_break">LONG BREAK</string>
</resources>
```

**Depois:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d cycles</string>
    <string id="settings_label">Settings</string>
    <string id="phase_focus">FOCUS</string>
    <string id="phase_break">BREAK</string>
    <string id="phase_long_break">LONG BREAK</string>
    <string id="state_paused">PAUSED</string>
</resources>
```

---

## 5. Storage/Properties

Nao aplicavel. Nenhuma persistencia nesta task.

---

## 6. Checklist de execucao

- [x] 1. Editar `source/ui/layout/Colors.mc` — adicionar `BRAND_DIM`, `ACCENT_DIM`, `TEXT_MUTED_DIM`
- [x] 2. Editar `source/ui/layout/Dimensions.mc` — adicionar `pausedLabelOffsetY(bucket)`
- [x] 3. Editar `source/ui/components/TimerDisplay.mc` — adicionar param `color`
- [x] 4. Editar `source/views/TimerView.mc` — adicionar `isPaused`, `_pausedText`, condicionar cores, render label
- [x] 5. Editar `source/delegates/HomeDelegate.mc` — expandir demo para 4 estados
- [x] 6. Editar `resources/strings/strings.xml` — adicionar `state_paused`
- [x] 7. Build para fr255 (bucket small, MIP)
- [x] 8. Build para fr265 (bucket large, AMOLED)
- [ ] 9. Testar no simulador — estados 1-3 (running) inalterados
- [ ] 10. Testar no simulador — estado 4 (paused): anel dim, display muted, label PAUSED visivel
- [ ] 11. Validar que label PAUSED nao sobrepoe pills em bucket small

---

## 7. Criterios de aceite

### Automated
- [x] `monkeyc` compila sem erros para device bucket small (ex: fr255s)
- [x] `monkeyc` compila sem erros para device bucket medium (ex: fr255)
- [x] `monkeyc` compila sem erros para device bucket large (ex: fr265)
- [x] `--typecheck=Strict` passa

### Manual (simulador)
- [ ] Estados 1-3 (running work/short break/long break) renderizam identico ao antes
- [ ] Estado 4 (paused work): anel em vermelho escurecido (`BRAND_DIM`), display em cinza (`TEXT_MUTED`), phase label "FOCUS" em cinza
- [ ] Label "PAUSED" aparece abaixo do display, fonte `FONT_TINY` (ou `XTINY` em small), cor `TEXT_MUTED`
- [ ] Session pills permanecem visiveis e inalteradas no estado paused
- [ ] Sem overlap de elementos em nenhum dos 3 buckets
- [ ] Cores dim sao visivelmente distintas do fundo (`BG`) no simulador FR255 (MIP)

---

## 8. Out of scope

- Toggle pause/resume real (task `02-04-pausa-resume-stop`).
- Confirmacao de stop.
- Animacao de blink/pulse no estado paused.
- Strings PT (task de i18n posterior).
- Refactor do construtor de TimerView para usar struct/dict.