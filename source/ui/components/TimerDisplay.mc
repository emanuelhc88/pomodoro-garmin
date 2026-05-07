using Toybox.Graphics as Gfx;
using Toybox.Lang;

module TimerDisplay {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        remainingSeconds as Lang.Number,
        bucket as Lang.Symbol
    ) as Void {
        var minutes = remainingSeconds / 60;
        var seconds = remainingSeconds % 60;
        var text = Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")]);

        var font = (bucket == :small) ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_THAI_HOT;
        var fontHeight = Gfx.getFontHeight(font);
        var y = centerY - fontHeight / 2;

        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
    }
}