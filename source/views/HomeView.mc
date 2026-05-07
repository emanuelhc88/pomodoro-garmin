using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HomeView extends Ui.View {
    private var _selectedIndex as Lang.Number = 0;
    private var _presetLabels as Lang.Array<Lang.String>;
    private var _presetSublabels as Lang.Array<Lang.String>;
    private var _totalItems as Lang.Number = 5;

    function initialize() {
        View.initialize();
        _presetLabels = ["25 / 5", "30 / 5", "50 / 10", "Custom", "Settings"];
        _presetSublabels = ["4 cycles", "4 cycles", "4 cycles", "25 / 5 · 4", ""];
    }

    function getSelectedIndex() as Lang.Number {
        return _selectedIndex;
    }

    function navigateUp() as Void {
        _selectedIndex = (_selectedIndex - 1 + _totalItems) % _totalItems;
        Ui.requestUpdate();
    }

    function navigateDown() as Void {
        _selectedIndex = (_selectedIndex + 1) % _totalItems;
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(Colors.BG, Colors.BG);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerX = w / 2;
        var bucket = Bucket.detect();

        var cw = Dimensions.cardWidth(bucket);
        var ch = Dimensions.cardHeight(bucket);
        var cr = Dimensions.cardRadius(bucket);
        var cb = Dimensions.cardBorder(bucket);
        var dr = Dimensions.dotRadius(bucket);
        var ds = Dimensions.dotSpacing(bucket);

        var wordmarkY = h * 15 / 100;
        Wordmark.draw(dc, centerX, wordmarkY, bucket);

        var cardCenterY = h * 47 / 100;
        var label = _presetLabels[_selectedIndex] as Lang.String;
        var sublabel = _presetSublabels[_selectedIndex] as Lang.String;
        PresetCard.draw(dc, centerX, cardCenterY, label, sublabel, true, cw, ch, cr, cb);

        var dotsY = h * 78 / 100;
        DotsIndicator.draw(dc, centerX, dotsY, _totalItems, _selectedIndex, dr, ds);
    }
}
