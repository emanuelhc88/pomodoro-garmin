using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class CustomBuilderView extends Ui.View {
    private var _selectedLine as Lang.Number = 0;
    private var _editing as Lang.Boolean = false;
    private var _workMin as Lang.Number;
    private var _breakMin as Lang.Number;
    private var _cycles as Lang.Number;
    private var _editStartValue as Lang.Number = 0;

    private var _titleStr as Lang.String;
    private var _labelWork as Lang.String;
    private var _labelBreak as Lang.String;
    private var _labelCycles as Lang.String;
    private var _unitMin as Lang.String;
    private var _hintsNav as Lang.String;
    private var _hintsEdit as Lang.String;

    function initialize(workMin as Lang.Number, breakMin as Lang.Number, cycles as Lang.Number) {
        View.initialize();
        _workMin = workMin;
        _breakMin = breakMin;
        _cycles = cycles;
        _titleStr = Strings.get(:custom_builder_title);
        _labelWork = Strings.get(:custom_label_work);
        _labelBreak = Strings.get(:custom_label_break);
        _labelCycles = Strings.get(:custom_label_cycles);
        _unitMin = Strings.get(:unit_min);
        _hintsNav = Strings.get(:hints_nav);
        _hintsEdit = Strings.get(:hints_edit);
    }

    function getSelectedLine() as Lang.Number {
        return _selectedLine;
    }

    function isEditing() as Lang.Boolean {
        return _editing;
    }

    function moveUp() as Void {
        _selectedLine = (_selectedLine - 1 + 3) % 3;
        Ui.requestUpdate();
    }

    function moveDown() as Void {
        _selectedLine = (_selectedLine + 1) % 3;
        Ui.requestUpdate();
    }

    function enterEdit() as Void {
        _editStartValue = _getCurrentValue();
        _editing = true;
        Ui.requestUpdate();
    }

    function confirmEdit() as Void {
        _editing = false;
        Ui.requestUpdate();
    }

    function cancelEdit() as Void {
        _setCurrentValue(_editStartValue);
        _editing = false;
        Ui.requestUpdate();
    }

    function incrementValue() as Void {
        var val = _getCurrentValue();
        var step = _getStep();
        var max = _getMax();
        val = val + step;
        if (val > max) { val = max; }
        _setCurrentValue(val);
        Ui.requestUpdate();
    }

    function decrementValue() as Void {
        var val = _getCurrentValue();
        var step = _getStep();
        var min = _getMin();
        val = val - step;
        if (val < min) { val = min; }
        _setCurrentValue(val);
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var lineH = Dimensions.customLineHeight(bucket);
        var line1Y = Dimensions.customLine1Y(bucket);
        var lineSpacing = Dimensions.customLineSpacing(bucket);
        var hintsY = Dimensions.customHintsY(bucket);
        var lineW = w * 80 / 100;
        var lineX = (w - lineW) / 2;

        if (bucket != :small) {
            var titleY = Dimensions.customTitleY(bucket);
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, titleY, Gfx.FONT_TINY, _titleStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var line2Y = line1Y + lineH + lineSpacing;
        var line3Y = line2Y + lineH + lineSpacing;

        SpecLine.draw(dc, lineX, line1Y, lineW, lineH, _labelWork, _workMin, _unitMin, _selectedLine == 0 && !_editing, _selectedLine == 0 && _editing, bucket);
        SpecLine.draw(dc, lineX, line2Y, lineW, lineH, _labelBreak, _breakMin, _unitMin, _selectedLine == 1 && !_editing, _selectedLine == 1 && _editing, bucket);
        SpecLine.draw(dc, lineX, line3Y, lineW, lineH, _labelCycles, _cycles, "", _selectedLine == 2 && !_editing, _selectedLine == 2 && _editing, bucket);

        var hintText = _editing ? _hintsEdit : _hintsNav;
        Hints.draw(dc, centerX, hintsY, hintText, bucket);
    }

    private function _getCurrentValue() as Lang.Number {
        if (_selectedLine == 0) { return _workMin; }
        if (_selectedLine == 1) { return _breakMin; }
        return _cycles;
    }

    private function _setCurrentValue(val as Lang.Number) as Void {
        if (_selectedLine == 0) { _workMin = val; }
        else if (_selectedLine == 1) { _breakMin = val; }
        else { _cycles = val; }
    }

    private function _getStep() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_STEP; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_STEP; }
        return PresetLimits.CYCLES_STEP;
    }

    private function _getMin() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_MIN; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_MIN; }
        return PresetLimits.CYCLES_MIN;
    }

    private function _getMax() as Lang.Number {
        if (_selectedLine == 0) { return PresetLimits.WORK_MAX; }
        if (_selectedLine == 1) { return PresetLimits.BREAK_MAX; }
        return PresetLimits.CYCLES_MAX;
    }

    function buildPreset() as Preset {
        return new Preset(_workMin, _breakMin, _cycles, true);
    }
}
