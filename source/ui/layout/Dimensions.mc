using Toybox.Lang;

module Dimensions {
    function cardWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 150; }
        if (bucket == :large) { return 300; }
        return 180;
    }

    function cardHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 66; }
        if (bucket == :large) { return 140; }
        return 105;
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
        if (bucket == :large) { return 170; }
        return 110;
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
        if (bucket == :large) { return -130; }
        return -70;
    }

    function pillsOffsetY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 60; }
        if (bucket == :large) { return 130; }
        return 75;
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
        if (bucket == :large) { return 80; }
        return 38;
    }

    function cycleNumberY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 55; }
        if (bucket == :large) { return 140; }
        return 72;
    }

    function cycleTodayY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 100; }
        if (bucket == :large) { return 240; }
        return 124;
    }

    function cycleButton1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 290; }
        return 152;
    }

    function cycleButton2Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 160; }
        if (bucket == :large) { return 358; }
        return 190;
    }

    function buttonWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 130; }
        if (bucket == :large) { return 280; }
        return 140;
    }

    function buttonHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 26; }
        if (bucket == :large) { return 38; }
        return 28;
    }

    function customTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :large) { return 40; }
        return 25;
    }

    function customLineHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 34; }
        if (bucket == :large) { return 56; }
        return 40;
    }

    function customLine1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 40; }
        if (bucket == :large) { return 120; }
        return 55;
    }

    function customLineSpacing(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 3; }
        if (bucket == :large) { return 18; }
        return 6;
    }

    function customHintsY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 170; }
        if (bucket == :large) { return 355; }
        return 195;
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

    function aboutWordmarkY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 30; }
        if (bucket == :large) { return 70; }
        return 45;
    }

    function aboutVersionY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 75; }
        if (bucket == :large) { return 165; }
        return 105;
    }

    function aboutTaglineY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 100; }
        if (bucket == :large) { return 215; }
        return 135;
    }

    function aboutCreditsY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 140; }
        if (bucket == :large) { return 300; }
        return 180;
    }

    function confirmDialogWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 160; }
        if (bucket == :large) { return 340; }
        return 200;
    }

    function confirmDialogHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 110; }
        if (bucket == :large) { return 210; }
        return 140;
    }

    function confirmTitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 15; }
        if (bucket == :large) { return 25; }
        return 20;
    }

    function confirmSubtitleY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 33; }
        if (bucket == :large) { return 55; }
        return 40;
    }

    function confirmButton1Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 50; }
        if (bucket == :large) { return 80; }
        return 55;
    }

    function confirmButton2Y(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 76; }
        if (bucket == :large) { return 140; }
        return 95;
    }

    function confirmButtonWidth(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 120; }
        if (bucket == :large) { return 260; }
        return 150;
    }

    function confirmButtonHeight(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 22; }
        if (bucket == :large) { return 50; }
        return 32;
    }
}
