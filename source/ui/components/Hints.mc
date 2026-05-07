using Toybox.Graphics as Gfx;
using Toybox.Lang;

module Hints {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        text as Lang.String,
        bucket as Lang.Symbol
    ) as Void {
        var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}
