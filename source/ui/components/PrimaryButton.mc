using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PrimaryButton {
    function draw(
        dc as Gfx.Dc,
        x as Lang.Number,
        y as Lang.Number,
        w as Lang.Number,
        h as Lang.Number,
        label as Lang.String,
        isFocused as Lang.Boolean,
        bucket as Lang.Symbol
    ) as Void {
        var radius = Dimensions.cardRadius(bucket);
        var centerX = x + w / 2;
        var centerY = y + h / 2;
        var font = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;

        if (isFocused) {
            dc.setColor(Colors.BRAND, Colors.BRAND);
            dc.fillRoundedRectangle(x, y, w, h, radius);
            dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(x, y, w, h, radius);
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        }

        dc.drawText(centerX, centerY, font, label, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}