using Toybox.Graphics as Gfx;
using Toybox.Lang;

module Wordmark {
    function draw(dc as Gfx.Dc, x as Lang.Number, y as Lang.Number, bucket as Lang.Symbol) as Void {
        var font = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, "toma", Gfx.TEXT_JUSTIFY_CENTER);
    }
}
