using Toybox.Graphics as Gfx;
using Toybox.Lang;

module PhaseLabel {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        text as Lang.String,
        color as Lang.Number,
        bucket as Lang.Symbol
    ) as Void {
        var font = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}