using Toybox.Attention;
using Toybox.System;
using Toybox.Lang;

class AttentionService {
    function initialize() {
    }

    function alertStart() as Void {
        _vibrate([new Attention.VibeProfile(75, 200)]);
        _flashBacklight();
    }

    function alertEndOfWork() as Void {
        _vibrate([
            new Attention.VibeProfile(100, 400),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 400)
        ]);
        _playTone();
        _flashBacklight();
    }

    function alertEndOfBreak() as Void {
        _vibrate([new Attention.VibeProfile(100, 600)]);
        _flashBacklight();
    }

    function alertCycleComplete() as Void {
        _vibrate([
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 500)
        ]);
        _playTone();
        _flashBacklight();
    }

    private function _vibrate(profile as Lang.Array<Attention.VibeProfile>) as Void {
        if (!SettingsState.vibrationEnabled) {
            return;
        }
        if (_isDoNotDisturb()) {
            return;
        }
        if (Attention has :vibrate) {
            Attention.vibrate(profile);
        }
    }

    private function _playTone() as Void {
        if (!SettingsState.soundEnabled) {
            return;
        }
        if (_isDoNotDisturb()) {
            return;
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
    }

    private function _flashBacklight() as Void {
        if (!SettingsState.backlightOnAlert) {
            return;
        }
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
    }

    private function _isDoNotDisturb() as Lang.Boolean {
        var settings = System.getDeviceSettings();
        if (settings has :doNotDisturb) {
            return settings.doNotDisturb;
        }
        return false;
    }
}
