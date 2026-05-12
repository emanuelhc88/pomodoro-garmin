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

        var labelFont;
        if (bucket == :small) {
            labelFont = Gfx.FONT_MEDIUM;
        } else if (bucket == :large) {
            labelFont = Gfx.FONT_NUMBER_MILD;
        } else {
            labelFont = Gfx.FONT_NUMBER_MEDIUM;
        }
        var sublabelFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var customLabelFont = Gfx.FONT_XTINY;

        if (isCustom) {
            var customFont;
            if (bucket == :small) {
                customFont = Gfx.FONT_SMALL;
            } else if (bucket == :large) {
                customFont = Gfx.FONT_LARGE;
            } else {
                customFont = Gfx.FONT_NUMBER_MILD;
            }
            var customLabelH = Gfx.getFontHeight(customLabelFont);
            var labelH = Gfx.getFontHeight(customFont);
            var sublabelH = Gfx.getFontHeight(sublabelFont);
            var totalH = customLabelH + labelH + sublabelH - 10;
            var startY = centerY - totalH / 2;

            dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY, customLabelFont, customLabel, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH - 4, customFont, label, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH + labelH - 8, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            if (sublabel.equals("")) {
                var soloFont = (bucket == :small) ? Gfx.FONT_MEDIUM : Gfx.FONT_MEDIUM;
                var labelY = centerY - Gfx.getFontHeight(soloFont) / 2;
                dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, labelY, soloFont, label, Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                var labelH = Gfx.getFontHeight(labelFont);
                var sublabelH = Gfx.getFontHeight(sublabelFont);
                var totalH = labelH + sublabelH - 6;
                var startY = centerY - totalH / 2;

                dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, startY, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

                dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, startY + labelH - 6, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}