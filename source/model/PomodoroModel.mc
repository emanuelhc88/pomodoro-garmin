using Toybox.Lang;
using Toybox.System;

class PomodoroModel {
    var _state as Lang.Number = PomodoroState.IDLE;
    var _preset as Preset or Null = null;
    var _remainingSeconds as Lang.Number = 0;
    var _totalPhaseSeconds as Lang.Number = 0;
    var _currentCycle as Lang.Number = 0;
    var _cyclesCompleted as Lang.Number = 0;
    var _paused as Lang.Boolean = false;
    var _observers as Lang.Array<Lang.Method> = [] as Lang.Array<Lang.Method>;

    function initialize() {
    }

    // --- Public API ---

    function start(preset as Preset) as Void {
        if (_state != PomodoroState.IDLE && _state != PomodoroState.COMPLETED) {
            _debugLog("start() ignored: not in IDLE or COMPLETED");
            return;
        }
        _preset = preset;
        _cyclesCompleted = 0;
        _currentCycle = 1;
        _paused = false;
        _state = PomodoroState.RUNNING_WORK;
        _remainingSeconds = preset.workMin * 60;
        _totalPhaseSeconds = _remainingSeconds;
        _emit(PomodoroEvent.ON_START);
        _emit(PomodoroEvent.ON_PHASE_CHANGE);
    }

    function tick() as Void {
        if (!PomodoroState.isRunning(_state) || _paused) {
            return;
        }
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _transitionPhase();
        } else {
            _emit(PomodoroEvent.ON_TICK);
        }
    }

    function pause() as Void {
        if (!PomodoroState.isRunning(_state) || _paused) {
            _debugLog("pause() ignored: not running or already paused");
            return;
        }
        _paused = true;
        _state = PomodoroState.PAUSED;
        _emit(PomodoroEvent.ON_PAUSE);
    }

    function resume() as Void {
        if (_state != PomodoroState.PAUSED) {
            _debugLog("resume() ignored: not paused");
            return;
        }
        _paused = false;
        _state = _getRunningStateForResume();
        _emit(PomodoroEvent.ON_RESUME);
    }

    function stop() as Void {
        if (_state == PomodoroState.IDLE || _state == PomodoroState.COMPLETED) {
            _debugLog("stop() ignored: already idle or completed");
            return;
        }
        _state = PomodoroState.IDLE;
        _paused = false;
        _remainingSeconds = 0;
        _totalPhaseSeconds = 0;
        _currentCycle = 0;
        _cyclesCompleted = 0;
        _preset = null;
        _emit(PomodoroEvent.ON_STOP);
    }

    function hydrate(preset as Preset, state as Lang.Number, remainingSeconds as Lang.Number, cyclesCompleted as Lang.Number, currentCycle as Lang.Number) as Void {
        _preset = preset;
        _state = state;
        _remainingSeconds = remainingSeconds;
        _cyclesCompleted = cyclesCompleted;
        _currentCycle = currentCycle;
        _paused = false;
        if (state == PomodoroState.RUNNING_WORK) {
            _totalPhaseSeconds = preset.workMin * 60;
        } else if (state == PomodoroState.RUNNING_SHORT_BREAK) {
            _totalPhaseSeconds = preset.breakMin * 60;
        } else if (state == PomodoroState.RUNNING_LONG_BREAK) {
            _totalPhaseSeconds = preset.getLongBreakSeconds();
        } else {
            _totalPhaseSeconds = remainingSeconds;
        }
        _emit(PomodoroEvent.ON_START);
        _emit(PomodoroEvent.ON_PHASE_CHANGE);
    }

    // --- Observers ---

    function addObserver(callback as Lang.Method) as Void {
        _observers.add(callback);
    }

    function removeObserver(callback as Lang.Method) as Void {
        var idx = _observers.indexOf(callback);
        if (idx != -1) {
            _observers.remove(callback);
        }
    }

    // --- Getters ---

    function getState() as Lang.Number {
        return _state;
    }

    function getRemainingSeconds() as Lang.Number {
        return _remainingSeconds;
    }

    function getTotalPhaseSeconds() as Lang.Number {
        return _totalPhaseSeconds;
    }

    function getCurrentCycle() as Lang.Number {
        return _currentCycle;
    }

    function getCyclesCompleted() as Lang.Number {
        return _cyclesCompleted;
    }

    function getTotalCycles() as Lang.Number {
        if (_preset != null) {
            return (_preset as Preset).cycles;
        }
        return 0;
    }

    function isPaused() as Lang.Boolean {
        return _paused;
    }

    function getPreset() as Preset or Null {
        return _preset;
    }

    // --- Private ---

    hidden function _transitionPhase() as Void {
        var preset = _preset as Preset;

        if (_state == PomodoroState.RUNNING_WORK) {
            _cyclesCompleted += 1;
            _emit(PomodoroEvent.ON_WORK_PHASE_COMPLETE);

            if (_cyclesCompleted >= preset.cycles) {
                if (preset.cycles == 1) {
                    _state = PomodoroState.COMPLETED;
                    _totalPhaseSeconds = 0;
                    _emit(PomodoroEvent.ON_PHASE_CHANGE);
                    _emit(PomodoroEvent.ON_COMPLETE);
                } else {
                    _state = PomodoroState.RUNNING_LONG_BREAK;
                    _remainingSeconds = preset.getLongBreakSeconds();
                    _totalPhaseSeconds = _remainingSeconds;
                    _emit(PomodoroEvent.ON_PHASE_CHANGE);
                }
            } else {
                _state = PomodoroState.RUNNING_SHORT_BREAK;
                _remainingSeconds = preset.breakMin * 60;
                _totalPhaseSeconds = _remainingSeconds;
                _emit(PomodoroEvent.ON_PHASE_CHANGE);
            }
        } else if (_state == PomodoroState.RUNNING_SHORT_BREAK) {
            _currentCycle += 1;
            _state = PomodoroState.RUNNING_WORK;
            _remainingSeconds = preset.workMin * 60;
            _totalPhaseSeconds = _remainingSeconds;
            _emit(PomodoroEvent.ON_PHASE_CHANGE);
        } else if (_state == PomodoroState.RUNNING_LONG_BREAK) {
            _state = PomodoroState.COMPLETED;
            _totalPhaseSeconds = 0;
            _emit(PomodoroEvent.ON_PHASE_CHANGE);
            _emit(PomodoroEvent.ON_COMPLETE);
        }
    }

    hidden function _getRunningStateForResume() as Lang.Number {
        if (_cyclesCompleted >= (_preset as Preset).cycles) {
            return PomodoroState.RUNNING_LONG_BREAK;
        }
        if (_currentCycle > _cyclesCompleted) {
            return PomodoroState.RUNNING_WORK;
        }
        return PomodoroState.RUNNING_SHORT_BREAK;
    }

    hidden function _emit(event as Lang.Number) as Void {
        for (var i = 0; i < _observers.size(); i++) {
            (_observers[i] as Lang.Method).invoke(event);
        }
    }

    hidden function _debugLog(msg as Lang.String) as Void {
        System.println("[PomodoroModel] " + msg);
    }
}
