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
