using Toybox.Test;
using Toybox.Lang;

(:test)
function testBuiltinPresets(logger as Test.Logger) as Lang.Boolean {
    var list = Presets.builtinList();
    Test.assertEqualMessage(4, list.size(), "builtinList should have 4 entries");

    var p0 = list[0] as Preset;
    Test.assertEqualMessage(25, p0.workMin, "p0 workMin");
    Test.assertEqualMessage(5, p0.breakMin, "p0 breakMin");
    Test.assertEqualMessage(4, p0.cycles, "p0 cycles");

    var p1 = list[1] as Preset;
    Test.assertEqualMessage(30, p1.workMin, "p1 workMin");
    Test.assertEqualMessage(5, p1.breakMin, "p1 breakMin");
    Test.assertEqualMessage(4, p1.cycles, "p1 cycles");

    var p2 = list[2] as Preset;
    Test.assertEqualMessage(50, p2.workMin, "p2 workMin");
    Test.assertEqualMessage(10, p2.breakMin, "p2 breakMin");
    Test.assertEqualMessage(4, p2.cycles, "p2 cycles");

    var p3 = list[3] as Preset;
    Test.assertEqualMessage(25, p3.workMin, "p3 workMin");
    Test.assertEqualMessage(5, p3.breakMin, "p3 breakMin");
    Test.assertEqualMessage(4, p3.cycles, "p3 cycles");

    return true;
}

(:test)
function testBuiltinPresetsIsCustom(logger as Test.Logger) as Lang.Boolean {
    var list = Presets.builtinList();

    Test.assertEqualMessage(false, (list[0] as Preset).isCustom, "p0 should not be custom");
    Test.assertEqualMessage(false, (list[1] as Preset).isCustom, "p1 should not be custom");
    Test.assertEqualMessage(false, (list[2] as Preset).isCustom, "p2 should not be custom");
    Test.assertEqualMessage(true, (list[3] as Preset).isCustom, "p3 should be custom");

    return true;
}

(:test)
function testLongBreakDuration(logger as Test.Logger) as Lang.Boolean {
    var p1 = new Preset(25, 5, 4, false);
    Test.assertEqualMessage(900, p1.getLongBreakSeconds(), "25/5 long break should be 900s");

    var p2 = new Preset(50, 10, 4, false);
    Test.assertEqualMessage(1800, p2.getLongBreakSeconds(), "50/10 long break should be 1800s");

    return true;
}

(:test)
function testFormatMethods(logger as Test.Logger) as Lang.Boolean {
    var p = new Preset(25, 5, 4, false);
    Test.assertEqualMessage("25 / 5", p.formatPrimary(), "formatPrimary");
    Test.assertEqualMessage("4 cycles", p.formatSecondary("cycles"), "formatSecondary");

    return true;
}
