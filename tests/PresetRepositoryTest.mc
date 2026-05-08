using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testLoadCustomDefaults(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("customWorkMin", null);
    App.Properties.setValue("customBreakMin", null);
    App.Properties.setValue("customCycles", null);
    var repo = new PresetRepository(new SettingsRepository());
    var preset = repo.loadCustom();
    Test.assertEqualMessage(25, preset.workMin, "Default work should be 25");
    Test.assertEqualMessage(5, preset.breakMin, "Default break should be 5");
    Test.assertEqualMessage(4, preset.cycles, "Default cycles should be 4");
    Test.assertEqualMessage(true, preset.isCustom, "Should be marked as custom");
    return true;
}

(:test)
function testSaveAndLoadCustom(logger as Test.Logger) as Lang.Boolean {
    var repo = new PresetRepository(new SettingsRepository());
    var preset = new Preset(45, 8, 5, true);
    repo.saveCustom(preset);
    var loaded = repo.loadCustom();
    Test.assertEqualMessage(45, loaded.workMin, "Work should be 45");
    Test.assertEqualMessage(8, loaded.breakMin, "Break should be 8");
    Test.assertEqualMessage(5, loaded.cycles, "Cycles should be 5");
    return true;
}

(:test)
function testClampWorkAboveMax(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomWorkMin(200);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(90, preset.workMin, "Work above max should clamp to 90");
    return true;
}

(:test)
function testClampWorkBelowMin(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomWorkMin(1);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(5, preset.workMin, "Work below min should clamp to 5");
    return true;
}

(:test)
function testClampBreakAboveMax(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomBreakMin(60);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(30, preset.breakMin, "Break above max should clamp to 30");
    return true;
}

(:test)
function testClampCyclesBelowMin(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    settings.setCustomCycles(0);
    var repo = new PresetRepository(settings);
    var preset = repo.loadCustom();
    Test.assertEqualMessage(1, preset.cycles, "Cycles below min should clamp to 1");
    return true;
}

(:test)
function testSaveClampsToo(logger as Test.Logger) as Lang.Boolean {
    var settings = new SettingsRepository();
    var repo = new PresetRepository(settings);
    var badPreset = new Preset(999, 0, 99, true);
    repo.saveCustom(badPreset);
    Test.assertEqualMessage(90, settings.getCustomWorkMin(), "Saved work should be clamped to 90");
    Test.assertEqualMessage(1, settings.getCustomBreakMin(), "Saved break should be clamped to 1");
    Test.assertEqualMessage(10, settings.getCustomCycles(), "Saved cycles should be clamped to 10");
    return true;
}
