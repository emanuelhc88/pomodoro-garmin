using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HistoryView extends Ui.View {
    private var _sessions as Lang.Array<Session>;
    private var _scrollOffset as Lang.Number;
    private var _focusIdx as Lang.Number;
    private var _visibleCount as Lang.Number;
    private var _titleText as Lang.String;
    private var _emptyText as Lang.String;

    function initialize() {
        View.initialize();
        _sessions = getMockSessions();
        _scrollOffset = 0;
        _focusIdx = 0;
        _visibleCount = 3;
        _titleText = Ui.loadResource(Rez.Strings.history_title) as Lang.String;
        _emptyText = Ui.loadResource(Rez.Strings.history_empty) as Lang.String;
    }

    function getSessionCount() as Lang.Number {
        return _sessions.size();
    }

    function getFocusIdx() as Lang.Number {
        return _focusIdx;
    }

    function scrollDown() as Void {
        if (_sessions.size() == 0) { return; }
        if (_focusIdx < _sessions.size() - 1) {
            _focusIdx++;
            if (_focusIdx >= _scrollOffset + _visibleCount) {
                _scrollOffset++;
            }
            Ui.requestUpdate();
        }
    }

    function scrollUp() as Void {
        if (_sessions.size() == 0) { return; }
        if (_focusIdx > 0) {
            _focusIdx--;
            if (_focusIdx < _scrollOffset) {
                _scrollOffset--;
            }
            Ui.requestUpdate();
        }
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var titleY = Dimensions.historyTitleY(bucket);
        var titleFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, titleFont, _titleText, Gfx.TEXT_JUSTIFY_CENTER);

        if (_sessions.size() == 0) {
            EmptyState.draw(dc, centerX, h / 2, _emptyText, bucket);
            return;
        }

        var listStartY = Dimensions.historyListStartY(bucket);
        var itemH = Dimensions.historyItemHeight(bucket);
        var itemPad = Dimensions.historyItemPadding(bucket);
        var totalItemH = itemH + itemPad;

        _visibleCount = (h - listStartY) / totalItemH;
        if (_visibleCount < 1) { _visibleCount = 1; }

        var itemX = 0;
        var itemW = w;
        var y = listStartY;

        var end = _scrollOffset + _visibleCount;
        if (end > _sessions.size()) { end = _sessions.size(); }

        for (var i = _scrollOffset; i < end; i++) {
            var session = _sessions[i] as Session;
            HistoryItem.draw(dc, itemX, y, itemW, session, i == _focusIdx, bucket);
            y += totalItemH;
        }
    }

    private function getMockSessions() as Lang.Array<Session> {
        var now = Time.now().value();
        var day = 86400;
        return [
            new Session(now - day * 0, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 1, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 1, "50/10/4", 50, 10, 4, 14400),
            new Session(now - day * 2, "30/5/4", 30, 5, 4, 8400),
            new Session(now - day * 3, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 4, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 5, "50/10/4", 50, 10, 4, 14400),
            new Session(now - day * 6, "30/5/4", 30, 5, 4, 8400),
            new Session(now - day * 7, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 8, "25/5/4", 25, 5, 4, 7200)
        ];
    }
}
