using Toybox.Lang;

class RecoveryState {
    var preset as Preset;
    var state as Lang.Number;
    var remainingSeconds as Lang.Number;
    var cyclesCompleted as Lang.Number;
    var currentCycle as Lang.Number;

    function initialize(preset as Preset, state as Lang.Number, remainingSeconds as Lang.Number, cyclesCompleted as Lang.Number, currentCycle as Lang.Number) {
        self.preset = preset;
        self.state = state;
        self.remainingSeconds = remainingSeconds;
        self.cyclesCompleted = cyclesCompleted;
        self.currentCycle = currentCycle;
    }
}
