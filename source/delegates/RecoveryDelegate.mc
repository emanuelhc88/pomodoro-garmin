using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class RecoveryDelegate extends Ui.BehaviorDelegate {
    private var _view as RecoveryView;
    private var _recoveryState as RecoveryState;

    function initialize(view as RecoveryView, recoveryState as RecoveryState) {
        BehaviorDelegate.initialize();
        _view = view;
        _recoveryState = recoveryState;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.setFocusIdx(0);
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.setFocusIdx(1);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var idx = _view.getFocusIdx();
        var app = App.getApp() as TomaApp;

        if (idx == 0) {
            app.resumeFromRecovery(_recoveryState);
            var model = app.getModel();
            Ui.switchToView(new TimerView(model), new TimerDelegate(), Ui.SLIDE_LEFT);
        } else {
            app.getRecoveryService().clear();
            var view = new HomeView();
            Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        app.getRecoveryService().clear();
        var view = new HomeView();
        Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
        return true;
    }
}
