using Toybox.Graphics as Gfx;
using Toybox.Lang;

module SpecLine {
    function draw(
        dc as Gfx.Dc,
        x as Lang.Number,
        y as Lang.Number,
        w as Lang.Number,
        h as Lang.Number,
        label as Lang.String,
        value as Lang.Number,
        unit as Lang.String,
        isSelected as Lang.Boolean,
        isEditing as Lang.Boolean,
        bucket as Lang.Symbol
    ) as Void {
        var labelFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_SMALL;
        var valueFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        var unitFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var centerY = y + h / 2;

        if (isSelected || isEditing) {
            var highlightColor = isEditing ? Colors.BRAND : Colors.ACCENT;
            dc.setColor(highlightColor, highlightColor);
            dc.fillRectangle(x, y, w, h);
        }

        var labelColor = (isSelected || isEditing) ? Colors.TEXT_PRIMARY : Colors.TEXT_MUTED;
        dc.setColor(labelColor, Gfx.COLOR_TRANSPARENT);
        var labelX = x + 8;
        dc.drawText(labelX, centerY, labelFont, label, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        var valueColor = (isSelected || isEditing) ? Colors.TEXT_PRIMARY : Colors.TEXT_MUTED;
        dc.setColor(valueColor, Gfx.COLOR_TRANSPARENT);
        var valueX = x + w - 8;
        if (unit.length() > 0) {
            var unitW = dc.getTextWidthInPixels(unit, unitFont);
            dc.drawText(valueX, centerY, unitFont, unit, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.drawText(valueX - unitW - 4, centerY, valueFont, value.toString(), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(valueX, centerY, valueFont, value.toString(), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }
}
