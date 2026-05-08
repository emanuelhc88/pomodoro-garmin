using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
    private var _counterRepo as CounterRepository;
    private var _settingsRepo as SettingsRepository;
    private var _presetRepo as PresetRepository;
    private var _recoveryService as RecoveryService;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _settingsRepo = new SettingsRepository();
        _presetRepo = new PresetRepository(_settingsRepo);
        _recoveryService = new RecoveryService();
        _attentionService = new AttentionService(_settingsRepo);
        _counterRepo = new CounterRepository();
        _model.addObserver(method(:onModelEvent));
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var recovery = _recoveryService.checkOnStart();
        if (recovery != null) {
            var rs = recovery as RecoveryState;
            var view = new RecoveryView(rs.remainingSeconds);
            var delegate = new RecoveryDelegate(view, rs);
            return [view, delegate];
        }
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }

    function getModel() as PomodoroModel {
        return _model;
    }

    function startSession(preset as Preset) as Void {
        _lastPreset = preset;
        _skipNextPhaseChange = true;
        _model.start(preset);
        _timerService.start(method(:onTimerTick), 1000);
    }

    function onTimerTick() as Void {
        if (_model.isPaused()) {
            return;
        }
        _model.tick();
        _recoveryService.persistThrottled(_model);
        Ui.requestUpdate();
    }

    function pauseSession() as Void {
        _model.pause();
        Ui.requestUpdate();
    }

    function resumeSession() as Void {
        _model.resume();
        Ui.requestUpdate();
    }

    function stopSession() as Void {
        _model.stop();
        _timerService.stop();
        _recoveryService.clear();
    }

    function onModelEvent(event as Lang.Number) as Void {
        if (event == PomodoroEvent.ON_START) {
            _attentionService.alertStart();
        } else if (event == PomodoroEvent.ON_PHASE_CHANGE) {
            if (_skipNextPhaseChange) {
                _skipNextPhaseChange = false;
                return;
            }
            var state = _model.getState();
            if (state == PomodoroState.COMPLETED) {
                return;
            }
            if (state == PomodoroState.RUNNING_SHORT_BREAK || state == PomodoroState.RUNNING_LONG_BREAK) {
                _attentionService.alertEndOfWork();
            } else if (state == PomodoroState.RUNNING_WORK) {
                _attentionService.alertEndOfBreak();
            }
            var phase = _stateToTransitionPhase(state);
            var view = new PhaseTransitionView(phase, _model.getCurrentCycle(), _model.getTotalCycles());
            Ui.pushView(view, new PhaseTransitionDelegate(view), Ui.SLIDE_LEFT);
        } else if (event == PomodoroEvent.ON_WORK_PHASE_COMPLETE) {
            _counterRepo.increment();
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            _recoveryService.clear();
            var todaySessions = _counterRepo.getTodayCount();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), todaySessions);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
    }

    private function _stateToTransitionPhase(state as Lang.Number) as Lang.Symbol {
        if (state == PomodoroState.RUNNING_WORK) { return :focus; }
        if (state == PomodoroState.RUNNING_SHORT_BREAK) { return :break; }
        return :long_break;
    }

    function getLastPreset() as Preset or Null {
        return _lastPreset;
    }

    function getSettingsRepo() as SettingsRepository {
        return _settingsRepo;
    }

    function getPresetRepo() as PresetRepository {
        return _presetRepo;
    }

    function getRecoveryService() as RecoveryService {
        return _recoveryService;
    }

    function resumeFromRecovery(recovery as RecoveryState) as Void {
        _skipNextPhaseChange = true;
        _model.hydrate(recovery.preset, recovery.state, recovery.remainingSeconds, recovery.cyclesCompleted, recovery.currentCycle);
        _timerService.start(method(:onTimerTick), 1000);
    }
}
