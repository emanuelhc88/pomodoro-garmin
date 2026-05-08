using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();
        var app = App.getApp() as TomaApp;
        var repo = app.getSettingsRepo();

        if (id == :auto) {
            repo.setLanguage("auto");
        } else if (id == :en) {
            repo.setLanguage("en");
        } else if (id == :pt) {
            repo.setLanguage("pt");
        }

        Ui.popView(Ui.SLIDE_RIGHT);
    }
}
