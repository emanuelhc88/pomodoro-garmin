using Toybox.Graphics as Gfx;
using Toybox.Lang;

module SessionPills {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        totalCycles as Lang.Number,
        completedCycles as Lang.Number,
        pillSize as Lang.Number,
        pillSpacing as Lang.Number
    ) as Void {
        if (totalCycles > 4) {
            var text = completedCycles.toString() + "/" + totalCycles.toString();
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, y - Gfx.getFontHeight(Gfx.FONT_TINY) / 2, Gfx.FONT_TINY, text, Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        var diameter = pillSize * 2;
        var totalWidth = totalCycles * diameter + (totalCycles - 1) * pillSpacing;
        var startX = centerX - totalWidth / 2 + pillSize;

        for (var i = 0; i < totalCycles; i++) {
            var px = startX + i * (diameter + pillSpacing);

            if (i < completedCycles) {
                dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(px, y, pillSize);
            } else if (i == completedCycles) {
                dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(px, y, pillSize);
            } else {
                dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(px, y, pillSize);
            }
        }
    }
}