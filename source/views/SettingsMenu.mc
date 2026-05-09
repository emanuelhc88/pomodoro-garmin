using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Strings.get(:settings_title)});

        var app = App.getApp() as TomaApp;
        var repo = app.getSettingsRepo();

        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_sound),
            null,
            :soundEnabled,
            repo.getSoundEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_vibration),
            null,
            :vibrationEnabled,
            repo.getVibrationEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_backlight),
            null,
            :backlightOnAlert,
            repo.getBacklightOnAlert(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_record_activity),
            null,
            :recordAsActivity,
            repo.getRecordAsActivity(),
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:settings_language),
            getLanguageSubLabel(repo),
            :language,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:settings_history),
            null,
            :history,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:settings_about),
            null,
            :about,
            null
        ));
    }

    function getLanguageSubLabel(repo as SettingsRepository) as Lang.String {
        var lang = repo.getLanguage();
        if (lang.equals("en")) {
            return Strings.get(:language_en);
        }
        if (lang.equals("pt")) {
            return Strings.get(:language_pt);
        }
        return Strings.get(:language_auto);
    }
}
