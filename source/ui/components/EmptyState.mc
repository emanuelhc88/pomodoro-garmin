using Toybox.Graphics as Gfx;
using Toybox.Lang;

module EmptyState {
    function draw(dc as Gfx.Dc, centerX as Lang.Number, centerY as Lang.Number, text as Lang.String, bucket as Lang.Symbol) as Void {
        var font = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}
