using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onSelect() as Lang.Boolean {
        Sys.println("TODO: pause/resume");
        return true;
    }
}
