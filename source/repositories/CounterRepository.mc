using Toybox.Application as App;
using Toybox.Lang;

class CounterRepository {
    private const STORAGE_KEY = "dailyCounter";

    function getTodayCount() as Lang.Number {
        var data = _load();
        return data["count"] as Lang.Number;
    }

    function increment() as Void {
        var data = _load();
        var count = data["count"] as Lang.Number;
        data["count"] = count + 1;
        App.Storage.setValue(STORAGE_KEY, data);
    }

    private function _load() as Lang.Dictionary {
        var stored = App.Storage.getValue(STORAGE_KEY);
        var today = DateUtils.today();

        if (stored instanceof Lang.Dictionary) {
            var dict = stored as Lang.Dictionary;
            if (dict.hasKey("date") && dict.hasKey("count")) {
                var storedDate = dict["date"];
                if (storedDate instanceof Lang.String && DateUtils.isSameDay(storedDate as Lang.String, today)) {
                    return dict;
                }
            }
        }

        return { "date" => today, "count" => 0 };
    }
}
