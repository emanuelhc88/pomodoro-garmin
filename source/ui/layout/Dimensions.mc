using Toybox.Lang;

module Dimensions {
    function cardWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 150; }
        if (bucket == :large) { return 260; }
        return 180;
    }

    function cardHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 66; }
        if (bucket == :large) { return 110; }
        return 80;
    }

    function cardRadius(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 6; }
        if (bucket == :large) { return 12; }
        return 8;
    }

    function cardBorder(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :large) { return 3; }
        return 2;
    }

    function dotRadius(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 3; }
        if (bucket == :large) { return 5; }
        return 4;
    }

    function dotSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 8; }
        if (bucket == :large) { return 12; }
        return 10;
    }

    function ringRadius(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 85; }
        if (bucket == :large) { return 175; }
        return 100;
    }

    function ringStroke(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 6; }
        if (bucket == :large) { return 12; }
        return 8;
    }

    function timerCenterY(bucket as Lang.Symbol, screenHeight as Lang.Number) as Lang.Number {
        return screenHeight / 2;
    }

    function phaseLabelOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return -48; }
        if (bucket == :large) { return -100; }
        return -60;
    }

    function pillsOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 75; }
        if (bucket == :large) { return 160; }
        return 90;
    }

    function pillSize(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 6; }
        if (bucket == :large) { return 10; }
        return 8;
    }

    function pillSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 3; }
        if (bucket == :large) { return 6; }
        return 4;
    }
}
