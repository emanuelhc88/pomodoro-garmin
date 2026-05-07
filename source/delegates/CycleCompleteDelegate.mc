using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class CycleCompleteDelegate extends Ui.BehaviorDelegate {
    private var _view as CycleCompleteView?;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function setView(view as CycleCompleteView) as Void {
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        if (_view != null) {
            _view.setFocusIdx(0);
        }
        return true;
    }

    function onNextPage() as Lang.Boolean {
        if (_view != null) {
            _view.setFocusIdx(1);
        }
        return true;
    }

    function onSelect() as Lang.Boolean {
        if (_view != null) {
            var idx = _view.getFocusIdx();
            if (idx == 0) {
                var app = App.getApp() as TomaApp;
                var preset = app.getLastPreset();
                if (preset != null) {
                    app.startSession(preset);
                    Ui.switchToView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
                } else {
                    _navigateHome();
                }
            } else {
                _navigateHome();
            }
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        _navigateHome();
        return true;
    }

    private function _navigateHome() as Void {
        var view = new HomeView();
        Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
    }
}
