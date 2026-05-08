using Toybox.Test;
using Toybox.Lang;

(:test)
function testTodayReturnsFormattedDate(logger as Test.Logger) as Lang.Boolean {
    var result = DateUtils.today();
    Test.assert(result.length() == 10);
    Test.assertEqualMessage("-", result.substring(4, 5), "Should have dash at pos 4");
    Test.assertEqualMessage("-", result.substring(7, 8), "Should have dash at pos 7");
    return true;
}

(:test)
function testIsSameDayTrue(logger as Test.Logger) as Lang.Boolean {
    Test.assert(DateUtils.isSameDay("2026-05-08", "2026-05-08"));
    return true;
}

(:test)
function testIsSameDayFalse(logger as Test.Logger) as Lang.Boolean {
    Test.assert(!DateUtils.isSameDay("2026-05-08", "2026-05-09"));
    return true;
}
