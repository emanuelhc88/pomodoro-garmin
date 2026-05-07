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
        cardWidth as Lang.Number,
        cardHeight as Lang.Number,
        cardRadius as Lang.Number,
        cardBorder as Lang.Number
    ) as Void {
        var x = centerX - cardWidth / 2;
        var y = centerY - cardHeight / 2;

        var borderColor = isSelected ? Colors.BRAND : Colors.BORDER;

        dc.setColor(borderColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(cardBorder);
        dc.drawRoundedRectangle(x, y, cardWidth, cardHeight, cardRadius);
        dc.setPenWidth(1);

        var labelFont = Gfx.FONT_LARGE;
        var sublabelFont = Gfx.FONT_SMALL;
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
