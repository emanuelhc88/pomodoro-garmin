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
        var selectedIndex = _view.getSelectedIndex();

        if (selectedIndex == 3) {
            var view = new CustomBuilderView();
            Ui.pushView(view, new CustomBuilderDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }

        if (selectedIndex == 4) {
            Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_LEFT);
            return true;
        }

        var idx = _demoIdx % 8;

        if (idx < 4) {
            var phases = [:running_work, :running_short_break, :running_long_break, :running_work];
            var remaining = [900, 180, 420, 900];
            var totals = [1500, 300, 600, 1500];
            var completed = [2, 2, 3, 2];
            var paused = [false, false, false, true];

            Ui.pushView(
                new TimerView(phases[idx], remaining[idx], totals[idx], completed[idx], 4, paused[idx]),
                new TimerDelegate(),
                Ui.SLIDE_LEFT
            );
        } else if (idx < 7) {
            var transPhases = [:focus, :break, :long_break];
            var sessionNums = [2, 3, 4];
            var phaseIdx = idx - 4;
            var view = new PhaseTransitionView(transPhases[phaseIdx], sessionNums[phaseIdx], 4);
            Ui.pushView(
                view,
                new PhaseTransitionDelegate(view),
                Ui.SLIDE_LEFT
            );
        } else {
            var view = new CycleCompleteView(4, 4, 8);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.pushView(view, delegate, Ui.SLIDE_LEFT);
        }

        _demoIdx++;
        return true;
    }

    function onMenu() as Lang.Boolean {
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}
