# Plan — Task 01-04: Tela Fim de Sessão (Phase Transition + Cycle Complete)

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar duas telas estáticas de protótipo visual — P5 (PhaseTransitionView) com texto gigante da próxima fase e auto-dismiss de 3s, e P6 (CycleCompleteView) com heading, número grande, contador e dois PrimaryButtons navegáveis — integradas ao demo cycling do HomeDelegate.

## 2. Cenários

### Caminho feliz
1. Usuário na HomeView pressiona Enter repetidamente para navegar o demo cycle.
2. Após os 4 TimerViews existentes (idx 0–3), Enter no idx 4/5/6 abre PhaseTransitionView (Focus/Break/Long Break).
3. PhaseTransitionView exibe texto gigante + hint, auto-dismiss após 3s ou qualquer input imediato.
4. Enter no idx 7 abre CycleCompleteView com dados estáticos (4/4, 8 sessions).
5. Na CycleCompleteView, Up/Down alterna foco entre os 2 botões, Enter faz log + popView, Back faz popView.

### Edge cases
- "LONG BREAK" em `FONT_NUMBER_HOT` no `:small` bucket pode exceder a largura → usar `FONT_LARGE` como fallback para esse texto nesse bucket.
- No `:small` bucket, omitir a linha "Today: X sessions" para caber todos os elementos.
- Se o Timer.Timer callback executa após a View já ter sido dismissed por input manual, o `_dismissTimer` será null → checar null antes de stop.

### Erros
- Timer callback invocado após popView: mitigado por limpar `_dismissTimer = null` no `onHide()`.
- `fillRoundedRectangle`/`drawRoundedRectangle` não disponível: SDK 3.x+, todos os devices alvo suportam.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/views/PhaseTransitionView.mc` | View P5: fundo bg, texto gigante da fase, hint "Session N of M", Timer 3s auto-dismiss |
| 2 | `source/delegates/PhaseTransitionDelegate.mc` | Input P5: qualquer input (Select, Back, Key) → chama dismiss() na View |
| 3 | `source/views/CycleCompleteView.mc` | View P6: heading, número grande, hint today, 2 botões via PrimaryButton |
| 4 | `source/delegates/CycleCompleteDelegate.mc` | Input P6: Up/Down alterna foco, Enter ativa, Back = popView |
| 5 | `source/ui/components/PrimaryButton.mc` | Módulo stateless: draw botão filled (focused) ou outline (unfocused) |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/delegates/HomeDelegate.mc` | Expandir demo cycling de 4 para 8 itens (3 P5 + 1 P6) |
| 2 | `source/ui/layout/Dimensions.mc` | Adicionar 9 funções de dimensão para P5 e P6 |
| 3 | `resources/strings/strings.xml` | Adicionar 5 novas strings |

### 4.1 `source/delegates/HomeDelegate.mc`

**Antes:**
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

**Depois:**
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
            Ui.pushView(
                new CycleCompleteView(4, 4, 8),
                new CycleCompleteDelegate(),
                Ui.SLIDE_LEFT
            );
        }

        _demoIdx++;
        return true;
    }
```

### 4.2 `source/ui/layout/Dimensions.mc`

**Antes (fim do arquivo, após `pausedLabelOffsetY`):**
```monkeyc
    function pausedLabelOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 30; }
        if (bucket == :large) { return 60; }
        return 35;
    }
}
```

**Depois:**
```monkeyc
    function pausedLabelOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 30; }
        if (bucket == :large) { return 60; }
        return 35;
    }

    // P5 — Phase Transition
    function phaseGiantY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 85; }
        if (bucket == :large) { return 180; }
        return 110;
    }

    function phaseHintY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 260; }
        return 160;
    }

    // P6 — Cycle Complete
    function cycleHeadingY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 20; }
        if (bucket == :large) { return 50; }
        return 30;
    }

    function cycleNumberY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 55; }
        if (bucket == :large) { return 130; }
        return 75;
    }

    function cycleTodayY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 100; }
        if (bucket == :large) { return 220; }
        return 130;
    }

    function cycleButton1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 280; }
        return 165;
    }

    function cycleButton2Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 160; }
        if (bucket == :large) { return 340; }
        return 200;
    }

    function buttonWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 240; }
        return 160;
    }

    function buttonHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 26; }
        if (bucket == :large) { return 44; }
        return 30;
    }
}
```

### 4.3 `resources/strings/strings.xml`

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
    <string id="cycle_complete_title">CYCLE COMPLETE</string>
    <string id="session_n_of_m">Session $1$ of $2$</string>
    <string id="today_sessions">Today: $1$ sessions</string>
    <string id="start_again">Start again</string>
    <string id="done">Done</string>
</resources>
```

---

## 5. Código dos arquivos a CRIAR

### 5.1 `source/views/PhaseTransitionView.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Lang;

class PhaseTransitionView extends Ui.View {
    private var _phase as Lang.Symbol;
    private var _sessionNum as Lang.Number;
    private var _totalSessions as Lang.Number;
    private var _dismissTimer as Timer.Timer?;

    function initialize(phase as Lang.Symbol, sessionNum as Lang.Number, totalSessions as Lang.Number) {
        View.initialize();
        _phase = phase;
        _sessionNum = sessionNum;
        _totalSessions = totalSessions;
    }

    function onShow() as Void {
        _dismissTimer = new Timer.Timer();
        _dismissTimer.start(method(:dismiss), 3000, false);
    }

    function dismiss() as Void {
        if (_dismissTimer != null) {
            _dismissTimer.stop();
            _dismissTimer = null;
        }
        Ui.popView(Ui.SLIDE_LEFT);
    }

    function onHide() as Void {
        if (_dismissTimer != null) {
            _dismissTimer.stop();
            _dismissTimer = null;
        }
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var phaseText = getPhaseText();
        var phaseColor = getPhaseColor();

        var giantFont = getGiantFont(bucket, phaseText, w);
        var giantY = Dimensions.phaseGiantY(bucket);
        dc.setColor(phaseColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, giantY, giantFont, phaseText, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var hintY = Dimensions.phaseHintY(bucket);
        var hintFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var hintText = Lang.format("$1$ $2$ $3$ $4$", [
            "Session", _sessionNum, "of", _totalSessions
        ]);
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, hintY, hintFont, hintText, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    private function getPhaseText() as Lang.String {
        if (_phase == :focus) { return Ui.loadResource(Rez.Strings.phase_focus) as Lang.String; }
        if (_phase == :break) { return Ui.loadResource(Rez.Strings.phase_break) as Lang.String; }
        return Ui.loadResource(Rez.Strings.phase_long_break) as Lang.String;
    }

    private function getPhaseColor() as Lang.Number {
        if (_phase == :focus) { return Colors.BRAND; }
        if (_phase == :break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

    private function getGiantFont(bucket as Lang.Symbol, text as Lang.String, screenWidth as Lang.Number) as Gfx.FontReference {
        if (bucket == :small) {
            return Gfx.FONT_NUMBER_MEDIUM;
        }
        return Gfx.FONT_NUMBER_HOT;
    }
}
```

### 5.2 `source/delegates/PhaseTransitionDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class PhaseTransitionDelegate extends Ui.BehaviorDelegate {
    private var _view as PhaseTransitionView;

    function initialize(view as PhaseTransitionView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Lang.Boolean {
        _view.dismiss();
        return true;
    }

    function onBack() as Lang.Boolean {
        _view.dismiss();
        return true;
    }

    function onKey(evt as Ui.KeyEvent) as Lang.Boolean {
        _view.dismiss();
        return true;
    }
}
```

### 5.3 `source/views/CycleCompleteView.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class CycleCompleteView extends Ui.View {
    private var _completedCycles as Lang.Number;
    private var _totalCycles as Lang.Number;
    private var _todaySessions as Lang.Number;
    private var _focusIdx as Lang.Number;

    function initialize(completedCycles as Lang.Number, totalCycles as Lang.Number, todaySessions as Lang.Number) {
        View.initialize();
        _completedCycles = completedCycles;
        _totalCycles = totalCycles;
        _todaySessions = todaySessions;
        _focusIdx = 0;
    }

    function setFocusIdx(idx as Lang.Number) as Void {
        _focusIdx = idx;
        Ui.requestUpdate();
    }

    function getFocusIdx() as Lang.Number {
        return _focusIdx;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var headingY = Dimensions.cycleHeadingY(bucket);
        var headingFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        var headingText = Ui.loadResource(Rez.Strings.cycle_complete_title) as Lang.String;
        dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, headingY, headingFont, headingText, Gfx.TEXT_JUSTIFY_CENTER);

        var numberY = Dimensions.cycleNumberY(bucket);
        var numberFont = (bucket == :small) ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_HOT;
        var numberText = Lang.format("$1$ / $2$", [_completedCycles, _totalCycles]);
        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, numberY, numberFont, numberText, Gfx.TEXT_JUSTIFY_CENTER);

        if (bucket != :small) {
            var todayY = Dimensions.cycleTodayY(bucket);
            var todayFont = Gfx.FONT_TINY;
            var todayText = Lang.format("$1$ $2$ $3$", ["Today:", _todaySessions, "sessions"]);
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, todayY, todayFont, todayText, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var btnW = Dimensions.buttonWidth(bucket);
        var btnH = Dimensions.buttonHeight(bucket);
        var btnX = centerX - btnW / 2;

        var btn1Y = Dimensions.cycleButton1Y(bucket);
        var startText = Ui.loadResource(Rez.Strings.start_again) as Lang.String;
        PrimaryButton.draw(dc, btnX, btn1Y, btnW, btnH, startText, _focusIdx == 0, bucket);

        var btn2Y = Dimensions.cycleButton2Y(bucket);
        var doneText = Ui.loadResource(Rez.Strings.done) as Lang.String;
        PrimaryButton.draw(dc, btnX, btn2Y, btnW, btnH, doneText, _focusIdx == 1, bucket);
    }
}
```

### 5.4 `source/delegates/CycleCompleteDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class CycleCompleteDelegate extends Ui.BehaviorDelegate {
    private var _view as CycleCompleteView?;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function setView(view as CycleCompleteView) as Void {
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        if (_view != null) {
            _view.setFocusIdx(0);
        }
        return true;
    }

    function onNextPage() as Lang.Boolean {
        if (_view != null) {
            _view.setFocusIdx(1);
        }
        return true;
    }

    function onSelect() as Lang.Boolean {
        if (_view != null) {
            var idx = _view.getFocusIdx();
            if (idx == 0) {
                Sys.println("Start again pressed");
            } else {
                Sys.println("Done pressed");
            }
        }
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}
```

### 5.5 `source/ui/components/PrimaryButton.mc`

```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PrimaryButton {
    function draw(
        dc as Gfx.Dc,
        x as Lang.Number,
        y as Lang.Number,
        w as Lang.Number,
        h as Lang.Number,
        label as Lang.String,
        isFocused as Lang.Boolean,
        bucket as Lang.Symbol
    ) as Void {
        var radius = Dimensions.cardRadius(bucket);
        var centerX = x + w / 2;
        var centerY = y + h / 2;
        var font = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;

        if (isFocused) {
            dc.setColor(Colors.BRAND, Colors.BRAND);
            dc.fillRoundedRectangle(x, y, w, h, radius);
            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(x, y, w, h, radius);
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        }

        dc.drawText(centerX, centerY, font, label, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}
```

---

## 6. Storage/Properties

Não aplicável nesta task (protótipo visual sem persistência).

---

## 7. Checklist de execução

- [x] 1. Criar `source/ui/components/PrimaryButton.mc`
- [x] 2. Criar `source/views/PhaseTransitionView.mc`
- [x] 3. Criar `source/delegates/PhaseTransitionDelegate.mc`
- [x] 4. Criar `source/views/CycleCompleteView.mc`
- [x] 5. Criar `source/delegates/CycleCompleteDelegate.mc`
- [x] 6. Modificar `source/ui/layout/Dimensions.mc` (adicionar 9 funções)
- [x] 7. Modificar `resources/strings/strings.xml` (adicionar 5 strings)
- [x] 8. Modificar `source/delegates/HomeDelegate.mc` (expandir demo cycling para 8 idx)
- [x] 9. Build para fr255
- [x] 10. Build para fr255s
- [x] 11. Build para fr265
- [ ] 12. Testar no simulador (caminho feliz completo)

---

## 8. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros

### Manual (simulador)

#### P5 — Phase Transition
- [ ] Tela fullscreen com fundo `bg` (#0C0C0C)
- [ ] Texto gigante (FONT_NUMBER_HOT em medium/large, FONT_NUMBER_MEDIUM em small) centralizado
- [ ] Cor do texto corresponde à fase: brand (Focus), textMuted (Break), accent (Long Break)
- [ ] Hint "Session N of M" abaixo do texto gigante, FONT_TINY, textMuted
- [ ] Auto-dismiss após 3s (popView automático)
- [ ] Qualquer input (Enter, Back) dismissa imediatamente
- [ ] 3 variantes funcionam no demo cycle (idx 4, 5, 6)

#### P6 — Cycle Complete
- [ ] Heading "CYCLE COMPLETE" no topo, cor accent, FONT_MEDIUM (FONT_SMALL no small)
- [ ] Número "4 / 4" grande no centro, FONT_NUMBER_HOT (FONT_NUMBER_MEDIUM no small)
- [ ] Hint "Today: 8 sessions" abaixo, FONT_TINY, textMuted (omitido no small bucket)
- [ ] PrimaryButton "Start again" — fundo brand, texto textPrimary, focado por default
- [ ] PrimaryButton "Done" — outline border, texto textMuted
- [ ] Up/Down alterna foco entre os 2 botões (visual atualiza)
- [ ] Enter no botão focado: log no console + popView
- [ ] Back: popView
- [ ] Layout não corta no small bucket (FR255S)

---

## 9. Out of scope

- Lógica real de transição de fase (task `02-04`).
- Persistência de contagem diária (task `02-05`).
- ActivityRecording stop/save (task `02-10`).
- Ações reais dos botões "Start again" / "Done" (apenas log + popView).
- Strings PT (strings_pt.xml) — será criado quando o suporte i18n for implementado.
- Formatação com `Rez.Strings.session_n_of_m` usando Lang.format de resource — no protótipo, strings são montadas inline por simplicidade.

---

## 10. Nota sobre CycleCompleteDelegate ↔ View

O `CycleCompleteDelegate` precisa de referência à `CycleCompleteView` para chamar `setFocusIdx`. Padrão: no `HomeDelegate.onSelect`, criar view e delegate separadamente, chamar `delegate.setView(view)` antes do `pushView`. Snippet exato no HomeDelegate:

```monkeyc
} else {
    var view = new CycleCompleteView(4, 4, 8);
    var delegate = new CycleCompleteDelegate();
    delegate.setView(view);
    Ui.pushView(view, delegate, Ui.SLIDE_LEFT);
}
```