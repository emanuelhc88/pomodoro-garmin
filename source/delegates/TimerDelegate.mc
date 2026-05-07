using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        app.stopSession();
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        if (app.getModel().isPaused()) {
            app.resumeSession();
        } else {
            app.pauseSession();
        }
        return true;
    }
}
