using Toybox.Graphics as Gfx;
using Toybox.Lang;

module DotsIndicator {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        y as Lang.Number,
        total as Lang.Number,
        activeIndex as Lang.Number,
        dotRadius as Lang.Number,
        dotSpacing as Lang.Number,
        settingsIndex as Lang.Number
    ) as Void {
        var totalWidth = (total - 1) * (dotRadius * 2 + dotSpacing);
        var startX = centerX - totalWidth / 2;

        for (var i = 0; i < total; i++) {
            var dotX = startX + i * (dotRadius * 2 + dotSpacing);
            if (i == activeIndex) {
                dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, y, dotRadius);
            } else {
                dc.setColor(Colors.BRAND, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(dotX, y, dotRadius);
            }
        }
    }
}