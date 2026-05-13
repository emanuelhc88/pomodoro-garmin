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
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var headingY = h * 18 / 100;
        var headingFont = (bucket == :large) ? Gfx.FONT_MEDIUM : Gfx.FONT_TINY;
        var headingText = Strings.get(:cycle_complete_title);
        dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, headingY, headingFont, headingText, Gfx.TEXT_JUSTIFY_CENTER);

        var numberY = h * 30 / 100;
        var numberFont = (bucket == :small) ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_MILD;
        var numberText = Lang.format("$1$ / $2$", [_completedCycles, _totalCycles]);
        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, numberY, numberFont, numberText, Gfx.TEXT_JUSTIFY_CENTER);

        if (bucket != :small) {
            var todayY = h * 52 / 100;
            var todayFont = Gfx.FONT_TINY;
            var todayText;
            if (_todaySessions == 1) {
                todayText = Strings.get(:today_session_singular);
            } else {
                todayText = Strings.format(:today_sessions, [_todaySessions]);
            }
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, todayY, todayFont, todayText, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var btnW = Dimensions.buttonWidth(bucket);
        var btnH = Dimensions.buttonHeight(bucket);
        var btnX = centerX - btnW / 2;

        var btn1Y = h * 63 / 100;
        var startText = Strings.get(:start_again);
        PrimaryButton.draw(dc, btnX, btn1Y, btnW, btnH, startText, _focusIdx == 0, bucket);

        var btn2Y = btn1Y + btnH + (h * 3 / 100);
        var doneText = Strings.get(:done);
        PrimaryButton.draw(dc, btnX, btn2Y, btnW, btnH, doneText, _focusIdx == 1, bucket);
    }
}