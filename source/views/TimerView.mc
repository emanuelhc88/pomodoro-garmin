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
