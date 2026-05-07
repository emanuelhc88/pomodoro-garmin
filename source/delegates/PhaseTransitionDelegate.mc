using Toybox.WatchUi as Ui;
using Toybox.Lang;

class PhaseTransitionDelegate extends Ui.BehaviorDelegate {
    private var _view as PhaseTransitionView;

    function initialize(view as PhaseTransitionView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Lang.Boolean {
        _view.dismiss();
        return true;
    }

    function onBack() as Lang.Boolean {
        _view.dismiss();
        return true;
    }

    function onKey(evt as Ui.KeyEvent) as Lang.Boolean {
        _view.dismiss();
        return true;
    }
}