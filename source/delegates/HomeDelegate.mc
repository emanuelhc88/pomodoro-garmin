using Toybox.Application as App;
using Toybox.WatchUi as Ui;
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

        var presets = Presets.builtinList();
        var preset = presets[selectedIndex] as Preset;
        var app = App.getApp() as TomaApp;
        app.startSession(preset);
        Ui.pushView(new TimerView(app.getModel()), new TimerDelegate(), Ui.SLIDE_LEFT);
        return true;
    }

    function onMenu() as Lang.Boolean {
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}
