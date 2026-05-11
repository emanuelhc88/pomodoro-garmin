using Toybox.Graphics as Gfx;
using Toybox.Lang;

module Wordmark {
    function draw(dc as Gfx.Dc, x as Lang.Number, y as Lang.Number, bucket as Lang.Symbol) as Void {
        var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        var textW = dc.getTextWidthInPixels("toma", font);
        var fontH = Gfx.getFontHeight(font);

        var tomatoR = (bucket == :small) ? 5 : 7;
        var gap = (bucket == :small) ? 4 : 6;
        var totalW = tomatoR * 2 + gap + textW;
        var startX = x - totalW / 2;

        var tomatoCx = startX + tomatoR;
        var tomatoCy = y + fontH / 2 + 1;

        dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(tomatoCx, tomatoCy, tomatoR);

        var stemLen = (bucket == :small) ? 3 : 4;
        dc.setColor(0x2ECC71, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(tomatoCx, tomatoCy - tomatoR, tomatoCx, tomatoCy - tomatoR - stemLen);

        var textX = startX + tomatoR * 2 + gap;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, "toma", Gfx.TEXT_JUSTIFY_LEFT);
    }
}
