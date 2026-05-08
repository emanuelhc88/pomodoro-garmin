using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testIncrementFromZero(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("dailyCounter");
    var repo = new CounterRepository();
    repo.increment();
    Test.assertEqualMessage(1, repo.getTodayCount(), "After 1 increment, count should be 1");
    return true;
}

(:test)
function testIncrementMultiple(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("dailyCounter");
    var repo = new CounterRepository();
    repo.increment();
    repo.increment();
    repo.increment();
    Test.assertEqualMessage(3, repo.getTodayCount(), "After 3 increments, count should be 3");
    return true;
}

(:test)
function testResetOnNewDay(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("dailyCounter", { "date" => "2020-01-01", "count" => 5 });
    var repo = new CounterRepository();
    Test.assertEqualMessage(0, repo.getTodayCount(), "Old date should reset to 0");
    return true;
}

(:test)
function testCorruptedStorageReturnsZero(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("dailyCounter", "invalid");
    var repo = new CounterRepository();
    Test.assertEqualMessage(0, repo.getTodayCount(), "Corrupted data should return 0");
    return true;
}

(:test)
function testIncrementPersists(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("dailyCounter");
    var repo = new CounterRepository();
    repo.increment();
    var repo2 = new CounterRepository();
    Test.assertEqualMessage(1, repo2.getTodayCount(), "Count should persist across instances");
    return true;
}
