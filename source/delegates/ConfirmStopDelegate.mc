using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class ConfirmStopDelegate extends Ui.BehaviorDelegate {
    private var _view as ConfirmStopView;

    function initialize(view as ConfirmStopView) {
        BehaviorDelegate.initialize();
        _view = view;
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
        if (idx == 0) {
            Ui.popView(Ui.SLIDE_DOWN);
        } else {
            var app = App.getApp() as TomaApp;
            app.stopSession();
            var view = new HomeView();
            Ui.switchToView(view, new HomeDelegate(view), Ui.SLIDE_RIGHT);
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_DOWN);
        return true;
    }
}
