using Toybox.Lang;

class PresetRepository {
    private var _settings as SettingsRepository;

    function initialize(settings as SettingsRepository) {
        _settings = settings;
    }

    function loadCustom() as Preset {
        var work = _clampWork(_settings.getCustomWorkMin());
        var brk = _clampBreak(_settings.getCustomBreakMin());
        var cycles = _clampCycles(_settings.getCustomCycles());
        return new Preset(work, brk, cycles, true);
    }

    function saveCustom(preset as Preset) as Void {
        _settings.setCustomWorkMin(_clampWork(preset.workMin));
        _settings.setCustomBreakMin(_clampBreak(preset.breakMin));
        _settings.setCustomCycles(_clampCycles(preset.cycles));
    }

    private function _clampWork(v as Lang.Number) as Lang.Number {
        if (v < PresetLimits.WORK_MIN) { return PresetLimits.WORK_MIN; }
        if (v > PresetLimits.WORK_MAX) { return PresetLimits.WORK_MAX; }
        return v;
    }

    private function _clampBreak(v as Lang.Number) as Lang.Number {
        if (v < PresetLimits.BREAK_MIN) { return PresetLimits.BREAK_MIN; }
        if (v > PresetLimits.BREAK_MAX) { return PresetLimits.BREAK_MAX; }
        return v;
    }

    private function _clampCycles(v as Lang.Number) as Lang.Number {
        if (v < PresetLimits.CYCLES_MIN) { return PresetLimits.CYCLES_MIN; }
        if (v > PresetLimits.CYCLES_MAX) { return PresetLimits.CYCLES_MAX; }
        return v;
    }
}
