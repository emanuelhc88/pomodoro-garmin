using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _attentionService = new AttentionService();
        _model.addObserver(method(:onModelEvent));
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }

    function getModel() as PomodoroModel {
        return _model;
    }

    function startSession(preset as Preset) as Void {
        _model.start(preset);
        _timerService.start(method(:onTimerTick), 1000);
    }

    function onTimerTick() as Void {
        if (_model.isPaused()) {
            return;
        }
        _model.tick();
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
    }

    function onModelEvent(event as Lang.Number) as Void {
        if (event == PomodoroEvent.ON_START) {
            _attentionService.alertStart();
        } else if (event == PomodoroEvent.ON_PHASE_CHANGE) {
            var state = _model.getState();
            if (state == PomodoroState.RUNNING_SHORT_BREAK || state == PomodoroState.RUNNING_LONG_BREAK) {
                _attentionService.alertEndOfWork();
            } else if (state == PomodoroState.RUNNING_WORK) {
                _attentionService.alertEndOfBreak();
            }
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), 0);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
    }
}
