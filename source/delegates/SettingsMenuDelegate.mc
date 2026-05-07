using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (item instanceof Ui.ToggleMenuItem) {
            var toggle = item as Ui.ToggleMenuItem;
            if (id == :soundEnabled) {
                SettingsState.soundEnabled = toggle.isEnabled();
            } else if (id == :vibrationEnabled) {
                SettingsState.vibrationEnabled = toggle.isEnabled();
            } else if (id == :backlightOnAlert) {
                SettingsState.backlightOnAlert = toggle.isEnabled();
            } else if (id == :recordAsActivity) {
                SettingsState.recordAsActivity = toggle.isEnabled();
            }
            return;
        }

        if (id == :language) {
            Ui.pushView(new LanguageMenu(), new LanguageMenuDelegate(), Ui.SLIDE_LEFT);
        } else if (id == :history) {
            var view = new HistoryView();
            Ui.pushView(view, new HistoryDelegate(view), Ui.SLIDE_LEFT);
        } else if (id == :about) {
            Ui.pushView(new AboutView(), new AboutDelegate(), Ui.SLIDE_LEFT);
        }
    }
}
