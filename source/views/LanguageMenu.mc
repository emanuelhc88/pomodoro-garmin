using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Strings.get(:settings_language)});

        addItem(new Ui.MenuItem(
            Strings.get(:language_auto),
            null,
            :auto,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:language_en),
            null,
            :en,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:language_pt),
            null,
            :pt,
            null
        ));
    }
}
