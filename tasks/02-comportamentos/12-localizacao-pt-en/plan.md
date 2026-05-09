# Plan — Task 02-12: Localisation PT/EN + Polish Final

> Spec Tatica gerada na FASE 2.3. Executar com `/execute` na proxima sessao.

---

## 1. Resumo

Criar modulo `Strings` com dicionarios EN/PT inline que resolve strings via setting Language (auto/en/pt). Migrar todas as views e utils de `Ui.loadResource(Rez.Strings.*)` e hardcoded strings para `Strings.get(:key)` / `Strings.format(:key, args)`. Completar strings PT ausentes. Atualizar `DateUtils.getLocale()` para respeitar override de idioma.

---

## 2. Cenarios

### Caminho feliz
1. Usuario abre app com Language = "auto" em device ingles → todas as strings aparecem em EN.
2. Usuario abre app com Language = "auto" em device portugues → todas as strings aparecem em PT.
3. Usuario muda Language para "pt" em device ingles → todas as strings mudam para PT.
4. Usuario muda Language para "en" em device portugues → todas as strings mudam para EN.
5. Datas no historico respeitam o idioma selecionado (meses em PT/EN).

### Edge cases
- Key nao encontrada no dicionario → retornar string vazia `""` (fallback seguro).
- `Strings.format(:key, args)` com key invalida → formata string vazia, sem crash.
- `Sys.LANGUAGE_POR` retorna valor numerico 19 em SDKs antigos — usar comparacao direta.

### Erros
- Nenhum erro de runtime esperado — lookups em dicionario sao null-safe com fallback.
- Se `App.getApp()` retornar null (impossivel em pratica) — crash hard, nao tratar (bug de framework).

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/utils/Strings.mc` | Modulo wrapper com dicionarios EN/PT e funcoes get/format |
| 2 | `scripts/check-strings.sh` | Linter grep para strings hardcoded em source/ |
| 3 | `scripts/build-release.sh` | Gera pacote `.iq` multi-device para distribuicao |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `resources-por/strings/strings.xml` | Adicionar 5 strings PT ausentes |
| 2 | `source/views/TimerView.mc` | Migrar hardcoded strings para Strings.get() |
| 3 | `source/views/PhaseTransitionView.mc` | Migrar hardcoded "Session"/"of" para Strings.format() |
| 4 | `source/views/HomeView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 5 | `source/views/CustomBuilderView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 6 | `source/views/CycleCompleteView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 7 | `source/views/HistoryView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 8 | `source/views/SettingsMenu.mc` | Migrar Ui.loadResource() para Strings.get() |
| 9 | `source/views/ConfirmStopView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 10 | `source/views/RecoveryView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 11 | `source/views/AboutView.mc` | Migrar Ui.loadResource() para Strings.get() |
| 12 | `source/views/LanguageMenu.mc` | Migrar Ui.loadResource() para Strings.get() |
| 13 | `source/utils/TimeFormatter.mc` | Migrar Ui.loadResource() para Strings.get() |
| 14 | `source/utils/DateUtils.mc` | getLocale() respeitar setting override |

---

### 4.1 `resources-por/strings/strings.xml`

**Antes:**
```xml
<resources>
    ...
    <string id="confirm_stop_continue">Continuar</string>
</resources>
```

**Depois:**
```xml
<resources>
    ...
    <string id="confirm_stop_continue">Continuar</string>
    <string id="today_session_singular">Hoje: 1 sessao</string>
    <string id="recovery_title">Retomar sessao?</string>
    <string id="recovery_remaining">Restante: $1$</string>
    <string id="recovery_resume">Retomar</string>
    <string id="recovery_discard">Descartar</string>
</resources>
```

---

### 4.2 `source/views/TimerView.mc`

**Antes (linhas 1-2):**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Application as App;
```

**Antes (initialize, linha 12):**
```monkeyc
        _pausedText = Ui.loadResource(Rez.Strings.state_paused) as Lang.String;
```

**Depois:**
```monkeyc
        _pausedText = Strings.get(:state_paused);
```

**Antes (linhas 89-93):**
```monkeyc
    private function _getPhaseText(phase as Lang.Symbol) as Lang.String {
        if (phase == :running_work) { return "FOCUS"; }
        if (phase == :running_short_break) { return "BREAK"; }
        return "LONG BREAK";
    }
```

**Depois:**
```monkeyc
    private function _getPhaseText(phase as Lang.Symbol) as Lang.String {
        if (phase == :running_work) { return Strings.get(:phase_focus); }
        if (phase == :running_short_break) { return Strings.get(:phase_break); }
        return Strings.get(:phase_long_break);
    }
```

---

### 4.3 `source/views/PhaseTransitionView.mc`

**Antes (linhas 57-59):**
```monkeyc
        var hintText = Lang.format("$1$ $2$ $3$ $4$", [
            "Session", _sessionNum, "of", _totalSessions
        ]);
```

**Depois:**
```monkeyc
        var hintText = Strings.format(:session_n_of_m, [_sessionNum, _totalSessions]);
```

**Antes (linhas 64-68):**
```monkeyc
    private function getPhaseText() as Lang.String {
        if (_phase == :focus) { return Ui.loadResource(Rez.Strings.phase_focus) as Lang.String; }
        if (_phase == :break) { return Ui.loadResource(Rez.Strings.phase_break) as Lang.String; }
        return Ui.loadResource(Rez.Strings.phase_long_break) as Lang.String;
    }
```

**Depois:**
```monkeyc
    private function getPhaseText() as Lang.String {
        if (_phase == :focus) { return Strings.get(:phase_focus); }
        if (_phase == :break) { return Strings.get(:phase_break); }
        return Strings.get(:phase_long_break);
    }
```

---

### 4.4 `source/views/HomeView.mc`

**Antes (linhas 17-19):**
```monkeyc
        _cyclesLabel = Ui.loadResource(Rez.Strings.unit_cycles) as Lang.String;
        _customLabel = Ui.loadResource(Rez.Strings.preset_custom_label) as Lang.String;
        _settingsLabel = Ui.loadResource(Rez.Strings.settings_label) as Lang.String;
```

**Depois:**
```monkeyc
        _cyclesLabel = Strings.get(:unit_cycles);
        _customLabel = Strings.get(:preset_custom_label);
        _settingsLabel = Strings.get(:settings_label);
```

---

### 4.5 `source/views/CustomBuilderView.mc`

**Antes (linhas 26-32):**
```monkeyc
        _titleStr = Ui.loadResource(Rez.Strings.custom_builder_title) as Lang.String;
        _labelWork = Ui.loadResource(Rez.Strings.custom_label_work) as Lang.String;
        _labelBreak = Ui.loadResource(Rez.Strings.custom_label_break) as Lang.String;
        _labelCycles = Ui.loadResource(Rez.Strings.custom_label_cycles) as Lang.String;
        _unitMin = Ui.loadResource(Rez.Strings.unit_min) as Lang.String;
        _hintsNav = Ui.loadResource(Rez.Strings.hints_nav) as Lang.String;
        _hintsEdit = Ui.loadResource(Rez.Strings.hints_edit) as Lang.String;
```

**Depois:**
```monkeyc
        _titleStr = Strings.get(:custom_builder_title);
        _labelWork = Strings.get(:custom_label_work);
        _labelBreak = Strings.get(:custom_label_break);
        _labelCycles = Strings.get(:custom_label_cycles);
        _unitMin = Strings.get(:unit_min);
        _hintsNav = Strings.get(:hints_nav);
        _hintsEdit = Strings.get(:hints_edit);
```

---

### 4.6 `source/views/CycleCompleteView.mc`

**Antes (linha 38):**
```monkeyc
        var headingText = Ui.loadResource(Rez.Strings.cycle_complete_title) as Lang.String;
```

**Depois:**
```monkeyc
        var headingText = Strings.get(:cycle_complete_title);
```

**Antes (linhas 52-56):**
```monkeyc
            if (_todaySessions == 1) {
                todayText = Ui.loadResource(Rez.Strings.today_session_singular) as Lang.String;
            } else {
                todayText = Lang.format(Ui.loadResource(Rez.Strings.today_sessions) as Lang.String, [_todaySessions]);
            }
```

**Depois:**
```monkeyc
            if (_todaySessions == 1) {
                todayText = Strings.get(:today_session_singular);
            } else {
                todayText = Strings.format(:today_sessions, [_todaySessions]);
            }
```

**Antes (linha 66):**
```monkeyc
        var startText = Ui.loadResource(Rez.Strings.start_again) as Lang.String;
```

**Depois:**
```monkeyc
        var startText = Strings.get(:start_again);
```

**Antes (linha 70):**
```monkeyc
        var doneText = Ui.loadResource(Rez.Strings.done) as Lang.String;
```

**Depois:**
```monkeyc
        var doneText = Strings.get(:done);
```

---

### 4.7 `source/views/HistoryView.mc`

**Antes (linhas 20-21):**
```monkeyc
        _titleText = Ui.loadResource(Rez.Strings.history_title) as Lang.String;
        _emptyText = Ui.loadResource(Rez.Strings.history_empty) as Lang.String;
```

**Depois:**
```monkeyc
        _titleText = Strings.get(:history_title);
        _emptyText = Strings.get(:history_empty);
```

---

### 4.8 `source/views/SettingsMenu.mc`

**Antes (linha 7):**
```monkeyc
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});
```

**Depois:**
```monkeyc
        Menu2.initialize({:title => Strings.get(:settings_title)});
```

**Antes (linhas 12-57 — todos os items):**
```monkeyc
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound) as Lang.String,
            null,
            :soundEnabled,
            repo.getSoundEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration) as Lang.String,
            null,
            :vibrationEnabled,
            repo.getVibrationEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_backlight) as Lang.String,
            null,
            :backlightOnAlert,
            repo.getBacklightOnAlert(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_record_activity) as Lang.String,
            null,
            :recordAsActivity,
            repo.getRecordAsActivity(),
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language) as Lang.String,
            getLanguageSubLabel(repo),
            :language,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_history) as Lang.String,
            null,
            :history,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_about) as Lang.String,
            null,
            :about,
            null
        ));
```

**Depois:**
```monkeyc
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_sound),
            null,
            :soundEnabled,
            repo.getSoundEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_vibration),
            null,
            :vibrationEnabled,
            repo.getVibrationEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_backlight),
            null,
            :backlightOnAlert,
            repo.getBacklightOnAlert(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Strings.get(:settings_record_activity),
            null,
            :recordAsActivity,
            repo.getRecordAsActivity(),
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:settings_language),
            getLanguageSubLabel(repo),
            :language,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:settings_history),
            null,
            :history,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:settings_about),
            null,
            :about,
            null
        ));
```

**Antes (funcao getLanguageSubLabel, linhas 60-69):**
```monkeyc
    function getLanguageSubLabel(repo as SettingsRepository) as Lang.String {
        var lang = repo.getLanguage();
        if (lang.equals("en")) {
            return Ui.loadResource(Rez.Strings.language_en) as Lang.String;
        }
        if (lang.equals("pt")) {
            return Ui.loadResource(Rez.Strings.language_pt) as Lang.String;
        }
        return Ui.loadResource(Rez.Strings.language_auto) as Lang.String;
    }
```

**Depois:**
```monkeyc
    function getLanguageSubLabel(repo as SettingsRepository) as Lang.String {
        var lang = repo.getLanguage();
        if (lang.equals("en")) {
            return Strings.get(:language_en);
        }
        if (lang.equals("pt")) {
            return Strings.get(:language_pt);
        }
        return Strings.get(:language_auto);
    }
```

---

### 4.9 `source/views/ConfirmStopView.mc`

**Antes (linhas 12-14):**
```monkeyc
        _titleText = Ui.loadResource(Rez.Strings.confirm_stop_title) as Lang.String;
        _stopText = Ui.loadResource(Rez.Strings.confirm_stop_stop) as Lang.String;
        _continueText = Ui.loadResource(Rez.Strings.confirm_stop_continue) as Lang.String;
```

**Depois:**
```monkeyc
        _titleText = Strings.get(:confirm_stop_title);
        _stopText = Strings.get(:confirm_stop_stop);
        _continueText = Strings.get(:confirm_stop_continue);
```

---

### 4.10 `source/views/RecoveryView.mc`

**Antes (linhas 13-16):**
```monkeyc
        _titleText = Ui.loadResource(Rez.Strings.recovery_title) as Lang.String;
        _resumeText = Ui.loadResource(Rez.Strings.recovery_resume) as Lang.String;
        _discardText = Ui.loadResource(Rez.Strings.recovery_discard) as Lang.String;
```

**Depois:**
```monkeyc
        _titleText = Strings.get(:recovery_title);
        _resumeText = Strings.get(:recovery_resume);
        _discardText = Strings.get(:recovery_discard);
```

**Antes (linhas 21-22):**
```monkeyc
        var pattern = Ui.loadResource(Rez.Strings.recovery_remaining) as Lang.String;
        _remainingFormatted = Lang.format(pattern, [timeStr]);
```

**Depois:**
```monkeyc
        _remainingFormatted = Strings.format(:recovery_remaining, [timeStr]);
```

---

### 4.11 `source/views/AboutView.mc`

**Antes (linhas 15-17):**
```monkeyc
        _versionText = Ui.loadResource(Rez.Strings.about_version) as Lang.String;
        _taglineText = Ui.loadResource(Rez.Strings.about_tagline) as Lang.String;
        _creditsText = Ui.loadResource(Rez.Strings.about_credits) as Lang.String;
```

**Depois:**
```monkeyc
        _versionText = Strings.get(:about_version);
        _taglineText = Strings.get(:about_tagline);
        _creditsText = Strings.get(:about_credits);
```

---

### 4.12 `source/views/LanguageMenu.mc`

**Antes (linhas 5-25):**
```monkeyc
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_language)});

        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.language_auto) as Lang.String,
            null,
            :auto,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.language_en) as Lang.String,
            null,
            :en,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.language_pt) as Lang.String,
            null,
            :pt,
            null
        ));
    }
```

**Depois:**
```monkeyc
    function initialize() {
        Menu2.initialize({:title => Strings.get(:settings_language)});

        addItem(new Ui.MenuItem(
            Strings.get(:language_auto),
            null,
            :auto,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:language_en),
            null,
            :en,
            null
        ));
        addItem(new Ui.MenuItem(
            Strings.get(:language_pt),
            null,
            :pt,
            null
        ));
    }
```

---

### 4.13 `source/utils/TimeFormatter.mc`

**Antes (linhas 1-2):**
```monkeyc
using Toybox.Lang;
using Toybox.WatchUi as Ui;
```

**Depois:**
```monkeyc
using Toybox.Lang;
```

**Antes (linhas 9-14):**
```monkeyc
        if (hours > 0) {
            var pattern = Ui.loadResource(Rez.Strings.duration_hours_minutes) as Lang.String;
            return Lang.format(pattern, [hours, minutes]);
        }
        var pattern = Ui.loadResource(Rez.Strings.duration_minutes) as Lang.String;
        return Lang.format(pattern, [minutes]);
```

**Depois:**
```monkeyc
        if (hours > 0) {
            return Strings.format(:duration_hours_minutes, [hours, minutes]);
        }
        return Strings.format(:duration_minutes, [minutes]);
```

---

### 4.14 `source/utils/DateUtils.mc`

**Antes (linhas 42-48):**
```monkeyc
    function getLocale() as Lang.Symbol {
        var lang = Sys.getDeviceSettings().systemLanguage;
        if (lang == Sys.LANGUAGE_POR) {
            return :pt;
        }
        return :en;
    }
```

**Depois:**
```monkeyc
    function getLocale() as Lang.Symbol {
        var app = Application.getApp() as TomaApp;
        var setting = app.getSettingsRepo().getLanguage();
        if (setting.equals("pt")) { return :pt; }
        if (setting.equals("en")) { return :en; }
        var sysLang = Sys.getDeviceSettings().systemLanguage;
        if (sysLang == Sys.LANGUAGE_POR) { return :pt; }
        return :en;
    }
```

**Antes (linha 1 — imports):**
```monkeyc
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;
```

**Depois:**
```monkeyc
using Toybox.Application;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;
```

---

## 5. Conteudo do `source/utils/Strings.mc` (arquivo novo)

```monkeyc
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

    hidden function _resolveLanguage() as Lang.Symbol {
        var app = Application.getApp() as TomaApp;
        var setting = app.getSettingsRepo().getLanguage();
        if (setting.equals("en")) { return :en; }
        if (setting.equals("pt")) { return :pt; }
        var sysLang = Sys.getDeviceSettings().systemLanguage;
        if (sysLang == Sys.LANGUAGE_POR) { return :pt; }
        return :en;
    }

    hidden function _en(key as Lang.Symbol) as Lang.String {
        if (key == :app_name) { return "Toma"; }
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
        if (key == :about_credits) { return "Made with focus"; }
        if (key == :confirm_stop_title) { return "Stop session?"; }
        if (key == :confirm_stop_stop) { return "Stop"; }
        if (key == :confirm_stop_continue) { return "Continue"; }
        if (key == :recovery_title) { return "Resume session?"; }
        if (key == :recovery_remaining) { return "Remaining: $1$"; }
        if (key == :recovery_resume) { return "Resume"; }
        if (key == :recovery_discard) { return "Discard"; }
        return "";
    }

    hidden function _pt(key as Lang.Symbol) as Lang.String {
        if (key == :app_name) { return "Toma"; }
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
        if (key == :about_credits) { return "Feito com foco"; }
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
```

**Nota sobre design:** Usa if-chains em vez de Dictionary para evitar alocacao de heap a cada chamada. O compilador Monkey C otimiza comparacoes de Symbol (inteiros internamente). Cada funcao `_en`/`_pt` retorna string literal — zero allocations alem da string em si.

---

## 6. Conteudo do `scripts/check-strings.sh`

```bash
#!/bin/bash
# Lint: detect hardcoded user-facing strings in source/ (excluding Strings.mc itself)

ERRORS=0

while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    num=$(echo "$line" | cut -d: -f2)
    content=$(echo "$line" | cut -d: -f3-)
    echo "  $file:$num →$content"
    ((ERRORS++))
done < <(grep -rn --include="*.mc" -E '(drawText|MenuItem|ToggleMenuItem|Menu2\.initialize).*"[A-Z][a-z]' source/ \
    | grep -v "Strings.mc" \
    | grep -v "Wordmark.mc" \
    | grep -v "//")

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "Found $ERRORS potential hardcoded strings."
    exit 1
fi

echo "No hardcoded strings found."
exit 0
```

---

## 7. Conteudo do `scripts/build-release.sh`

```bash
#!/bin/bash
# Build .iq package for Connect IQ Store submission

SDKPATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/" | head -1)"
KEYPATH="$HOME/.connect-iq/developer_key.der"
JUNGLE="monkey.jungle"
OUTDIR="bin"
OUTPUT="$OUTDIR/toma.iq"

mkdir -p "$OUTDIR"

echo "Building release package..."
if "$SDKPATH/bin/monkeyc" -e -f "$JUNGLE" -o "$OUTPUT" -y "$KEYPATH" -w; then
    echo "Success: $OUTPUT"
    ls -lh "$OUTPUT"
    exit 0
else
    echo "Build failed."
    exit 1
fi
```

---

## 8. Storage/Properties

Nenhuma nova property. O modulo `Strings` le a property `language` existente via `SettingsRepository.getLanguage()` (ja implementado em task anterior).

---

## 9. Checklist de execucao

- [x] 1. Criar `source/utils/Strings.mc` com modulo completo (dicionarios EN/PT + get/format)
- [x] 2. Adicionar 5 strings ausentes em `resources-por/strings/strings.xml`
- [x] 3. Modificar `source/utils/DateUtils.mc` (import Application + getLocale respeitando setting)
- [x] 4. Modificar `source/utils/TimeFormatter.mc` (remover import Ui, usar Strings.format)
- [x] 5. Modificar `source/views/TimerView.mc` (import App, _pausedText e _getPhaseText)
- [x] 6. Modificar `source/views/PhaseTransitionView.mc` (hintText e getPhaseText)
- [x] 7. Modificar `source/views/HomeView.mc` (3 labels no initialize)
- [x] 8. Modificar `source/views/CustomBuilderView.mc` (7 labels no initialize)
- [x] 9. Modificar `source/views/CycleCompleteView.mc` (heading, today, buttons)
- [x] 10. Modificar `source/views/HistoryView.mc` (title e empty)
- [x] 11. Modificar `source/views/SettingsMenu.mc` (title, 7 items, getLanguageSubLabel)
- [x] 12. Modificar `source/views/ConfirmStopView.mc` (3 labels)
- [x] 13. Modificar `source/views/RecoveryView.mc` (4 labels)
- [x] 14. Modificar `source/views/AboutView.mc` (3 labels)
- [x] 15. Modificar `source/views/LanguageMenu.mc` (title + 3 items)
- [x] 16. Criar `scripts/check-strings.sh` e marcar executavel
- [x] 17. Criar `scripts/build-release.sh` e marcar executavel
- [x] 18. Rodar `scripts/check-strings.sh` — deve passar (0 hardcoded)
- [x] 19. Build para fr255 (`monkeyc -d fr255`)
- [x] 20. Build para fr265 (`monkeyc -d fr265`)
- [x] 21. Build para venu3 (`monkeyc -d venu3`)

---

## 10. Criterios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [x] `monkeyc -d venu3` compila sem erros
- [x] `scripts/check-strings.sh` retorna exit 0 (nenhuma string hardcoded detectada)

### Manual (simulador)
- [ ] Com Language = Auto em device EN: todas as telas mostram strings em ingles
- [ ] Com Language = Auto em device PT: todas as telas mostram strings em portugues
- [ ] Com Language = EN forceado: strings em EN independente do device language
- [ ] Com Language = PT forceado: strings em PT independente do device language
- [ ] Historico: datas com meses no idioma correto (Jan/Fev vs Jan/Feb)
- [ ] PhaseTransitionView: mostra "Session 1 of 4" (EN) ou "Sessao 1 de 4" (PT)
- [ ] TimerView: mostra "FOCUS"/"BREAK"/"LONG BREAK" (EN) ou "FOCO"/"PAUSA"/"PAUSA LONGA" (PT)

---

## 11. Out of scope

- Adicionar novos idiomas alem de PT/EN.
- Traducao da wordmark "toma" (e nome da marca).
- Remocao dos arquivos XML strings (ainda necessarios para metadata do Connect IQ Store).
- Custom fonts ou ajustes tipograficos por idioma.
- README.md (removido do scope — CLAUDE.md ja documenta o projeto).
- Cache de language resolution (PRD D4 decidiu contra).
