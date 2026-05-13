using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class ConfirmStopView extends Ui.View {
    private var _focusIdx as Lang.Number = 0;
    private var _titleText as Lang.String;
    private var _stopText as Lang.String;
    private var _continueText as Lang.String;

    function initialize() {
        View.initialize();
        _titleText = Strings.get(:confirm_stop_title);
        _stopText = Strings.get(:confirm_stop_stop);
        _continueText = Strings.get(:confirm_stop_continue);
    }

    function setFocusIdx(idx as Lang.Number) as Void {
        _focusIdx = idx;
        Ui.requestUpdate();
    }

    function getFocusIdx() as Lang.Number {
        return _focusIdx;
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var btnW = Dimensions.confirmButtonWidth(bucket);
        var btnH = Dimensions.confirmButtonHeight(bucket);
        var btnX = centerX - btnW / 2;

        var titleFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        var gap;
        var titleBlockH;
        if (bucket == :small) {
            gap = 6;
            titleBlockH = 24;
        } else if (bucket == :large) {
            gap = 24;
            titleBlockH = 56;
        } else {
            gap = 12;
            titleBlockH = 32;
        }

        var titleY = h * 28 / 100;
        var btn1Y = titleY + titleBlockH + gap;
        var btn2Y = btn1Y + btnH + gap;

        var dlgW = Dimensions.confirmDialogWidth(bucket);
        var dlgX = centerX - dlgW / 2;
        var dlgY = titleY - gap;
        var dlgH = (btn2Y + btnH + gap) - dlgY;
        var radius = Dimensions.cardRadius(bucket);
        var border = Dimensions.cardBorder(bucket);

        dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dlgX, dlgY, dlgW, dlgH, radius);
        dc.setColor(Colors.BG, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dlgX + border, dlgY + border, dlgW - border * 2, dlgH - border * 2, radius);

        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, titleFont, _titleText, Gfx.TEXT_JUSTIFY_CENTER);

        PrimaryButton.draw(dc, btnX, btn1Y, btnW, btnH, _continueText, _focusIdx == 0, bucket);
        PrimaryButton.draw(dc, btnX, btn2Y, btnW, btnH, _stopText, _focusIdx == 1, bucket);
    }
}
