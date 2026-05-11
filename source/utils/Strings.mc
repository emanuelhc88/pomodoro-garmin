using Toybox.Application;
using Toybox.Lang;
using Toybox.System as Sys;

module Strings {
    function get(key as Lang.Symbol) as Lang.String {
        var lang = _resolveLanguage();
        if (lang == :pt) {
            return _pt(key);
        }
        return _en(key);
    }

    function format(key as Lang.Symbol, args as Lang.Array) as Lang.String {
        return Lang.format(get(key), args);
    }

    function _resolveLanguage() as Lang.Symbol {
        var app = Application.getApp() as TomaApp;
        var setting = app.getSettingsRepo().getLanguage();
        if (setting.equals("en")) { return :en; }
        if (setting.equals("pt")) { return :pt; }
        var sysLang = Sys.getDeviceSettings().systemLanguage;
        if (sysLang == Sys.LANGUAGE_POR) { return :pt; }
        return :en;
    }

    function _en(key as Lang.Symbol) as Lang.String {
        if (key == :app_name) { return "Toma Pomodoro"; }
        if (key == :preset_cycles) { return "%d cycles"; }
        if (key == :unit_cycles) { return "cycles"; }
        if (key == :preset_custom_label) { return "CUSTOM"; }
        if (key == :settings_label) { return "Settings"; }
        if (key == :phase_focus) { return "FOCUS"; }
        if (key == :phase_break) { return "BREAK"; }
        if (key == :phase_long_break) { return "LONG BREAK"; }
        if (key == :state_paused) { return "PAUSED"; }
        if (key == :cycle_complete_title) { return "CYCLE COMPLETE"; }
        if (key == :session_n_of_m) { return "Session $1$ of $2$"; }
        if (key == :today_sessions) { return "Today: $1$ sessions"; }
        if (key == :today_session_singular) { return "Today: 1 session"; }
        if (key == :start_again) { return "Start again"; }
        if (key == :done) { return "Done"; }
        if (key == :custom_builder_title) { return "Custom"; }
        if (key == :custom_label_work) { return "WORK"; }
        if (key == :custom_label_break) { return "BREAK"; }
        if (key == :custom_label_cycles) { return "CYCLES"; }
        if (key == :unit_min) { return "min"; }
        if (key == :hints_nav) { return "SELECT to edit"; }
        if (key == :hints_edit) { return "SELECT to confirm"; }
        if (key == :history_title) { return "HISTORY"; }
        if (key == :history_empty) { return "No sessions yet"; }
        if (key == :duration_hours_minutes) { return "$1$h $2$m"; }
        if (key == :duration_minutes) { return "$1$m"; }
        if (key == :settings_title) { return "Settings"; }
        if (key == :settings_sound) { return "Sound"; }
        if (key == :settings_vibration) { return "Vibration"; }
        if (key == :settings_backlight) { return "Backlight on alert"; }
        if (key == :settings_record_activity) { return "Record as activity"; }
        if (key == :settings_language) { return "Language"; }
        if (key == :settings_history) { return "History"; }
        if (key == :settings_about) { return "About"; }
        if (key == :language_auto) { return "Auto"; }
        if (key == :language_en) { return "English"; }
        if (key == :language_pt) { return "Portugues"; }
        if (key == :about_tagline) { return "Pomodoro for developers"; }
        if (key == :about_version) { return "v1.0.0"; }
        if (key == :about_credits) { return "Made by Emanuel v7k"; }
        if (key == :confirm_stop_title) { return "Stop session?"; }
        if (key == :confirm_stop_stop) { return "Stop"; }
        if (key == :confirm_stop_continue) { return "Continue"; }
        if (key == :recovery_title) { return "Resume session?"; }
        if (key == :recovery_remaining) { return "Remaining: $1$"; }
        if (key == :recovery_resume) { return "Resume"; }
        if (key == :recovery_discard) { return "Discard"; }
        return "";
    }

    function _pt(key as Lang.Symbol) as Lang.String {
        if (key == :app_name) { return "Toma Pomodoro"; }
        if (key == :preset_cycles) { return "%d ciclos"; }
        if (key == :unit_cycles) { return "ciclos"; }
        if (key == :preset_custom_label) { return "PERSONALIZADO"; }
        if (key == :settings_label) { return "Configuracoes"; }
        if (key == :phase_focus) { return "FOCO"; }
        if (key == :phase_break) { return "PAUSA"; }
        if (key == :phase_long_break) { return "PAUSA LONGA"; }
        if (key == :state_paused) { return "PAUSADO"; }
        if (key == :cycle_complete_title) { return "CICLO COMPLETO"; }
        if (key == :session_n_of_m) { return "Sessao $1$ de $2$"; }
        if (key == :today_sessions) { return "Hoje: $1$ sessoes"; }
        if (key == :today_session_singular) { return "Hoje: 1 sessao"; }
        if (key == :start_again) { return "Recomecar"; }
        if (key == :done) { return "Pronto"; }
        if (key == :custom_builder_title) { return "Personalizado"; }
        if (key == :custom_label_work) { return "FOCO"; }
        if (key == :custom_label_break) { return "PAUSA"; }
        if (key == :custom_label_cycles) { return "CICLOS"; }
        if (key == :unit_min) { return "min"; }
        if (key == :hints_nav) { return "SELECT p/ editar"; }
        if (key == :hints_edit) { return "SELECT p/ confirmar"; }
        if (key == :history_title) { return "HISTORICO"; }
        if (key == :history_empty) { return "Sem sessoes ainda"; }
        if (key == :duration_hours_minutes) { return "$1$h $2$min"; }
        if (key == :duration_minutes) { return "$1$min"; }
        if (key == :settings_title) { return "Ajustes"; }
        if (key == :settings_sound) { return "Som"; }
        if (key == :settings_vibration) { return "Vibracao"; }
        if (key == :settings_backlight) { return "Iluminacao no alerta"; }
        if (key == :settings_record_activity) { return "Gravar como atividade"; }
        if (key == :settings_language) { return "Idioma"; }
        if (key == :settings_history) { return "Historico"; }
        if (key == :settings_about) { return "Sobre"; }
        if (key == :language_auto) { return "Auto"; }
        if (key == :language_en) { return "Ingles"; }
        if (key == :language_pt) { return "Portugues"; }
        if (key == :about_tagline) { return "Pomodoro para devs"; }
        if (key == :about_version) { return "v1.0.0"; }
        if (key == :about_credits) { return "Made by Emanuel v7k"; }
        if (key == :confirm_stop_title) { return "Parar sessao?"; }
        if (key == :confirm_stop_stop) { return "Parar"; }
        if (key == :confirm_stop_continue) { return "Continuar"; }
        if (key == :recovery_title) { return "Retomar sessao?"; }
        if (key == :recovery_remaining) { return "Restante: $1$"; }
        if (key == :recovery_resume) { return "Retomar"; }
        if (key == :recovery_discard) { return "Descartar"; }
        return "";
    }
}
