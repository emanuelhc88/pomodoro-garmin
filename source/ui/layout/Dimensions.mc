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

    function pausedLabelOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 30; }
        if (bucket == :large) { return 60; }
        return 35;
    }

    function phaseGiantY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 85; }
        if (bucket == :large) { return 180; }
        return 110;
    }

    function phaseHintY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 260; }
        return 160;
    }

    function cycleHeadingY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 20; }
        if (bucket == :large) { return 50; }
        return 30;
    }

    function cycleNumberY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 55; }
        if (bucket == :large) { return 130; }
        return 75;
    }

    function cycleTodayY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 100; }
        if (bucket == :large) { return 220; }
        return 130;
    }

    function cycleButton1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 280; }
        return 165;
    }

    function cycleButton2Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 160; }
        if (bucket == :large) { return 340; }
        return 200;
    }

    function buttonWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 240; }
        return 160;
    }

    function buttonHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 26; }
        if (bucket == :large) { return 44; }
        return 30;
    }

    function customTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :large) { return 40; }
        return 25;
    }

    function customLineHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 38; }
        if (bucket == :large) { return 70; }
        return 48;
    }

    function customLine1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 40; }
        if (bucket == :large) { return 90; }
        return 60;
    }

    function customLineSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 4; }
        if (bucket == :large) { return 12; }
        return 8;
    }

    function customHintsY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 170; }
        if (bucket == :large) { return 360; }
        return 210;
    }

    function historyTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 15; }
        if (bucket == :large) { return 35; }
        return 20;
    }

    function historyItemHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 40; }
        if (bucket == :large) { return 70; }
        return 52;
    }

    function historyItemPadding(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 4; }
        if (bucket == :large) { return 10; }
        return 6;
    }

    function historyListStartY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 35; }
        if (bucket == :large) { return 70; }
        return 45;
    }

    function historyItemLine1Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 2; }
        if (bucket == :large) { return 6; }
        return 4;
    }

    function historyItemLine2Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 14; }
        if (bucket == :large) { return 26; }
        return 18;
    }

    function historyItemLine3Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 28; }
        if (bucket == :large) { return 50; }
        return 36;
    }
}
