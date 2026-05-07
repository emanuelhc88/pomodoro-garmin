# Plan — Task 01-05: Tela Presets (refinamento)

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Refinar a HomeView (P1) para consumir dados tipados de presets em vez de strings hardcoded. Criar classe `Preset` com formatação, adaptar `PresetCard` para renderizar variante custom com label "CUSTOM" em accent, e fazer o dot de Settings ser outline no `DotsIndicator`.

---

## 2. Cenários

### Caminho feliz
1. Usuário abre a Home. Vê o preset 25/5 selecionado com card mostrando "25 / 5" (FONT_NUMBER_MEDIUM) e "4 cycles" (FONT_TINY) abaixo.
2. Navega Down — vê 30/5, 50/10 com mesma formatação.
3. Navega até Custom — card mostra "CUSTOM" (FONT_XTINY, ACCENT) acima de "25 / 5" e "4 cycles".
4. Navega até Settings — card mostra "Settings" (FONT_LARGE), sem sublabel. Dot do Settings é outline (drawCircle).
5. Dots indicator mostra 5 dots, o ativo em ACCENT filled, presets inativos em BORDER filled, Settings inativo em BORDER outline.

### Edge cases
- Bucket small (FR255S 218px): FONT_NUMBER_MEDIUM pode ser grande demais. Usar FONT_MEDIUM como fallback para linha principal.
- Preset Custom com valores default (25/5/4) — sem persistência nesta task, valores hardcoded são aceitáveis.

### Erros
- Nenhum cenário de erro nesta task (protótipo visual, sem I/O).

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/model/Preset.mc` | Classe Preset (workMin, breakMin, cycles, isCustom) + módulo Presets com factory `builtinList()`. Métodos de formatação `formatPrimary()` e `formatSecondary(cyclesLabel)`. |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/views/HomeView.mc` | Substituir arrays de strings por `Array<Preset>`. Carregar strings localizadas em `initialize()`. Passar dados formatados ao PresetCard. |
| 2 | `source/ui/components/PresetCard.mc` | Nova assinatura com `isCustom` e `customLabel`. Fontes ajustadas por bucket. Renderizar label "CUSTOM" acima dos números quando custom. |
| 3 | `source/ui/components/DotsIndicator.mc` | Novo parâmetro `settingsIndex`. Dot de Settings desenhado como outline (`drawCircle`) quando inativo. |
| 4 | `resources/strings/strings.xml` | Adicionar `unit_cycles` e `preset_custom_label`. |
| 5 | `resources-por/strings/strings.xml` | Adicionar versão PT das novas strings + strings faltantes. |

---

### 4.1 `source/model/Preset.mc`

**Arquivo novo — conteúdo completo:**

```monkeyc
using Toybox.Lang;

class Preset {
    var workMin as Lang.Number;
    var breakMin as Lang.Number;
    var cycles as Lang.Number;
    var isCustom as Lang.Boolean;

    function initialize(workMin as Lang.Number, breakMin as Lang.Number, cycles as Lang.Number, isCustom as Lang.Boolean) {
        self.workMin = workMin;
        self.breakMin = breakMin;
        self.cycles = cycles;
        self.isCustom = isCustom;
    }

    function formatPrimary() as Lang.String {
        return Lang.format("$1$ / $2$", [workMin, breakMin]);
    }

    function formatSecondary(cyclesLabel as Lang.String) as Lang.String {
        return Lang.format("$1$ $2$", [cycles, cyclesLabel]);
    }
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

---

### 4.2 `source/views/HomeView.mc`

**Antes:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HomeView extends Ui.View {
    private var _selectedIndex as Lang.Number = 0;
    private var _presetLabels as Lang.Array<Lang.String>;
    private var _presetSublabels as Lang.Array<Lang.String>;
    private var _totalItems as Lang.Number = 5;

    function initialize() {
        View.initialize();
        _presetLabels = ["25 / 5", "30 / 5", "50 / 10", "Custom", "Settings"];
        _presetSublabels = ["4 cycles", "4 cycles", "4 cycles", "25 / 5 · 4", ""];
    }

    function getSelectedIndex() as Lang.Number {
        return _selectedIndex;
    }

    function navigateUp() as Void {
        _selectedIndex = (_selectedIndex - 1 + _totalItems) % _totalItems;
        Ui.requestUpdate();
    }

    function navigateDown() as Void {
        _selectedIndex = (_selectedIndex + 1) % _totalItems;
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var cw = Dimensions.cardWidth(bucket);
        var ch = Dimensions.cardHeight(bucket);
        var cr = Dimensions.cardRadius(bucket);
        var cb = Dimensions.cardBorder(bucket);
        var dr = Dimensions.dotRadius(bucket);
        var ds = Dimensions.dotSpacing(bucket);

        var wordmarkY = h * 15 / 100;
        Wordmark.draw(dc, centerX, wordmarkY, bucket);

        var cardCenterY = h * 47 / 100;
        var label = _presetLabels[_selectedIndex] as Lang.String;
        var sublabel = _presetSublabels[_selectedIndex] as Lang.String;
        PresetCard.draw(dc, centerX, cardCenterY, label, sublabel, true, cw, ch, cr, cb);

        var dotsY = h * 78 / 100;
        DotsIndicator.draw(dc, centerX, dotsY, _totalItems, _selectedIndex, dr, ds);
    }
}
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HomeView extends Ui.View {
    private var _selectedIndex as Lang.Number = 0;
    private var _presets as Lang.Array<Preset>;
    private var _totalItems as Lang.Number = 5;
    private var _cyclesLabel as Lang.String;
    private var _customLabel as Lang.String;
    private var _settingsLabel as Lang.String;

    function initialize() {
        View.initialize();
        _presets = Presets.builtinList();
        _cyclesLabel = Ui.loadResource(Rez.Strings.unit_cycles) as Lang.String;
        _customLabel = Ui.loadResource(Rez.Strings.preset_custom_label) as Lang.String;
        _settingsLabel = Ui.loadResource(Rez.Strings.settings_label) as Lang.String;
    }

    function getSelectedIndex() as Lang.Number {
        return _selectedIndex;
    }

    function navigateUp() as Void {
        _selectedIndex = (_selectedIndex - 1 + _totalItems) % _totalItems;
        Ui.requestUpdate();
    }

    function navigateDown() as Void {
        _selectedIndex = (_selectedIndex + 1) % _totalItems;
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var cw = Dimensions.cardWidth(bucket);
        var ch = Dimensions.cardHeight(bucket);
        var cr = Dimensions.cardRadius(bucket);
        var cb = Dimensions.cardBorder(bucket);
        var dr = Dimensions.dotRadius(bucket);
        var ds = Dimensions.dotSpacing(bucket);

        var wordmarkY = h * 15 / 100;
        Wordmark.draw(dc, centerX, wordmarkY, bucket);

        var cardCenterY = h * 47 / 100;

        if (_selectedIndex < 4) {
            var preset = _presets[_selectedIndex] as Preset;
            var primary = preset.formatPrimary();
            var secondary = preset.formatSecondary(_cyclesLabel);
            PresetCard.draw(dc, centerX, cardCenterY, primary, secondary, true, preset.isCustom, _customLabel, cw, ch, cr, cb, bucket);
        } else {
            PresetCard.draw(dc, centerX, cardCenterY, _settingsLabel, "", true, false, "", cw, ch, cr, cb, bucket);
        }

        var dotsY = h * 78 / 100;
        DotsIndicator.draw(dc, centerX, dotsY, _totalItems, _selectedIndex, dr, ds, 4);
    }
}
```

---

### 4.3 `source/ui/components/PresetCard.mc`

**Antes:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PresetCard {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        label as Lang.String,
        sublabel as Lang.String,
        isSelected as Lang.Boolean,
        cardWidth as Lang.Number,
        cardHeight as Lang.Number,
        cardRadius as Lang.Number,
        cardBorder as Lang.Number
    ) as Void {
        var x = centerX - cardWidth / 2;
        var y = centerY - cardHeight / 2;

        var borderColor = isSelected ? Colors.BRAND : Colors.BORDER;

        dc.setColor(borderColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(cardBorder);
        dc.drawRoundedRectangle(x, y, cardWidth, cardHeight, cardRadius);
        dc.setPenWidth(1);

        var labelFont = Gfx.FONT_LARGE;
        var sublabelFont = Gfx.FONT_SMALL;
        var labelY = centerY - Gfx.getFontHeight(labelFont) / 2 - 4;
        var sublabelY = labelY + Gfx.getFontHeight(labelFont) - 2;

        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, labelY, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

        if (!sublabel.equals("")) {
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, sublabelY, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
}
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PresetCard {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        label as Lang.String,
        sublabel as Lang.String,
        isSelected as Lang.Boolean,
        isCustom as Lang.Boolean,
        customLabel as Lang.String,
        cardWidth as Lang.Number,
        cardHeight as Lang.Number,
        cardRadius as Lang.Number,
        cardBorder as Lang.Number,
        bucket as Lang.Symbol
    ) as Void {
        var x = centerX - cardWidth / 2;
        var y = centerY - cardHeight / 2;

        var borderColor = isSelected ? Colors.BRAND : Colors.BORDER;

        dc.setColor(borderColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(cardBorder);
        dc.drawRoundedRectangle(x, y, cardWidth, cardHeight, cardRadius);
        dc.setPenWidth(1);

        var labelFont = (bucket == :small) ? Gfx.FONT_MEDIUM : Gfx.FONT_NUMBER_MEDIUM;
        var sublabelFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var customLabelFont = Gfx.FONT_XTINY;

        if (isCustom) {
            var customLabelH = Gfx.getFontHeight(customLabelFont);
            var labelH = Gfx.getFontHeight(labelFont);
            var sublabelH = Gfx.getFontHeight(sublabelFont);
            var totalH = customLabelH + labelH + sublabelH - 8;
            var startY = centerY - totalH / 2;

            dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY, customLabelFont, customLabel, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH - 2, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH + labelH - 6, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            var labelY = centerY - Gfx.getFontHeight(labelFont) / 2 - 4;
            var sublabelY = labelY + Gfx.getFontHeight(labelFont) - 2;

            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, labelY, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

            if (!sublabel.equals("")) {
                dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, sublabelY, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}
```

---

### 4.4 `source/ui/components/DotsIndicator.mc`

**Antes:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module DotsIndicator {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        total as Lang.Number,
        activeIndex as Lang.Number,
        dotRadius as Lang.Number,
        dotSpacing as Lang.Number
    ) as Void {
        var totalWidth = (total - 1) * (dotRadius * 2 + dotSpacing);
        var startX = centerX - totalWidth / 2;

        for (var i = 0; i < total; i++) {
            var dotX = startX + i * (dotRadius * 2 + dotSpacing);
            if (i == activeIndex) {
                dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
            }
            dc.fillCircle(dotX, y, dotRadius);
        }
    }
}
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module DotsIndicator {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        total as Lang.Number,
        activeIndex as Lang.Number,
        dotRadius as Lang.Number,
        dotSpacing as Lang.Number,
        settingsIndex as Lang.Number
    ) as Void {
        var totalWidth = (total - 1) * (dotRadius * 2 + dotSpacing);
        var startX = centerX - totalWidth / 2;

        for (var i = 0; i < total; i++) {
            var dotX = startX + i * (dotRadius * 2 + dotSpacing);
            if (i == activeIndex) {
                dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, y, dotRadius);
            } else if (i == settingsIndex) {
                dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(dotX, y, dotRadius);
            } else {
                dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, y, dotRadius);
            }
        }
    }
}
```

---

### 4.5 `resources/strings/strings.xml`

**Antes:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d cycles</string>
    <string id="settings_label">Settings</string>
    <string id="phase_focus">FOCUS</string>
    <string id="phase_break">BREAK</string>
    <string id="phase_long_break">LONG BREAK</string>
    <string id="state_paused">PAUSED</string>
    <string id="cycle_complete_title">CYCLE COMPLETE</string>
    <string id="session_n_of_m">Session $1$ of $2$</string>
    <string id="today_sessions">Today: $1$ sessions</string>
    <string id="start_again">Start again</string>
    <string id="done">Done</string>
</resources>
```

**Depois:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d cycles</string>
    <string id="unit_cycles">cycles</string>
    <string id="preset_custom_label">CUSTOM</string>
    <string id="settings_label">Settings</string>
    <string id="phase_focus">FOCUS</string>
    <string id="phase_break">BREAK</string>
    <string id="phase_long_break">LONG BREAK</string>
    <string id="state_paused">PAUSED</string>
    <string id="cycle_complete_title">CYCLE COMPLETE</string>
    <string id="session_n_of_m">Session $1$ of $2$</string>
    <string id="today_sessions">Today: $1$ sessions</string>
    <string id="start_again">Start again</string>
    <string id="done">Done</string>
</resources>
```

---

### 4.6 `resources-por/strings/strings.xml`

**Antes:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d ciclos</string>
    <string id="settings_label">Configurações</string>
</resources>
```

**Depois:**
```xml
<resources>
    <string id="app_name">Toma</string>
    <string id="preset_cycles">%d ciclos</string>
    <string id="unit_cycles">ciclos</string>
    <string id="preset_custom_label">PERSONALIZADO</string>
    <string id="settings_label">Configurações</string>
    <string id="phase_focus">FOCO</string>
    <string id="phase_break">PAUSA</string>
    <string id="phase_long_break">PAUSA LONGA</string>
    <string id="state_paused">PAUSADO</string>
    <string id="cycle_complete_title">CICLO COMPLETO</string>
    <string id="session_n_of_m">Sessão $1$ de $2$</string>
    <string id="today_sessions">Hoje: $1$ sessões</string>
    <string id="start_again">Recomeçar</string>
    <string id="done">Pronto</string>
</resources>
```

---

## 5. Storage/Properties

Não aplicável nesta task. Preset Custom usa valores hardcoded (25/5/4). Persistência vem na task 02-08.

---

## 6. Checklist de execução

- [x] 1. Criar diretório `source/model/`
- [x] 2. Criar `source/model/Preset.mc`
- [x] 3. Modificar `resources/strings/strings.xml` (adicionar `unit_cycles`, `preset_custom_label`)
- [x] 4. Modificar `resources-por/strings/strings.xml` (adicionar strings PT)
- [x] 5. Modificar `source/ui/components/DotsIndicator.mc` (adicionar `settingsIndex`, outline para Settings)
- [x] 6. Modificar `source/ui/components/PresetCard.mc` (nova assinatura com `isCustom`, `customLabel`, `bucket`; fontes ajustadas; layout custom)
- [x] 7. Modificar `source/views/HomeView.mc` (substituir arrays por `Preset[]`, carregar strings, chamar componentes com nova API)
- [x] 8. Build para fr255
- [x] 9. Build para fr255s
- [x] 10. Build para fr265
- [ ] 11. Testar no simulador FR255 (medium bucket — caminho feliz: navegar todos os 5 items)
- [ ] 12. Testar no simulador FR255S (small bucket — verificar que fontes cabem no card)
- [ ] 13. Testar no simulador FR265 (large bucket — verificar proporcionalidade)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros

### Manual (simulador)
- [ ] Preset 25/5: card mostra "25 / 5" em FONT_NUMBER_MEDIUM e "4 cycles" em FONT_TINY (medium/large)
- [ ] Preset 30/5 e 50/10: mesma formatação com valores corretos
- [ ] Preset Custom: label "CUSTOM" em ACCENT (FONT_XTINY) aparece acima de "25 / 5" e "4 cycles"
- [ ] Settings: card mostra "Settings" (localizado) sem sublabel
- [ ] DotsIndicator: dot ativo = ACCENT filled; presets inativos = BORDER filled; Settings inativo = BORDER outline
- [ ] FR255S (small): fontes usam FONT_MEDIUM para linha principal (não FONT_NUMBER_MEDIUM)
- [ ] Navegação Up/Down continua funcionando sem regressão

---

## 8. Out of scope

- Persistência de preset Custom em Properties (task 02-08).
- Navegação Enter para iniciar sessão (já funciona no HomeDelegate, não muda).
- Settings como Menu2 (task futura P8).
- Tradução para outros idiomas além de EN/PT.
- Custom Builder (P2 — task 01-06).