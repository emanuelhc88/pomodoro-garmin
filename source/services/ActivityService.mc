using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Lang;
using Toybox.System;

class ActivityService {
    private var _session as ActivityRecording.Session?;
    private var _settingsRepo as SettingsRepository;

    function initialize(settingsRepo as SettingsRepository) {
        _settingsRepo = settingsRepo;
    }

    function start() as Void {
        if (!_settingsRepo.getRecordAsActivity()) {
            return;
        }
        if (_session != null) {
            return;
        }
        if (!(Toybox has :ActivityRecording) ||
            !(Toybox.ActivityRecording has :createSession)) {
            return;
        }
        try {
            _session = ActivityRecording.createSession({
                :name => "Focus",
                :sport => Activity.SPORT_GENERIC,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            (_session as ActivityRecording.Session).start();
        } catch (e instanceof Lang.Exception) {
            _debugLog("start failed: " + e.getErrorMessage());
            _session = null;
        }
    }

    function stop() as Void {
        if (_session == null) {
            return;
        }
        try {
            (_session as ActivityRecording.Session).stop();
            (_session as ActivityRecording.Session).save();
        } catch (e instanceof Lang.Exception) {
            _debugLog("stop failed: " + e.getErrorMessage());
        }
        _session = null;
    }

    function discard() as Void {
        if (_session == null) {
            return;
        }
        try {
            (_session as ActivityRecording.Session).stop();
            (_session as ActivityRecording.Session).discard();
        } catch (e instanceof Lang.Exception) {
            _debugLog("discard failed: " + e.getErrorMessage());
        }
        _session = null;
    }

    function isRecording() as Lang.Boolean {
        return _session != null;
    }

    (:debug)
    private function _debugLog(msg as Lang.String) as Void {
        System.println("[ActivityService] " + msg);
    }
}
