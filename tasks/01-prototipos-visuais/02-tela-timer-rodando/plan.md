# Plan — Task 01-02: Tela Timer Rodando

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar a página P3 (Timer Running) como protótipo visual estático: anel circular de progresso, display MM:SS, phase label e session pills. Valores hardcoded passados pelo HomeDelegate para validação visual nos 3 buckets (small/medium/large). Sem timer real.

---

## 2. Cenários

### Caminho feliz

1. Usuário está na HomeView, pressiona Enter.
2. `HomeDelegate.onSelect()` faz `pushView` do `TimerView` com dados hardcoded (ciclando entre 3 estados).
3. `TimerView.onUpdate(dc)` desenha: PhaseLabel → TimerRing → TimerDisplay → SessionPills.
4. Usuário pressiona Back → `TimerDelegate.onBack()` faz `popView` → volta para Home.
5. Pressionar Enter de novo mostra o próximo estado (cycling `:running_work` → `:running_short_break` → `:running_long_break`).

### Edge cases

- **Bucket small (218px):** Todos os componentes cabem sem overlap. Font do timer é `FONT_NUMBER_MEDIUM` (menor).
- **SessionPills com total > 4:** Renderiza texto "X/Y" em vez de pills individuais. (Demo usa total=4, mas código deve suportar ambos.)
- **progress = 0.0:** Apenas o anel de fundo (BORDER) é visível, sem arco de progresso.
- **progress = 1.0:** Anel completo na cor da fase.

### Erros

- **`drawArc` com startAngle == endAngle:** Pode gerar artefato. Se progress == 0, não desenhar o arco de progresso (apenas fundo).
- **Font inexistente em device:** `FONT_NUMBER_THAI_HOT` pode não existir em devices muito antigos. A task foca nos 3 devices de build (fr255, fr255s, fr265) onde ambas fonts existem.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/views/TimerView.mc` | View P3 — orquestra componentes, recebe estado hardcoded via `initialize` |
| 2 | `source/delegates/TimerDelegate.mc` | Input: onBack=popView, onSelect=println (noop placeholder) |
| 3 | `source/ui/components/TimerRing.mc` | Módulo stateless — desenha anel circular (fundo BORDER 360° + progresso colorido) |
| 4 | `source/ui/components/TimerDisplay.mc` | Módulo stateless — renderiza MM:SS centralizado |
| 5 | `source/ui/components/SessionPills.mc` | Módulo stateless — desenha pills ou texto "X/Y" |
| 6 | `source/ui/components/PhaseLabel.mc` | Módulo stateless — label uppercase da fase |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/delegates/HomeDelegate.mc` | `onSelect` passa a fazer pushView do TimerView com dados hardcoded ciclando 3 estados |
| 2 | `source/ui/layout/Dimensions.mc` | Adicionar 7 funções: `ringRadius`, `ringStroke`, `timerCenterY`, `phaseLabelOffsetY`, `pillsOffsetY`, `pillSize`, `pillSpacing` |
| 3 | `resources/strings/strings.xml` | Adicionar strings `phase_focus`, `phase_break`, `phase_long_break` |

---

### 4.1 `source/delegates/HomeDelegate.mc`

**Antes:**
```monkeyc
    function onSelect() as Lang.Boolean {
        Sys.println("Selected preset: " + _view.getSelectedIndex());
        return true;
    }
```

**Depois:**
```monkeyc
    private var _demoIdx as Lang.Number = 0;

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

**Nota:** A variável `_demoIdx` deve ser declarada como campo privado da classe (junto com `_view`).

---

### 4.2 `source/ui/layout/Dimensions.mc`

**Antes:**
```monkeyc
    function dotSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 8; }
        if (bucket == :large) { return 12; }
        return 10;
    }
}
```

**Depois:**
```monkeyc
    function dotSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 8; }
        if (bucket == :large) { return 12; }
        return 10;
    }

    function ringRadius(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 85; }
        if (bucket == :large) { return 175; }
        return 100;
    }

    function ringStroke(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 6; }
        if (bucket == :large) { return 12; }
        return 8;
    }

    function timerCenterY(bucket as Lang.Symbol, screenHeight as Lang.Number) as Lang.Number {
        return screenHeight / 2;
    }

    function phaseLabelOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return -48; }
        if (bucket == :large) { return -100; }
        return -60;
    }

    function pillsOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 75; }
        if (bucket == :large) { return 160; }
        return 90;
    }

    function pillSize(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 6; }
        if (bucket == :large) { return 10; }
        return 8;
    }

    function pillSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 3; }
        if (bucket == :large) { return 6; }
        return 4;
    }
}
```

**Nota:** `timerCenterY` recebe `screenHeight` e calcula centro dinâmico (`height/2`) em vez de valor fixo — mitigação do Risco 5 do PRD (devices large com alturas variando 390–454px).

---

### 4.3 `resources/strings/strings.xml`

**Antes:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d cycles</string>
    <string id="settings_label">Settings</string>
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
</resources>
```

---

## 5. Código dos arquivos novos

### 5.1 `source/ui/components/TimerRing.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module TimerRing {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        radius as Lang.Number,
        stroke as Lang.Number,
        progress as Lang.Float,
        color as Lang.Number
    ) as Void {
        dc.setPenWidth(stroke);
        dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 0, 360);

        if (progress > 0.0) {
            var startAngle = 90;
            var endAngle = 90 - (progress * 360).toNumber();
            if (endAngle < 0) {
                endAngle = endAngle + 360;
            }
            dc.setColor(color, Gfx.COLOR_TRANSPARENT);
            dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, startAngle, endAngle);
        }

        dc.setPenWidth(1);
    }
}
```

### 5.2 `source/ui/components/TimerDisplay.mc`

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

### 5.3 `source/ui/components/PhaseLabel.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PhaseLabel {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        text as Lang.String,
        color as Lang.Number,
        bucket as Lang.Symbol
    ) as Void {
        var font = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}
```

### 5.4 `source/ui/components/SessionPills.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module SessionPills {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        totalCycles as Lang.Number,
        completedCycles as Lang.Number,
        pillSize as Lang.Number,
        pillSpacing as Lang.Number
    ) as Void {
        if (totalCycles > 4) {
            var text = completedCycles.toString() + "/" + totalCycles.toString();
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, y - Gfx.getFontHeight(Gfx.FONT_TINY) / 2, Gfx.FONT_TINY, text, Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        var diameter = pillSize * 2;
        var totalWidth = totalCycles * diameter + (totalCycles - 1) * pillSpacing;
        var startX = centerX - totalWidth / 2 + pillSize;

        for (var i = 0; i < totalCycles; i++) {
            var px = startX + i * (diameter + pillSpacing);

            if (i < completedCycles) {
                dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(px, y, pillSize);
            } else if (i == completedCycles) {
                dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(px, y, pillSize);
            } else {
                dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(px, y, pillSize);
            }
        }
    }
}
```

### 5.5 `source/views/TimerView.mc`

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

### 5.6 `source/delegates/TimerDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onSelect() as Lang.Boolean {
        Sys.println("TODO: pause/resume");
        return true;
    }
}
```

---

## 6. Storage/Properties

Não aplicável nesta task (protótipo visual estático, sem persistência).

---

## 7. Checklist de execução

- [x] 1. Criar `source/ui/components/TimerRing.mc` (conteúdo da seção 5.1)
- [x] 2. Criar `source/ui/components/TimerDisplay.mc` (conteúdo da seção 5.2)
- [x] 3. Criar `source/ui/components/PhaseLabel.mc` (conteúdo da seção 5.3)
- [x] 4. Criar `source/ui/components/SessionPills.mc` (conteúdo da seção 5.4)
- [x] 5. Criar `source/views/TimerView.mc` (conteúdo da seção 5.5)
- [x] 6. Criar `source/delegates/TimerDelegate.mc` (conteúdo da seção 5.6)
- [x] 7. Modificar `source/ui/layout/Dimensions.mc` (adicionar 7 funções — seção 4.2)
- [x] 8. Modificar `source/delegates/HomeDelegate.mc` (onSelect com pushView — seção 4.1)
- [x] 9. Modificar `resources/strings/strings.xml` (adicionar 3 strings — seção 4.3)
- [x] 10. Build para fr255 — `monkeyc -d fr255`
- [x] 11. Build para fr255s — `monkeyc -d fr255s`
- [x] 12. Build para fr265 — `monkeyc -d fr265`
- [ ] 13. Testar no simulador (caminho feliz: Enter na Home → ver TimerView → Back → Enter de novo → ver próximo estado)

---

## 8. Critérios de aceite

### Automated

- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros

### Manual (simulador)

- [ ] Anel circular desenhado partindo do topo (12h), preenchendo sentido horário
- [ ] Cor do anel reflete estado: BRAND para Work, TEXT_MUTED para Break, ACCENT para Long Break
- [ ] Espessura do anel correta por bucket (small=6px, medium=8px, large=12px)
- [ ] MM:SS centralizado, fonte `FONT_NUMBER_THAI_HOT` (medium/large) ou `FONT_NUMBER_MEDIUM` (small)
- [ ] Phase label uppercase ("FOCUS", "BREAK", "LONG BREAK") acima do display com cor da fase
- [ ] Session pills no rodapé: 4 pills (2 preenchidos BRAND, 1 preenchido ACCENT=current, 1 outline BORDER)
- [ ] Layout não corta em nenhum bucket (testar fr255s=small, fr255=medium, fr265=large)
- [ ] Back no TimerView retorna para HomeView
- [ ] Cada Enter na Home mostra um estado diferente (cycling 3 estados)

---

## 9. Out of scope

- Loop de timer real (`02-02-timer-loop`)
- Pause / Resume / Stop (`02-04-pausa-resume-stop`)
- Vibração (`02-03-vibracao-inicio-fim`)
- ActivityRecording (`02-10-fit-activity-recording`)
- Estado Paused (P4 — próxima task visual `01-03`)
- Uso de Rez.Strings (hardcoded direto como string literal nesta task; i18n será integrada em task futura)
- Recursos XML de dimensões (`resources-small/`, `resources-large/`) — usando Dimensions.mc programático conforme pattern existente