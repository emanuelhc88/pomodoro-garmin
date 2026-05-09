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

        var dlgW = Dimensions.confirmDialogWidth(bucket);
        var dlgH = Dimensions.confirmDialogHeight(bucket);
        var dlgX = centerX - dlgW / 2;
        var dlgY = h / 2 - dlgH / 2;
        var radius = Dimensions.cardRadius(bucket);
        var border = Dimensions.cardBorder(bucket);

        dc.setColor(Colors.BORDER, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dlgX, dlgY, dlgW, dlgH, radius);
        dc.setColor(Colors.BG, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dlgX + border, dlgY + border, dlgW - border * 2, dlgH - border * 2, radius);

        var titleY = dlgY + Dimensions.confirmTitleY(bucket);
        var titleFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, titleFont, _titleText, Gfx.TEXT_JUSTIFY_CENTER);

        var btnW = Dimensions.confirmButtonWidth(bucket);
        var btnH = Dimensions.confirmButtonHeight(bucket);
        var btnX = centerX - btnW / 2;

        var btn1Y = dlgY + Dimensions.confirmButton1Y(bucket);
        PrimaryButton.draw(dc, btnX, btn1Y, btnW, btnH, _continueText, _focusIdx == 0, bucket);

        var btn2Y = dlgY + Dimensions.confirmButton2Y(bucket);
        PrimaryButton.draw(dc, btnX, btn2Y, btnW, btnH, _stopText, _focusIdx == 1, bucket);
    }
}
