using Toybox.Application as App;
using Toybox.Lang;

class SettingsRepository {
    function getSoundEnabled() as Lang.Boolean {
        var v = App.Properties.getValue("soundEnabled");
        return (v != null) ? (v as Lang.Boolean) : false;
    }

    function setSoundEnabled(value as Lang.Boolean) as Void {
        App.Properties.setValue("soundEnabled", value);
    }

    function getVibrationEnabled() as Lang.Boolean {
        var v = App.Properties.getValue("vibrationEnabled");
        return (v != null) ? (v as Lang.Boolean) : true;
    }

    function setVibrationEnabled(value as Lang.Boolean) as Void {
        App.Properties.setValue("vibrationEnabled", value);
    }

    function getBacklightOnAlert() as Lang.Boolean {
        var v = App.Properties.getValue("backlightOnAlert");
        return (v != null) ? (v as Lang.Boolean) : true;
    }

    function setBacklightOnAlert(value as Lang.Boolean) as Void {
        App.Properties.setValue("backlightOnAlert", value);
    }

    function getRecordAsActivity() as Lang.Boolean {
        var v = App.Properties.getValue("recordAsActivity");
        return (v != null) ? (v as Lang.Boolean) : true;
    }

    function setRecordAsActivity(value as Lang.Boolean) as Void {
        App.Properties.setValue("recordAsActivity", value);
    }

    function getLanguage() as Lang.String {
        var v = App.Properties.getValue("language");
        return (v != null && v instanceof Lang.String) ? (v as Lang.String) : "auto";
    }

    function setLanguage(value as Lang.String) as Void {
        App.Properties.setValue("language", value);
    }

    function getLastSelectedPreset() as Lang.Number {
        var v = App.Properties.getValue("lastSelectedPreset");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 0;
    }

    function setLastSelectedPreset(value as Lang.Number) as Void {
        App.Properties.setValue("lastSelectedPreset", value);
    }

    function getCustomWorkMin() as Lang.Number {
        var v = App.Properties.getValue("customWorkMin");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 25;
    }

    function setCustomWorkMin(value as Lang.Number) as Void {
        App.Properties.setValue("customWorkMin", value);
    }

    function getCustomBreakMin() as Lang.Number {
        var v = App.Properties.getValue("customBreakMin");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 5;
    }

    function setCustomBreakMin(value as Lang.Number) as Void {
        App.Properties.setValue("customBreakMin", value);
    }

    function getCustomCycles() as Lang.Number {
        var v = App.Properties.getValue("customCycles");
        return (v != null && v instanceof Lang.Number) ? (v as Lang.Number) : 4;
    }

    function setCustomCycles(value as Lang.Number) as Void {
        App.Properties.setValue("customCycles", value);
    }
}
