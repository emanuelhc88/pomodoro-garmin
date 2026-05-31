using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PresetCard {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        isSelected as Lang.Boolean,
        bucket as Lang.Symbol,
        options as Lang.Dictionary
    ) as Void {
        var cardWidth = Dimensions.cardWidth(bucket);
        var cardHeight = Dimensions.cardHeight(bucket);
        var cardRadius = Dimensions.cardRadius(bucket);
        var cardBorder = Dimensions.cardBorder(bucket);
        
        var label = options.get(:label) as Lang.String;
        var sublabel = options.get(:sublabel) as Lang.String;
        var isCustom = options.get(:isCustom) as Lang.Boolean;
        var customLabel = options.get(:customLabel) as Lang.String;

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
            var ov1 = (bucket == :large) ? 8 : 4;
            var ov2 = (bucket == :large) ? 14 : 8;
            var totalH = customLabelH + labelH + sublabelH - ov1 - ov2;
            var startY = centerY - totalH / 2;

            dc.setColor(Colors.ACCENT, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY, customLabelFont, customLabel, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH - ov1, customFont, label, Gfx.TEXT_JUSTIFY_CENTER);

            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, startY + customLabelH + labelH - ov1 - ov2, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            if (sublabel.equals("")) {
                var soloFont = (bucket == :small) ? Gfx.FONT_MEDIUM : Gfx.FONT_MEDIUM;
                var labelY = centerY - Gfx.getFontHeight(soloFont) / 2;
                dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, labelY, soloFont, label, Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                var labelH = Gfx.getFontHeight(labelFont);
                var sublabelH = Gfx.getFontHeight(sublabelFont);
                var overlap = (bucket == :large) ? 14 : 6;
                var totalH = labelH + sublabelH - overlap;
                var startY = centerY - totalH / 2;

                dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, startY, labelFont, label, Gfx.TEXT_JUSTIFY_CENTER);

                dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
                dc.drawText(centerX, startY + labelH - overlap, sublabelFont, sublabel, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}