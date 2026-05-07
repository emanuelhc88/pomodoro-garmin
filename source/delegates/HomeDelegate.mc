using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class HomeDelegate extends Ui.BehaviorDelegate {
    private var _view as HomeView;

    function initialize(view as HomeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.navigateUp();
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.navigateDown();
        return true;
    }

    function onSelect() as Lang.Boolean {
        Sys.println("Selected preset: " + _view.getSelectedIndex());
        return true;
    }

    function onMenu() as Lang.Boolean {
        Sys.println("Menu pressed");
        return true;
    }
}
