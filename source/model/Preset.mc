using Toybox.Lang;

module PresetLimits {
    const WORK_MIN = 5;
    const WORK_MAX = 90;
    const WORK_STEP = 5;
    const BREAK_MIN = 1;
    const BREAK_MAX = 30;
    const BREAK_STEP = 1;
    const CYCLES_MIN = 1;
    const CYCLES_MAX = 10;
    const CYCLES_STEP = 1;
}

class Preset {
    var workMin as Lang.Number;
    var breakMin as Lang.Number;
    var cycles as Lang.Number;
    var isCustom as Lang.Boolean;

    function initialize(workMin as Lang.Number, breakMin as Lang.Number, cycles as Lang.Number, isCustom as Lang.Boolean) {
        self.workMin = workMin;
        self.breakMin = breakMin;
        self.cycles = cycles;
        self.isCustom = isCustom;
    }

    function formatPrimary() as Lang.String {
        return Lang.format("$1$ / $2$", [workMin, breakMin]);
    }

    function formatSecondary(cyclesLabel as Lang.String) as Lang.String {
        return Lang.format("$1$ $2$", [cycles, cyclesLabel]);
    }

    function getLongBreakSeconds() as Lang.Number {
        return breakMin * 60 * 3;
    }

    function toDict() as Lang.Dictionary {
        return {
            "workMin" => workMin,
            "breakMin" => breakMin,
            "cycles" => cycles,
            "isCustom" => isCustom
        };
    }

    static function fromDict(dict as Lang.Dictionary) as Preset {
        return new Preset(
            dict["workMin"] as Lang.Number,
            dict["breakMin"] as Lang.Number,
            dict["cycles"] as Lang.Number,
            dict["isCustom"] as Lang.Boolean
        );
    }
}

module Presets {
    function builtinList() as Lang.Array<Preset> {
        return [
            new Preset(25, 5, 4, false),
            new Preset(30, 5, 4, false),
            new Preset(50, 10, 4, false),
            new Preset(25, 5, 4, true)
        ];
    }
}