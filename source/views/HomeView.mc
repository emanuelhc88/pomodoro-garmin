using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HomeView extends Ui.View {
    private var _selectedIndex as Lang.Number = 0;
    private var _presets as Lang.Array<Preset>;
    private var _totalItems as Lang.Number = 5;
    private var _cyclesLabel as Lang.String;
    private var _customLabel as Lang.String;
    private var _settingsLabel as Lang.String;

    function initialize() {
        View.initialize();
        _presets = Presets.builtinList();
        _cyclesLabel = Ui.loadResource(Rez.Strings.unit_cycles) as Lang.String;
        _customLabel = Ui.loadResource(Rez.Strings.preset_custom_label) as Lang.String;
        _settingsLabel = Ui.loadResource(Rez.Strings.settings_label) as Lang.String;
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

        if (_selectedIndex < 4) {
            var preset = _presets[_selectedIndex] as Preset;
            var primary = preset.formatPrimary();
            var secondary = preset.formatSecondary(_cyclesLabel);
            PresetCard.draw(dc, centerX, cardCenterY, primary, secondary, true, preset.isCustom, _customLabel, cw, ch, cr, cb, bucket);
        } else {
            PresetCard.draw(dc, centerX, cardCenterY, _settingsLabel, "", true, false, "", cw, ch, cr, cb, bucket);
        }

        var dotsY = h * 78 / 100;
        DotsIndicator.draw(dc, centerX, dotsY, _totalItems, _selectedIndex, dr, ds, 4);
    }
}