using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});

        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound) as Lang.String,
            null,
            :soundEnabled,
            SettingsState.soundEnabled,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration) as Lang.String,
            null,
            :vibrationEnabled,
            SettingsState.vibrationEnabled,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_backlight) as Lang.String,
            null,
            :backlightOnAlert,
            SettingsState.backlightOnAlert,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_record_activity) as Lang.String,
            null,
            :recordAsActivity,
            SettingsState.recordAsActivity,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language) as Lang.String,
            getLanguageSubLabel(),
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

    function getLanguageSubLabel() as Lang.String {
        if (SettingsState.language.equals("en")) {
            return Ui.loadResource(Rez.Strings.language_en) as Lang.String;
        }
        if (SettingsState.language.equals("pt")) {
            return Ui.loadResource(Rez.Strings.language_pt) as Lang.String;
        }
        return Ui.loadResource(Rez.Strings.language_auto) as Lang.String;
    }
}
