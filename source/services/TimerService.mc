using Toybox.Timer;
using Toybox.Lang;

class TimerService {
    private var _timer as Timer.Timer;
    private var _running as Lang.Boolean = false;

    function initialize() {
        _timer = new Timer.Timer();
    }

    function start(callback as Lang.Method, intervalMs as Lang.Number) as Void {
        _timer.start(callback, intervalMs, true);
        _running = true;
    }

    function stop() as Void {
        _timer.stop();
        _running = false;
    }

    function isRunning() as Lang.Boolean {
        return _running;
    }
}
