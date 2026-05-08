using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testHistoryLoadAllEmpty(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    var sessions = repo.loadAll();
    Test.assertEqualMessage(0, sessions.size(), "Empty storage should return empty array");
    return true;
}

(:test)
function testHistoryAppendOne(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    var session = new Session(1000000, "25/5/4", 25, 5, 4, 7200);
    repo.append(session);
    var sessions = repo.loadAll();
    Test.assertEqualMessage(1, sessions.size(), "After 1 append, should have 1 session");
    Test.assertEqualMessage(1000000, (sessions[0] as Session).completedAt, "completedAt should match");
    Test.assertEqualMessage("25/5/4", (sessions[0] as Session).preset, "preset should match");
    return true;
}

(:test)
function testHistoryAppendMultiple(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    repo.append(new Session(1000, "25/5/4", 25, 5, 4, 7200));
    repo.append(new Session(2000, "50/10/4", 50, 10, 4, 14400));
    repo.append(new Session(3000, "30/5/4", 30, 5, 4, 8400));
    var sessions = repo.loadAll();
    Test.assertEqualMessage(3, sessions.size(), "Should have 3 sessions");
    Test.assertEqualMessage(1000, (sessions[0] as Session).completedAt, "First should be oldest");
    Test.assertEqualMessage(3000, (sessions[2] as Session).completedAt, "Last should be newest");
    return true;
}

(:test)
function testHistoryTrimAt50(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    for (var i = 0; i < 52; i++) {
        repo.append(new Session(i * 1000, "25/5/4", 25, 5, 4, 7200));
    }
    var sessions = repo.loadAll();
    Test.assertEqualMessage(50, sessions.size(), "Should trim to 50 max");
    Test.assertEqualMessage(2000, (sessions[0] as Session).completedAt, "Oldest 2 should be trimmed");
    return true;
}

(:test)
function testHistoryCorruptedStorage(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("sessionHistory", "invalid");
    var repo = new HistoryRepository();
    var sessions = repo.loadAll();
    Test.assertEqualMessage(0, sessions.size(), "Corrupted storage should return empty array");
    return true;
}

(:test)
function testHistoryPersistsAcrossInstances(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo1 = new HistoryRepository();
    repo1.append(new Session(5000, "25/5/4", 25, 5, 4, 7200));
    var repo2 = new HistoryRepository();
    var sessions = repo2.loadAll();
    Test.assertEqualMessage(1, sessions.size(), "Should persist across instances");
    return true;
}
