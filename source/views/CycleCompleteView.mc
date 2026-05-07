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