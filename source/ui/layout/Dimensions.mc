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
}
