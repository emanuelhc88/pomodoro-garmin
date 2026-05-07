using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
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
                Sys.println("Start again pressed");
            } else {
                Sys.println("Done pressed");
            }
        }
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}
