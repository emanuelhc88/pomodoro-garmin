# Plan — Task 01-07: Tela History

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar a página P7 (History): título + lista vertical scrollável com mock de 10 sessões, highlight do item focused, empty state, modelo Session, utilitários TimeFormatter e DateUtils, e navegação via item Settings (index 4) do Home.

---

## 2. Cenários

### Caminho feliz
1. Usuário seleciona item Settings (index 4) na Home → pushView HistoryView.
2. Tela renderiza título "HISTORY" + lista de 10 sessões mock.
3. Usuário navega up/down → focus move entre items, scroll ajusta quando focus sai da viewport.
4. Usuário pressiona back → popView, volta para Home.

### Edge cases
- Lista vazia: renderiza EmptyState com texto "No sessions yet" centralizado.
- Focus no primeiro item + onPreviousPage: nada acontece (clamp em 0).
- Focus no último item + onNextPage: nada acontece (clamp em size-1).
- Bucket :small → usa FONT_TINY como fallback para FONT_XTINY (risco R4).

### Erros
- Nenhum erro tratável nesta task (dados são mock hardcoded, sem I/O).

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/model/Session.mc` | Class com campos da sessão + formatters |
| 2 | `source/utils/TimeFormatter.mc` | Module: `formatDuration(seconds)`, `formatTime(hour, min)` |
| 3 | `source/utils/DateUtils.mc` | Module: `formatDate(epoch)`, `getMonthNames()`, `getLocale()` |
| 4 | `source/ui/components/HistoryItem.mc` | Module: `draw(dc, x, y, w, session, focused, bucket)` |
| 5 | `source/ui/components/EmptyState.mc` | Module: `draw(dc, centerX, centerY, text, bucket)` |
| 6 | `source/views/HistoryView.mc` | View com scroll manual, renderiza título + lista/empty |
| 7 | `source/delegates/HistoryDelegate.mc` | Input: up/down = scroll, back = pop |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/ui/layout/Dimensions.mc` | Adicionar 7 funções history* |
| 2 | `source/delegates/HomeDelegate.mc` | Item index 4 → push HistoryView |
| 3 | `resources/strings/strings.xml` | Adicionar 4 strings history |
| 4 | `resources-por/strings/strings.xml` | Adicionar 4 strings history PT |

---

### 4.1 `source/ui/layout/Dimensions.mc`

**Depois do último método (`customHintsY`), adicionar:**

```monkeyc
    function historyTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 15; }
        if (bucket == :large) { return 35; }
        return 20;
    }

    function historyItemHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 40; }
        if (bucket == :large) { return 70; }
        return 52;
    }

    function historyItemPadding(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 4; }
        if (bucket == :large) { return 10; }
        return 6;
    }

    function historyListStartY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 35; }
        if (bucket == :large) { return 70; }
        return 45;
    }

    function historyItemLine1Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 2; }
        if (bucket == :large) { return 6; }
        return 4;
    }

    function historyItemLine2Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 14; }
        if (bucket == :large) { return 26; }
        return 18;
    }

    function historyItemLine3Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 28; }
        if (bucket == :large) { return 50; }
        return 36;
    }
```

---

### 4.2 `source/delegates/HomeDelegate.mc`

**Antes:**

```monkeyc
    function onSelect() as Lang.Boolean {
        var selectedIndex = _view.getSelectedIndex();

        if (selectedIndex == 3) {
            var view = new CustomBuilderView();
            Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }

        var idx = _demoIdx % 8;
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

        if (selectedIndex == 4) {
            var view = new HistoryView();
            Ui.pushView(view, new HistoryDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }

        var idx = _demoIdx % 8;
```

---

### 4.3 `resources/strings/strings.xml`

**Antes:**

```xml
    <string id="hints_edit">SELECT to confirm</string>
</resources>
```

**Depois:**

```xml
    <string id="hints_edit">SELECT to confirm</string>
    <string id="history_title">HISTORY</string>
    <string id="history_empty">No sessions yet</string>
    <string id="duration_hours_minutes">$1$h $2$m</string>
    <string id="duration_minutes">$1$m</string>
</resources>
```

---

### 4.4 `resources-por/strings/strings.xml`

**Antes:**

```xml
    <string id="hints_edit">SELECT p/ confirmar</string>
</resources>
```

**Depois:**

```xml
    <string id="hints_edit">SELECT p/ confirmar</string>
    <string id="history_title">HISTORICO</string>
    <string id="history_empty">Sem sessoes ainda</string>
    <string id="duration_hours_minutes">$1$h $2$min</string>
    <string id="duration_minutes">$1$min</string>
</resources>
```

---

## 5. Código dos arquivos a CRIAR

### 5.1 `source/model/Session.mc`

```monkeyc
using Toybox.Lang;

class Session {
    var completedAt as Lang.Number;
    var preset as Lang.String;
    var workMin as Lang.Number;
    var breakMin as Lang.Number;
    var cycles as Lang.Number;
    var totalDuration as Lang.Number;

    function initialize(completedAt as Lang.Number, preset as Lang.String, workMin as Lang.Number, breakMin as Lang.Number, cycles as Lang.Number, totalDuration as Lang.Number) {
        self.completedAt = completedAt;
        self.preset = preset;
        self.workMin = workMin;
        self.breakMin = breakMin;
        self.cycles = cycles;
        self.totalDuration = totalDuration;
    }

    function formatPreset() as Lang.String {
        return Lang.format("$1$/$2$ · $3$", [workMin, breakMin, cycles]);
    }
}
```

---

### 5.2 `source/utils/TimeFormatter.mc`

```monkeyc
using Toybox.Lang;
using Toybox.WatchUi as Ui;

module TimeFormatter {
    function formatDuration(totalSeconds as Lang.Number) as Lang.String {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;

        if (hours > 0) {
            var pattern = Ui.loadResource(Rez.Strings.duration_hours_minutes) as Lang.String;
            return Lang.format(pattern, [hours, minutes]);
        }
        var pattern = Ui.loadResource(Rez.Strings.duration_minutes) as Lang.String;
        return Lang.format(pattern, [minutes]);
    }

    function formatTime(hour as Lang.Number, min as Lang.Number) as Lang.String {
        return Lang.format("$1$:$2$", [hour.format("%02d"), min.format("%02d")]);
    }
}
```

---

### 5.3 `source/utils/DateUtils.mc`

```monkeyc
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;

module DateUtils {
    function formatDate(epoch as Lang.Number) as Lang.String {
        var moment = new Time.Moment(epoch);
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        var monthNames = getMonthNames();
        var monthIdx = (info.month as Lang.Number) - 1;
        if (monthIdx < 0 || monthIdx > 11) { monthIdx = 0; }
        var monthStr = monthNames[monthIdx] as Lang.String;
        var timeStr = TimeFormatter.formatTime(info.hour as Lang.Number, info.min as Lang.Number);

        if (getLocale() == :pt) {
            return Lang.format("$1$ $2$, $3$", [info.day, monthStr, timeStr]);
        }
        return Lang.format("$1$ $2$, $3$", [monthStr, info.day, timeStr]);
    }

    function getMonthNames() as Lang.Array<Lang.String> {
        if (getLocale() == :pt) {
            return ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
        }
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    }

    function getLocale() as Lang.Symbol {
        var lang = Sys.getDeviceSettings().systemLanguage;
        if (lang == Sys.LANGUAGE_POR) {
            return :pt;
        }
        return :en;
    }
}
```

---

### 5.4 `source/ui/components/HistoryItem.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module HistoryItem {
    function draw(dc as Gfx.Dc, x as Lang.Number, y as Lang.Number, w as Lang.Number, session as Session, focused as Lang.Boolean, bucket as Lang.Symbol) as Void {
        var itemH = Dimensions.historyItemHeight(bucket);

        if (focused) {
            dc.setColor(Colors.BORDER, Colors.BORDER);
            dc.fillRectangle(x, y, w, itemH);
        }

        var textX = x + 10;
        var line1Y = y + Dimensions.historyItemLine1Offset(bucket);
        var line2Y = y + Dimensions.historyItemLine2Offset(bucket);
        var line3Y = y + Dimensions.historyItemLine3Offset(bucket);

        var dateFont = (bucket == :small) ? Gfx.FONT_TINY : Gfx.FONT_TINY;
        var durationFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_SMALL;
        var presetFont = (bucket == :small) ? Gfx.FONT_TINY : Gfx.FONT_XTINY;

        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, line1Y, dateFont, DateUtils.formatDate(session.completedAt), Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, line2Y, durationFont, TimeFormatter.formatDuration(session.totalDuration), Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, line3Y, presetFont, session.formatPreset(), Gfx.TEXT_JUSTIFY_LEFT);
    }
}
```

---

### 5.5 `source/ui/components/EmptyState.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module EmptyState {
    function draw(dc as Gfx.Dc, centerX as Lang.Number, centerY as Lang.Number, text as Lang.String, bucket as Lang.Symbol) as Void {
        var font = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}
```

---

### 5.6 `source/views/HistoryView.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HistoryView extends Ui.View {
    private var _sessions as Lang.Array<Session>;
    private var _scrollOffset as Lang.Number;
    private var _focusIdx as Lang.Number;
    private var _visibleCount as Lang.Number;
    private var _titleText as Lang.String;
    private var _emptyText as Lang.String;

    function initialize() {
        View.initialize();
        _sessions = getMockSessions();
        _scrollOffset = 0;
        _focusIdx = 0;
        _visibleCount = 3;
        _titleText = Ui.loadResource(Rez.Strings.history_title) as Lang.String;
        _emptyText = Ui.loadResource(Rez.Strings.history_empty) as Lang.String;
    }

    function getSessionCount() as Lang.Number {
        return _sessions.size();
    }

    function getFocusIdx() as Lang.Number {
        return _focusIdx;
    }

    function scrollDown() as Void {
        if (_sessions.size() == 0) { return; }
        if (_focusIdx < _sessions.size() - 1) {
            _focusIdx++;
            if (_focusIdx >= _scrollOffset + _visibleCount) {
                _scrollOffset++;
            }
            Ui.requestUpdate();
        }
    }

    function scrollUp() as Void {
        if (_sessions.size() == 0) { return; }
        if (_focusIdx > 0) {
            _focusIdx--;
            if (_focusIdx < _scrollOffset) {
                _scrollOffset--;
            }
            Ui.requestUpdate();
        }
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var titleY = Dimensions.historyTitleY(bucket);
        var titleFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, titleFont, _titleText, Gfx.TEXT_JUSTIFY_CENTER);

        if (_sessions.size() == 0) {
            EmptyState.draw(dc, centerX, h / 2, _emptyText, bucket);
            return;
        }

        var listStartY = Dimensions.historyListStartY(bucket);
        var itemH = Dimensions.historyItemHeight(bucket);
        var itemPad = Dimensions.historyItemPadding(bucket);
        var totalItemH = itemH + itemPad;

        _visibleCount = (h - listStartY) / totalItemH;
        if (_visibleCount < 1) { _visibleCount = 1; }

        var itemX = 0;
        var itemW = w;
        var y = listStartY;

        var end = _scrollOffset + _visibleCount;
        if (end > _sessions.size()) { end = _sessions.size(); }

        for (var i = _scrollOffset; i < end; i++) {
            var session = _sessions[i] as Session;
            HistoryItem.draw(dc, itemX, y, itemW, session, i == _focusIdx, bucket);
            y += totalItemH;
        }
    }

    private function getMockSessions() as Lang.Array<Session> {
        var now = Time.now().value();
        var day = 86400;
        return [
            new Session(now - day * 0, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 1, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 1, "50/10/4", 50, 10, 4, 14400),
            new Session(now - day * 2, "30/5/4", 30, 5, 4, 8400),
            new Session(now - day * 3, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 4, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 5, "50/10/4", 50, 10, 4, 14400),
            new Session(now - day * 6, "30/5/4", 30, 5, 4, 8400),
            new Session(now - day * 7, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 8, "25/5/4", 25, 5, 4, 7200)
        ];
    }
}
```

---

### 5.7 `source/delegates/HistoryDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HistoryDelegate extends Ui.BehaviorDelegate {
    private var _view as HistoryView;

    function initialize(view as HistoryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Lang.Boolean {
        _view.scrollDown();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.scrollUp();
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}
```

---

## 5. Storage/Properties

Nenhum. Dados são mock hardcoded. Persistência real será implementada em task B10.

---

## 6. Checklist de execução

- [x] 1. Criar diretório `source/utils/`
- [x] 2. Criar `source/model/Session.mc`
- [x] 3. Criar `source/utils/TimeFormatter.mc`
- [x] 4. Criar `source/utils/DateUtils.mc`
- [x] 5. Criar `source/ui/components/EmptyState.mc`
- [x] 6. Criar `source/ui/components/HistoryItem.mc`
- [x] 7. Criar `source/views/HistoryView.mc`
- [x] 8. Criar `source/delegates/HistoryDelegate.mc`
- [x] 9. Modificar `source/ui/layout/Dimensions.mc` (adicionar 7 funções history*)
- [x] 10. Modificar `source/delegates/HomeDelegate.mc` (index 4 → push HistoryView)
- [x] 11. Modificar `resources/strings/strings.xml` (4 strings EN)
- [x] 12. Modificar `resources-por/strings/strings.xml` (4 strings PT)
- [x] 13. Build para fr255
- [x] 14. Build para fr255s
- [x] 15. Build para fr265
- [ ] 16. Testar no simulador (caminho feliz: scroll, empty state)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros

### Manual (simulador)
- [ ] Selecionar item Settings (index 4) no Home → abre tela History
- [ ] Título "HISTORY" visível no topo
- [ ] Lista de 10 sessões visível com scroll funcional (up/down)
- [ ] Item focused tem fundo highlight (cor BORDER 0x2A2A2A)
- [ ] Cada item mostra 3 linhas: data/hora, duração, preset
- [ ] Back retorna ao Home
- [ ] Em tela :small (fr255s): layout proporcional, fontes legíveis

---

## 8. Out of scope

- Persistência real (Storage) — task B10.
- Delete de sessão individual — previsto para V1.x apenas se houver demanda.
- Navegação via Settings Menu2 real (será implementada na task P8).
- Scroll indicator visual (dots ou scrollbar) — não previsto na spec P7.
- Activity FIT recording — task B11.
