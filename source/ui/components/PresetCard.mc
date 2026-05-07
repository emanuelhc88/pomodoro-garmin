using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PresetCard {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        label as Lang.String,
        sublabel as Lang.String,
        isSelected as Lang.Boolean,
        isCustom as Lang.Boolean,
        customLabel as Lang.String,
        cardWidth as Lang.Number,
        cardHeight as Lang.Number,
        cardRadius as Lang.Number,
        cardBorder as Lang.Number,
        bucket as Lang.Symbol
    ) as Void {
        var x = centerX - cardWidth / 2;
        var y = centerY - cardHeight / 2;

        var borderColor = isSelected ? Colors.BRAND : Colors.BORDER;

        dc.setColor(borderColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(cardBorder);
        dc.drawRoundedRectangle(x, y, cardWidth, cardHeight, cardRadius);
        dc.setPenWidth(1);

        var labelFont = (bucket == :small) ? Gfx.FONT_MEDIUM : Gfx.FONT_NUMBER_MEDIUM;
        var sublabelFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var customLabelFont = Gfx.FONT_XTINY;

        if (isCustom) {
            var customLabelH = Gfx.getFontHeight(customLabelFont);
            var labelH = Gfx.getFontHeight(labelFont);
            var sublabelH = Gfx.getFontHeight(sublabelFont);
            var totalH = customLabelH + labelH + sublabelH - 8;
            var startY = centerY - totalH / 2;

            dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY, customLabelFont, customLabel, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH - 2, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH + labelH - 6, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            var labelY = centerY - Gfx.getFontHeight(labelFont) / 2 - 4;
            var sublabelY = labelY + Gfx.getFontHeight(labelFont) - 2;

            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, labelY, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

            if (!sublabel.equals("")) {
                dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, sublabelY, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}