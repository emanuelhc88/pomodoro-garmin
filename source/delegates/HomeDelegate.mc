using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Lang;

class HomeDelegate extends Ui.BehaviorDelegate {
    private var _view as HomeView;
    private var _demoIdx as Lang.Number = 0;

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
        var phases = [:running_work, :running_short_break, :running_long_break];
        var remaining = [900, 180, 420];
        var totals = [1500, 300, 600];
        var completed = [2, 2, 3];

        var idx = _demoIdx % 3;
        Ui.pushView(
            new TimerView(phases[idx], remaining[idx], totals[idx], completed[idx], 4),
            new TimerDelegate(),
            Ui.SLIDE_LEFT
        );
        _demoIdx++;
        return true;
    }

    function onMenu() as Lang.Boolean {
        Sys.println("Menu pressed");
        return true;
    }
}
