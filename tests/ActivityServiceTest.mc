using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testActivityServiceStartWhenDisabled(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("recordAsActivity", false);
    var repo = new SettingsRepository();
    var service = new ActivityService(repo);
    service.start();
    Test.assert(!service.isRecording());
    App.Properties.setValue("recordAsActivity", true);
    return true;
}

(:test)
function testActivityServiceStopWithNoSession(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("recordAsActivity", true);
    var repo = new SettingsRepository();
    var service = new ActivityService(repo);
    service.stop();
    Test.assert(!service.isRecording());
    return true;
}

(:test)
function testActivityServiceDiscardWithNoSession(logger as Test.Logger) as Lang.Boolean {
    App.Properties.setValue("recordAsActivity", true);
    var repo = new SettingsRepository();
    var service = new ActivityService(repo);
    service.discard();
    Test.assert(!service.isRecording());
    return true;
}
