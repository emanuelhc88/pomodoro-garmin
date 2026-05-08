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

    function toDict() as Lang.Dictionary {
        return {
            "completedAt" => completedAt,
            "preset" => preset,
            "workMin" => workMin,
            "breakMin" => breakMin,
            "cycles" => cycles,
            "totalDuration" => totalDuration
        };
    }

    static function fromDict(d as Lang.Dictionary) as Session {
        return new Session(
            (d.hasKey("completedAt") ? d["completedAt"] : 0) as Lang.Number,
            (d.hasKey("preset") ? d["preset"] : "") as Lang.String,
            (d.hasKey("workMin") ? d["workMin"] : 25) as Lang.Number,
            (d.hasKey("breakMin") ? d["breakMin"] : 5) as Lang.Number,
            (d.hasKey("cycles") ? d["cycles"] : 4) as Lang.Number,
            (d.hasKey("totalDuration") ? d["totalDuration"] : 0) as Lang.Number
        );
    }
}
