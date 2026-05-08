using Toybox.Application as App;
using Toybox.Time;
using Toybox.Lang;

class RecoveryService {
    private const STORAGE_KEY = "activeSession";
    private const MIN_RESUME_SECONDS = 60;
    private const THROTTLE_SECONDS = 5;
    private var _lastSavedAt as Lang.Number = 0;

    function checkOnStart() as RecoveryState or Null {
        var saved = App.Storage.getValue(STORAGE_KEY);
        if (saved == null || !(saved instanceof Lang.Dictionary)) {
            return null;
        }
        var dict = saved as Lang.Dictionary;

        if (!dict.hasKey("savedAt") || !dict.hasKey("remaining") ||
            !dict.hasKey("state") || !dict.hasKey("cyclesCompleted") ||
            !dict.hasKey("currentCycle") || !dict.hasKey("workMin") ||
            !dict.hasKey("breakMin") || !dict.hasKey("cycles") ||
            !dict.hasKey("isCustom")) {
            clear();
            return null;
        }

        var savedAt = dict["savedAt"] as Lang.Number;
        var remaining = dict["remaining"] as Lang.Number;
        var elapsed = Time.now().value() - savedAt;
        var newRemaining = remaining - elapsed;

        if (newRemaining < MIN_RESUME_SECONDS) {
            clear();
            return null;
        }

        var preset = new Preset(
            dict["workMin"] as Lang.Number,
            dict["breakMin"] as Lang.Number,
            dict["cycles"] as Lang.Number,
            dict["isCustom"] as Lang.Boolean
        );

        return new RecoveryState(
            preset,
            dict["state"] as Lang.Number,
            newRemaining,
            dict["cyclesCompleted"] as Lang.Number,
            dict["currentCycle"] as Lang.Number
        );
    }

    function persistThrottled(model as PomodoroModel) as Void {
        var now = Time.now().value();
        if (now - _lastSavedAt < THROTTLE_SECONDS) {
            return;
        }
        _lastSavedAt = now;

        var preset = model.getPreset();
        if (preset == null) {
            return;
        }
        var p = preset as Preset;

        var dict = {
            "savedAt" => now,
            "remaining" => model.getRemainingSeconds(),
            "state" => model.getState(),
            "cyclesCompleted" => model.getCyclesCompleted(),
            "currentCycle" => model.getCurrentCycle(),
            "workMin" => p.workMin,
            "breakMin" => p.breakMin,
            "cycles" => p.cycles,
            "isCustom" => p.isCustom
        };
        App.Storage.setValue(STORAGE_KEY, dict);
    }

    function clear() as Void {
        App.Storage.deleteValue(STORAGE_KEY);
        _lastSavedAt = 0;
    }
}
