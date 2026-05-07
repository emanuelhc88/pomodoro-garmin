using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerView extends Ui.View {
    private var _model as PomodoroModel;
    private var _pausedText as Lang.String;

    function initialize(model as PomodoroModel) {
        View.initialize();
        _model = model;
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

        var state = _model.getState();
        var remaining = _model.getRemainingSeconds();
        var total = _model.getTotalPhaseSeconds();
        var isPaused = _model.isPaused();
        var phase = _stateToPhase(state);

        var ringColor = isPaused ? _getDimColor(phase) : _getPhaseColor(phase);
        var displayColor = isPaused ? Colors.TEXT_MUTED : Colors.TEXT_PRIMARY;
        var labelColor = isPaused ? Colors.TEXT_MUTED : _getPhaseColor(phase);
        var phaseText = _getPhaseText(phase);
        var progress = (total > 0) ? (total - remaining).toFloat() / total.toFloat() : 0.0;

        var labelY = centerY + labelOffsetY;
        PhaseLabel.draw(dc, centerX, labelY, phaseText, labelColor, bucket);

        TimerRing.draw(dc, centerX, centerY, radius, stroke, progress, ringColor);

        TimerDisplay.draw(dc, centerX, centerY, remaining, bucket, displayColor);

        if (isPaused) {
            var pausedY = centerY + Dimensions.pausedLabelOffsetY(bucket);
            var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, pausedY, font, _pausedText, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var pillsY = centerY + pOffsetY;
        SessionPills.draw(dc, centerX, pillsY, _model.getTotalCycles(), _model.getCyclesCompleted(), pSize, pSpacing);
    }

    private function _stateToPhase(state as Lang.Number) as Lang.Symbol {
        if (state == PomodoroState.RUNNING_WORK) { return :running_work; }
        if (state == PomodoroState.RUNNING_SHORT_BREAK) { return :running_short_break; }
        if (state == PomodoroState.RUNNING_LONG_BREAK) { return :running_long_break; }
        if (state == PomodoroState.PAUSED) {
            var model = _model;
            var cycles = model.getCyclesCompleted();
            var total = model.getTotalCycles();
            if (cycles >= total) { return :running_long_break; }
            if (model.getCurrentCycle() > cycles) { return :running_work; }
            return :running_short_break;
        }
        return :running_work;
    }

    private function _getPhaseColor(phase as Lang.Symbol) as Lang.Number {
        if (phase == :running_work) { return Colors.BRAND; }
        if (phase == :running_short_break) { return Colors.TEXT_MUTED; }
        return Colors.ACCENT;
    }

    private function _getDimColor(phase as Lang.Symbol) as Lang.Number {
        if (phase == :running_work) { return Colors.BRAND_DIM; }
        if (phase == :running_short_break) { return Colors.TEXT_MUTED_DIM; }
        return Colors.ACCENT_DIM;
    }

    private function _getPhaseText(phase as Lang.Symbol) as Lang.String {
        if (phase == :running_work) { return "FOCUS"; }
        if (phase == :running_short_break) { return "BREAK"; }
        return "LONG BREAK";
    }
}
