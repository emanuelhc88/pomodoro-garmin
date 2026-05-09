using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        var view = new ConfirmStopView();
        Ui.pushView(view, new ConfirmStopDelegate(view), Ui.SLIDE_UP);
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

    function onMenu() as Lang.Boolean {
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}
