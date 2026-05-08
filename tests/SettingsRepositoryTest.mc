using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testGetSoundEnabledDefault(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("soundEnabled", null);
    var repo = new SettingsRepository();
    Test.assertEqualMessage(false, repo.getSoundEnabled(), "Default soundEnabled should be false");
    return true;
}

(:test)
function testSetGetSoundEnabled(logger as Test.Logger) as Lang.Boolean {
    var repo = new SettingsRepository();
    repo.setSoundEnabled(true);
    Test.assertEqualMessage(true, repo.getSoundEnabled(), "Should read back true after set");
    repo.setSoundEnabled(false);
    Test.assertEqualMessage(false, repo.getSoundEnabled(), "Should read back false after set");
    return true;
}

(:test)
function testGetCustomWorkMinDefault(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("customWorkMin", null);
    var repo = new SettingsRepository();
    Test.assertEqualMessage(25, repo.getCustomWorkMin(), "Default customWorkMin should be 25");
    return true;
}

(:test)
function testSetGetCustomValues(logger as Test.Logger) as Lang.Boolean {
    var repo = new SettingsRepository();
    repo.setCustomWorkMin(50);
    repo.setCustomBreakMin(10);
    repo.setCustomCycles(3);
    Test.assertEqualMessage(50, repo.getCustomWorkMin(), "Work should be 50");
    Test.assertEqualMessage(10, repo.getCustomBreakMin(), "Break should be 10");
    Test.assertEqualMessage(3, repo.getCustomCycles(), "Cycles should be 3");
    return true;
}

(:test)
function testGetLastSelectedPresetDefault(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("lastSelectedPreset", null);
    var repo = new SettingsRepository();
    Test.assertEqualMessage(0, repo.getLastSelectedPreset(), "Default lastSelectedPreset should be 0");
    return true;
}
