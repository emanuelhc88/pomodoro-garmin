using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class TomaApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        var view = new HomeView();
        var delegate = new HomeDelegate(view);
        return [view, delegate];
    }
}
