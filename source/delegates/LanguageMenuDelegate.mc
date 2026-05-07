using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (id == :auto) {
            SettingsState.language = "auto";
        } else if (id == :en) {
            SettingsState.language = "en";
        } else if (id == :pt) {
            SettingsState.language = "pt";
        }

        Ui.popView(Ui.SLIDE_RIGHT);
    }
}
