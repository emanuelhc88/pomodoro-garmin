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

        var giantFont = (bucket == :small) ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_HOT;
        var giantY = Dimensions.phaseGiantY(bucket);
        dc.setColor(phaseColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, giantY, giantFont, phaseText, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var hintY = Dimensions.phaseHintY(bucket);
        var hintFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var hintText = Strings.format(:session_n_of_m, [_sessionNum, _totalSessions]);
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, hintY, hintFont, hintText, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    private function getPhaseText() as Lang.String {
        if (_phase == :focus) { return Strings.get(:phase_focus); }
        if (_phase == :break) { return Strings.get(:phase_break); }
        return Strings.get(:phase_long_break);
    }

    private function getPhaseColor() as Lang.Number {
        if (_phase == :focus) { return Colors.BRAND; }
        if (_phase == :break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

}