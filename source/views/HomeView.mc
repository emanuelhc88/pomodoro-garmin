using Toybox.Application as App;
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
        _cyclesLabel = Strings.get(:unit_cycles);
        _customLabel = Strings.get(:preset_custom_label);
        _settingsLabel = Strings.get(:settings_label);
        var app = App.getApp() as TomaApp;
        var savedIdx = app.getSettingsRepo().getLastSelectedPreset();
        if (savedIdx >= 0 && savedIdx < _totalItems) {
            _selectedIndex = savedIdx;
        }
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


        var dr = Dimensions.dotRadius(bucket);
        var ds = Dimensions.dotSpacing(bucket);

        var wordmarkY = h * 15 / 100;
        Wordmark.draw(dc, centerX, wordmarkY, bucket);

        var cardCenterY = h * 47 / 100;

        if (_selectedIndex < 4) {
            var preset = _presets[_selectedIndex] as Preset;
            var primary = preset.formatPrimary();
            var secondary = preset.formatSecondary(_cyclesLabel);
            PresetCard.draw(dc, centerX, cardCenterY, true, bucket, {
                :label => primary,
                :sublabel => secondary,
                :isCustom => preset.isCustom,
                :customLabel => _customLabel
            });
        } else {
            PresetCard.draw(dc, centerX, cardCenterY, true, bucket, {
                :label => _settingsLabel,
                :sublabel => "",
                :isCustom => false,
                :customLabel => ""
            });
        }

        var dotsY = (bucket == :large) ? h * 73 / 100 : h * 78 / 100;
        DotsIndicator.draw(dc, centerX, dotsY, _totalItems, _selectedIndex, dr, ds, 4);
    }
}