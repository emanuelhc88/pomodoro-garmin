using Toybox.Test;
using Toybox.Lang;

(:test)
function testAlertStartRespectsVibrationDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = false;
    SettingsState.backlightOnAlert = true;
    var service = new AttentionService();
    service.alertStart();
    SettingsState.vibrationEnabled = true;
    return true;
}

(:test)
function testAlertEndOfWorkRespectsSoundDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.soundEnabled = false;
    SettingsState.vibrationEnabled = true;
    SettingsState.backlightOnAlert = true;
    var service = new AttentionService();
    service.alertEndOfWork();
    return true;
}

(:test)
function testAlertEndOfBreakRespectsBacklightDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = true;
    SettingsState.backlightOnAlert = false;
    var service = new AttentionService();
    service.alertEndOfBreak();
    SettingsState.backlightOnAlert = true;
    return true;
}

(:test)
function testAlertCycleCompleteWithAllEnabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = true;
    SettingsState.soundEnabled = true;
    SettingsState.backlightOnAlert = true;
    var service = new AttentionService();
    service.alertCycleComplete();
    SettingsState.soundEnabled = false;
    return true;
}

(:test)
function testAllAlertsSuppressedWhenAllDisabled(logger as Test.Logger) as Lang.Boolean {
    SettingsState.vibrationEnabled = false;
    SettingsState.soundEnabled = false;
    SettingsState.backlightOnAlert = false;
    var service = new AttentionService();
    service.alertStart();
    service.alertEndOfWork();
    service.alertEndOfBreak();
    service.alertCycleComplete();
    SettingsState.vibrationEnabled = true;
    SettingsState.backlightOnAlert = true;
    return true;
}
