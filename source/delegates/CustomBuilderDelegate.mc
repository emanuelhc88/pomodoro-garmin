using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class CustomBuilderDelegate extends Ui.BehaviorDelegate {
    private var _view as CustomBuilderView;

    function initialize(view as CustomBuilderView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.incrementValue();
        } else {
            _view.moveUp();
        }
        return true;
    }

    function onNextPage() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.decrementValue();
        } else {
            _view.moveDown();
        }
        return true;
    }

    function onSelect() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.confirmEdit();
        } else {
            _view.enterEdit();
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        if (_view.isEditing()) {
            _view.cancelEdit();
        } else {
            var app = App.getApp() as TomaApp;
            app.setCustomPreset(_view.buildPreset());
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
}
