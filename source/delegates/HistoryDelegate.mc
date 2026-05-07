using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HistoryDelegate extends Ui.BehaviorDelegate {
    private var _view as HistoryView;

    function initialize(view as HistoryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Lang.Boolean {
        _view.scrollDown();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.scrollUp();
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}
