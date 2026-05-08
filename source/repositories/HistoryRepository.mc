using Toybox.Application as App;
using Toybox.Lang;

class HistoryRepository {
    private const STORAGE_KEY = "sessionHistory";
    private const MAX_ENTRIES = 50;

    function loadAll() as Lang.Array<Session> {
        var stored = App.Storage.getValue(STORAGE_KEY);
        if (!(stored instanceof Lang.Array)) {
            return [] as Lang.Array<Session>;
        }
        var list = stored as Lang.Array;
        var sessions = [] as Lang.Array<Session>;
        for (var i = 0; i < list.size(); i++) {
            var item = list[i];
            if (item instanceof Lang.Dictionary) {
                sessions.add(Session.fromDict(item as Lang.Dictionary));
            }
        }
        return sessions;
    }

    function append(session as Session) as Void {
        var stored = App.Storage.getValue(STORAGE_KEY);
        var list;
        if (stored instanceof Lang.Array) {
            list = stored as Lang.Array<Lang.Dictionary>;
        } else {
            list = [] as Lang.Array<Lang.Dictionary>;
        }
        list.add(session.toDict());
        if (list.size() > MAX_ENTRIES) {
            list = list.slice(1, null) as Lang.Array<Lang.Dictionary>;
        }
        App.Storage.setValue(STORAGE_KEY, list);
    }
}
