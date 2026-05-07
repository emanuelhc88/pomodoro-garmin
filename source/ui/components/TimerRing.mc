using Toybox.Graphics as Gfx;
using Toybox.Lang;

module TimerRing {
    function draw(
        dc as Gfx.Dc,
        centerX as Lang.Number,
        centerY as Lang.Number,
        radius as Lang.Number,
        stroke as Lang.Number,
        progress as Lang.Float,
        color as Lang.Number
    ) as Void {
        dc.setPenWidth(stroke);
        dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 0, 360);

        if (progress > 0.0) {
            var startAngle = 90;
            var endAngle = 90 - (progress * 360).toNumber();
            if (endAngle < 0) {
                endAngle = endAngle + 360;
            }
            dc.setColor(color, Gfx.COLOR_TRANSPARENT);
            dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, startAngle, endAngle);
        }

        dc.setPenWidth(1);
    }
}