using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_language)});

        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.language_auto) as Lang.String,
            null,
            :auto,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.language_en) as Lang.String,
            null,
            :en,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.language_pt) as Lang.String,
            null,
            :pt,
            null
        ));
    }
}
