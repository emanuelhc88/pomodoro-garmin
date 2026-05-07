using Toybox.Graphics as Gfx;
using Toybox.Lang;

module HistoryItem {
    function draw(dc as Gfx.Dc, x as Lang.Number, y as Lang.Number, w as Lang.Number, session as Session, focused as Lang.Boolean, bucket as Lang.Symbol) as Void {
        var itemH = Dimensions.historyItemHeight(bucket);

        if (focused) {
            dc.setColor(Colors.BORDER, Colors.BORDER);
            dc.fillRectangle(x, y, w, itemH);
        }

        var textX = x + 10;
        var line1Y = y + Dimensions.historyItemLine1Offset(bucket);
        var line2Y = y + Dimensions.historyItemLine2Offset(bucket);
        var line3Y = y + Dimensions.historyItemLine3Offset(bucket);

        var dateFont = (bucket == :small) ? Gfx.FONT_TINY : Gfx.FONT_TINY;
        var durationFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_SMALL;
        var presetFont = (bucket == :small) ? Gfx.FONT_TINY : Gfx.FONT_XTINY;

        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, line1Y, dateFont, DateUtils.formatDate(session.completedAt), Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, line2Y, durationFont, TimeFormatter.formatDuration(session.totalDuration), Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, line3Y, presetFont, session.formatPreset(), Gfx.TEXT_JUSTIFY_LEFT);
    }
}
