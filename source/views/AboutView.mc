using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class AboutView extends Ui.View {
    private var _versionText as Lang.String = "";
    private var _taglineText as Lang.String = "";
    private var _creditsText as Lang.String = "";

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Gfx.Dc) as Void {
        _versionText = Strings.get(:about_version);
        _taglineText = Strings.get(:about_tagline);
        _creditsText = Strings.get(:about_credits);
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var wordmarkY = Dimensions.aboutWordmarkY(bucket);
        Wordmark.draw(dc, centerX, wordmarkY, bucket);

        var versionY = Dimensions.aboutVersionY(bucket);
        var versionFont = (bucket == :small) ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
        dc.setColor(Colors.TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, versionY, versionFont, _versionText, Gfx.TEXT_JUSTIFY_CENTER);

        var taglineY = Dimensions.aboutTaglineY(bucket);
        var taglineFont = (bucket == :small) ? Gfx.FONT_XTINY : Gfx.FONT_TINY;
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, taglineY, taglineFont, _taglineText, Gfx.TEXT_JUSTIFY_CENTER);

        var creditsY = Dimensions.aboutCreditsY(bucket);
        dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, creditsY, taglineFont, _creditsText, Gfx.TEXT_JUSTIFY_CENTER);
    }
}
