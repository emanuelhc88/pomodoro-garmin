using Toybox.Lang;

module PomodoroState {
    enum {
        IDLE,
        RUNNING_WORK,
        RUNNING_SHORT_BREAK,
        RUNNING_LONG_BREAK,
        PAUSED,
        COMPLETED
    }

    function isRunning(state as Lang.Number) as Lang.Boolean {
        return (state == RUNNING_WORK || state == RUNNING_SHORT_BREAK || state == RUNNING_LONG_BREAK);
    }
}
