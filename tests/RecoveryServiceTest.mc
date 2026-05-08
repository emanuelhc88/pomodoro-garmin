using Toybox.Test;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Lang;

(:test)
function testCheckOnStartEmpty(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("activeSession");
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result == null);
    return true;
}

(:test)
function testCheckOnStartExpired(logger as Test.Logger) as Lang.Boolean {
    var now = Time.now().value();
    App.Storage.setValue("activeSession", {
        "savedAt" => now - 2000,
        "remaining" => 100,
        "state" => PomodoroState.RUNNING_WORK,
        "cyclesCompleted" => 0,
        "currentCycle" => 1,
        "workMin" => 25,
        "breakMin" => 5,
        "cycles" => 4,
        "isCustom" => false
    });
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result == null);
    return true;
}

(:test)
function testCheckOnStartValid(logger as Test.Logger) as Lang.Boolean {
    var now = Time.now().value();
    App.Storage.setValue("activeSession", {
        "savedAt" => now - 60,
        "remaining" => 600,
        "state" => PomodoroState.RUNNING_WORK,
        "cyclesCompleted" => 1,
        "currentCycle" => 2,
        "workMin" => 25,
        "breakMin" => 5,
        "cycles" => 4,
        "isCustom" => false
    });
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result != null);
    var rs = result as RecoveryState;
    Test.assert(rs.remainingSeconds >= 539 && rs.remainingSeconds <= 540);
    Test.assertEqualMessage(1, rs.cyclesCompleted, "cyclesCompleted should be 1");
    Test.assertEqualMessage(2, rs.currentCycle, "currentCycle should be 2");
    return true;
}

(:test)
function testCheckOnStartBelowThreshold(logger as Test.Logger) as Lang.Boolean {
    var now = Time.now().value();
    App.Storage.setValue("activeSession", {
        "savedAt" => now - 10,
        "remaining" => 65,
        "state" => PomodoroState.RUNNING_WORK,
        "cyclesCompleted" => 0,
        "currentCycle" => 1,
        "workMin" => 25,
        "breakMin" => 5,
        "cycles" => 4,
        "isCustom" => false
    });
    var service = new RecoveryService();
    var result = service.checkOnStart();
    Test.assert(result == null);
    return true;
}

(:test)
function testClearDeletesStorage(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("activeSession", { "savedAt" => 123 });
    var service = new RecoveryService();
    service.clear();
    Test.assert(App.Storage.getValue("activeSession") == null);
    return true;
}
