using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});

        var app = App.getApp() as TomaApp;
        var repo = app.getSettingsRepo();

        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound) as Lang.String,
            null,
            :soundEnabled,
            repo.getSoundEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration) as Lang.String,
            null,
            :vibrationEnabled,
            repo.getVibrationEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_backlight) as Lang.String,
            null,
            :backlightOnAlert,
            repo.getBacklightOnAlert(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_record_activity) as Lang.String,
            null,
            :recordAsActivity,
            repo.getRecordAsActivity(),
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language) as Lang.String,
            getLanguageSubLabel(repo),
            :language,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_history) as Lang.String,
            null,
            :history,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_about) as Lang.String,
            null,
            :about,
            null
        ));
    }

    function getLanguageSubLabel(repo as SettingsRepository) as Lang.String {
        var lang = repo.getLanguage();
        if (lang.equals("en")) {
            return Ui.loadResource(Rez.Strings.language_en) as Lang.String;
        }
        if (lang.equals("pt")) {
            return Ui.loadResource(Rez.Strings.language_pt) as Lang.String;
        }
        return Ui.loadResource(Rez.Strings.language_auto) as Lang.String;
    }
}
