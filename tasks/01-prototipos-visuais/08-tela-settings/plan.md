# Plan — Task 01-08: Tela Settings

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar a tela P8 (Settings) usando `WatchUi.Menu2` nativo com 4 toggles, 1 selector (Language sub-menu), 2 ações (History, About). Estado dos toggles vive em memória via módulo `SettingsState`. A AboutView é customizada (wordmark + versão + tagline). Integração com HomeDelegate via `onSelect(index=4)` e `onMenu()`.

## 2. Cenários

### Caminho feliz
1. Usuário navega até item "Settings" no carousel (index 4) e pressiona Enter → abre SettingsMenu.
2. Alterna toggles Sound/Vibration/Backlight/Record → estado atualiza em SettingsState.
3. Seleciona Language → abre sub-menu com Auto/English/Português → seleciona → popView, sub-label atualiza.
4. Seleciona History → pushView HistoryView.
5. Seleciona About → pushView AboutView com wordmark, versão, tagline.
6. Pressiona Back → popView retorna ao HomeView.

### Edge cases
- `onMenu()` de qualquer posição no carousel abre SettingsMenu (atalho).
- Sub-label de Language inicializa com valor atual do SettingsState.
- Toggle state sobrevive durante a sessão do app (in-memory).

### Erros
- Nenhum erro de runtime esperado — Menu2 é nativo, toggles são in-memory.
- Se `setSubLabel` não existir no SDK, o sub-label não atualiza dinamicamente (menu funciona sem ele).

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/model/SettingsState.mc` | Módulo singleton com variáveis estáticas para estado in-memory dos toggles e language. |
| 2 | `source/views/SettingsMenu.mc` | Extends `Ui.Menu2`. Monta menu com 4 ToggleMenuItems + 3 MenuItems. |
| 3 | `source/delegates/SettingsMenuDelegate.mc` | Extends `Ui.Menu2InputDelegate`. Trata toggles e navegação para sub-views. |
| 4 | `source/views/LanguageMenu.mc` | Sub-menu Menu2 com opções Auto/English/Português. |
| 5 | `source/delegates/LanguageMenuDelegate.mc` | Delegate do sub-menu Language. Atualiza SettingsState.language e popView. |
| 6 | `source/views/AboutView.mc` | View customizada com wordmark, versão, tagline, créditos. |
| 7 | `source/delegates/AboutDelegate.mc` | BehaviorDelegate simples — apenas `onBack` para popView. |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/delegates/HomeDelegate.mc` | `onSelect` index 4 → pushView SettingsMenu. `onMenu` → pushView SettingsMenu. |
| 2 | `source/ui/layout/Dimensions.mc` | Adicionar 4 funções para posições Y da AboutView. |
| 3 | `resources/strings/strings.xml` | Adicionar 13 strings (settings/language/about) em EN. |
| 4 | `resources-por/strings/strings.xml` | Adicionar 13 strings traduzidas para PT. |
| 5 | `monkey.jungle` | Adicionar `resources-por` ao resourcePath. |

### 4.1 `source/delegates/HomeDelegate.mc`

**Antes (linhas 33-36):**
```monkeyc
        if (selectedIndex == 4) {
            var view = new HistoryView();
            Ui.pushView(view, new HistoryDelegate(view), Ui.SLIDE_LEFT);
            return true;
        }
```

**Depois:**
```monkeyc
        if (selectedIndex == 4) {
            Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_LEFT);
            return true;
        }
```

**Antes (linhas 74-77):**
```monkeyc
    function onMenu() as Lang.Boolean {
        Sys.println("Menu pressed");
        return true;
    }
```

**Depois:**
```monkeyc
    function onMenu() as Lang.Boolean {
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
```

### 4.2 `source/ui/layout/Dimensions.mc`

**Antes (fim do módulo, após `historyItemLine3Offset`):**
```monkeyc
    function historyItemLine3Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 28; }
        if (bucket == :large) { return 50; }
        return 36;
    }
}
```

**Depois:**
```monkeyc
    function historyItemLine3Offset(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 28; }
        if (bucket == :large) { return 50; }
        return 36;
    }

    function aboutWordmarkY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 30; }
        if (bucket == :large) { return 70; }
        return 45;
    }

    function aboutVersionY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 75; }
        if (bucket == :large) { return 165; }
        return 105;
    }

    function aboutTaglineY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 100; }
        if (bucket == :large) { return 215; }
        return 135;
    }

    function aboutCreditsY(bucket as Lang.Symbol) as Lang.Number {
        if (bucket == :small) { return 140; }
        if (bucket == :large) { return 300; }
        return 180;
    }
}
```

### 4.3 `resources/strings/strings.xml`

**Antes (fim do arquivo):**
```xml
    <string id="duration_hours_minutes">$1$h $2$m</string>
    <string id="duration_minutes">$1$m</string>
</resources>
```

**Depois:**
```xml
    <string id="duration_hours_minutes">$1$h $2$m</string>
    <string id="duration_minutes">$1$m</string>
    <string id="settings_title">Settings</string>
    <string id="settings_sound">Sound</string>
    <string id="settings_vibration">Vibration</string>
    <string id="settings_backlight">Backlight on alert</string>
    <string id="settings_record_activity">Record as activity</string>
    <string id="settings_language">Language</string>
    <string id="settings_history">History</string>
    <string id="settings_about">About</string>
    <string id="language_auto">Auto</string>
    <string id="language_en">English</string>
    <string id="language_pt">Portugues</string>
    <string id="about_tagline">Pomodoro for developers</string>
    <string id="about_version">v1.0.0</string>
    <string id="about_credits">Made with focus</string>
</resources>
```

### 4.4 `resources-por/strings/strings.xml`

**Antes (fim do arquivo):**
```xml
    <string id="duration_hours_minutes">$1$h $2$min</string>
    <string id="duration_minutes">$1$min</string>
</resources>
```

**Depois:**
```xml
    <string id="duration_hours_minutes">$1$h $2$min</string>
    <string id="duration_minutes">$1$min</string>
    <string id="settings_title">Ajustes</string>
    <string id="settings_sound">Som</string>
    <string id="settings_vibration">Vibracao</string>
    <string id="settings_backlight">Iluminacao no alerta</string>
    <string id="settings_record_activity">Gravar como atividade</string>
    <string id="settings_language">Idioma</string>
    <string id="settings_history">Historico</string>
    <string id="settings_about">Sobre</string>
    <string id="language_auto">Auto</string>
    <string id="language_en">Ingles</string>
    <string id="language_pt">Portugues</string>
    <string id="about_tagline">Pomodoro para devs</string>
    <string id="about_version">v1.0.0</string>
    <string id="about_credits">Feito com foco</string>
</resources>
```

### 4.5 `monkey.jungle`

**Antes:**
```
project.manifest = manifest.xml

base.sourcePath = source
base.resourcePath = resources
```

**Depois:**
```
project.manifest = manifest.xml

base.sourcePath = source
base.resourcePath = resources;resources-por
```

---

## 5. Storage/Properties (se aplicável)

Nenhum — esta task usa apenas estado in-memory (`SettingsState` módulo). Persistência com Properties fica para task `02-08`.

**Estado in-memory do SettingsState:**

| Variável | Tipo | Default | Onde lido | Onde escrito |
|---|---|---|---|---|
| `soundEnabled` | Boolean | false | SettingsMenuDelegate (toggle init) | SettingsMenuDelegate (onSelect) |
| `vibrationEnabled` | Boolean | true | SettingsMenuDelegate (toggle init) | SettingsMenuDelegate (onSelect) |
| `backlightOnAlert` | Boolean | true | SettingsMenuDelegate (toggle init) | SettingsMenuDelegate (onSelect) |
| `recordAsActivity` | Boolean | true | SettingsMenuDelegate (toggle init) | SettingsMenuDelegate (onSelect) |
| `language` | String | "auto" | SettingsMenu (sub-label), LanguageMenuDelegate | LanguageMenuDelegate (onSelect) |

---

## 6. Checklist de execução

- [x] 1. Criar `source/model/SettingsState.mc`
- [x] 2. Criar `source/views/SettingsMenu.mc`
- [x] 3. Criar `source/delegates/SettingsMenuDelegate.mc`
- [x] 4. Criar `source/views/LanguageMenu.mc`
- [x] 5. Criar `source/delegates/LanguageMenuDelegate.mc`
- [x] 6. Criar `source/views/AboutView.mc`
- [x] 7. Criar `source/delegates/AboutDelegate.mc`
- [x] 8. Modificar `source/delegates/HomeDelegate.mc` (onSelect index 4 + onMenu)
- [x] 9. Modificar `source/ui/layout/Dimensions.mc` (adicionar about*Y)
- [x] 10. Modificar `resources/strings/strings.xml` (adicionar 13 strings EN)
- [x] 11. Modificar `resources-por/strings/strings.xml` (adicionar 13 strings PT)
- [x] 12. Modificar `monkey.jungle` (adicionar resources-por ao resourcePath)
- [x] 13. Build para fr255
- [x] 14. Build para fr255s
- [x] 15. Build para fr265
- [ ] 16. Testar no simulador (caminho feliz)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros

### Manual (simulador)
- [ ] Menu Settings abre via onSelect(index=4) no carousel
- [ ] Menu Settings abre via onMenu() (long-press) de qualquer posição
- [ ] 4 toggles refletem estado do SettingsState ao interagir
- [ ] Language sub-menu abre, seleciona opção, sub-label atualiza ao voltar
- [ ] History item navega para HistoryView existente
- [ ] About item navega para AboutView com wordmark, versão, tagline, créditos
- [ ] Back no SettingsMenu retorna ao HomeView
- [ ] AboutView renderiza corretamente (fundo BG, texto centralizado)

---

## 8. Out of scope
- Persistência de settings com `Application.Properties` (task 02-08).
- Settings via Garmin Connect mobile (resources/settings/).
- Aplicação runtime dos toggles (vibrar/som baseado nos settings) — tasks 02-xx.
- Troca real de idioma em runtime (o selector apenas muda SettingsState.language; Connect IQ resolve i18n no boot).
- Delete de itens no History.

---

## Apêndice: Código dos arquivos a criar

### A1. `source/model/SettingsState.mc`

```monkeyc
using Toybox.Lang;

module SettingsState {
    var soundEnabled as Lang.Boolean = false;
    var vibrationEnabled as Lang.Boolean = true;
    var backlightOnAlert as Lang.Boolean = true;
    var recordAsActivity as Lang.Boolean = true;
    var language as Lang.String = "auto";
}
```

### A2. `source/views/SettingsMenu.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});

        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound) as Lang.String,
            null,
            :soundEnabled,
            SettingsState.soundEnabled,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration) as Lang.String,
            null,
            :vibrationEnabled,
            SettingsState.vibrationEnabled,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_backlight) as Lang.String,
            null,
            :backlightOnAlert,
            SettingsState.backlightOnAlert,
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_record_activity) as Lang.String,
            null,
            :recordAsActivity,
            SettingsState.recordAsActivity,
            null
        ));
        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language) as Lang.String,
            getLanguageSubLabel(),
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
    }

    function getLanguageSubLabel() as Lang.String {
        if (SettingsState.language.equals("en")) {
            return Ui.loadResource(Rez.Strings.language_en) as Lang.String;
        }
        if (SettingsState.language.equals("pt")) {
            return Ui.loadResource(Rez.Strings.language_pt) as Lang.String;
        }
        return Ui.loadResource(Rez.Strings.language_auto) as Lang.String;
    }
}
```

### A3. `source/delegates/SettingsMenuDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (item instanceof Ui.ToggleMenuItem) {
            var toggle = item as Ui.ToggleMenuItem;
            if (id == :soundEnabled) {
                SettingsState.soundEnabled = toggle.isEnabled();
            } else if (id == :vibrationEnabled) {
                SettingsState.vibrationEnabled = toggle.isEnabled();
            } else if (id == :backlightOnAlert) {
                SettingsState.backlightOnAlert = toggle.isEnabled();
            } else if (id == :recordAsActivity) {
                SettingsState.recordAsActivity = toggle.isEnabled();
            }
            return;
        }

        if (id == :language) {
            Ui.pushView(new LanguageMenu(), new LanguageMenuDelegate(), Ui.SLIDE_LEFT);
        } else if (id == :history) {
            var view = new HistoryView();
            Ui.pushView(view, new HistoryDelegate(view), Ui.SLIDE_LEFT);
        } else if (id == :about) {
            Ui.pushView(new AboutView(), new AboutDelegate(), Ui.SLIDE_LEFT);
        }
    }
}
```

### A4. `source/views/LanguageMenu.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenu extends Ui.Menu2 {
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
}
```

### A5. `source/delegates/LanguageMenuDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class LanguageMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();

        if (id == :auto) {
            SettingsState.language = "auto";
        } else if (id == :en) {
            SettingsState.language = "en";
        } else if (id == :pt) {
            SettingsState.language = "pt";
        }

        Ui.popView(Ui.SLIDE_RIGHT);
    }
}
```

### A6. `source/views/AboutView.mc`

```monkeyc
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
        _versionText = Ui.loadResource(Rez.Strings.about_version) as Lang.String;
        _taglineText = Ui.loadResource(Rez.Strings.about_tagline) as Lang.String;
        _creditsText = Ui.loadResource(Rez.Strings.about_credits) as Lang.String;
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
```

### A7. `source/delegates/AboutDelegate.mc`

```monkeyc
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class AboutDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}
```
