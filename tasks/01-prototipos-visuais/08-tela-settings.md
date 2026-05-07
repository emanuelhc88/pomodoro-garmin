# Task 01-08: Tela Settings

## Objetivo

Implementar a **P8 (Settings)** usando `WatchUi.Menu2` nativo do Connect IQ. Toggles + items + selectors. Para esta task, **estado em memória apenas** — persistência real (Properties) é implementada em `02-08-persistencia-settings`.

## Tipo

- [x] Protótipo Visual
- [x] Comportamento (lógica local — toggles)

## Cobre

- **P8** (Settings) — `spec/spec.md` §2.P8
- Estrutura preparada para **B12** (Settings persistentes — `spec/spec.md` §4.B12)

## Dependências

- `tasks/01-prototipos-visuais/01-tela-home.md`.

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets.
- [ ] `--typecheck=Strict` passa.

### Manual

- [ ] Menu nativo Connect IQ Menu2 abre ao selecionar Settings em Home.
- [ ] Itens listados:
  - Sound (toggle, default OFF)
  - Vibration (toggle, default ON)
  - Backlight on alert (toggle, default ON)
  - Record as activity (toggle, default ON)
  - Language (selector — abre sub-menu)
  - History (action — abre HistoryView)
  - About (action — abre AboutView)
- [ ] Toggle alterna ao selecionar (Enter) — visualmente reflete novo estado.
- [ ] Sub-menu Language tem 3 opções: Auto, English, Português.
- [ ] About mostra:
  - "Toma" (heading)
  - "v1.0.0" (versão — ler do manifest se possível, senão hardcode por ora)
  - "Pomodoro for Garmin"
  - Texto curto sobre / créditos.
- [ ] Strings traduzidas em PT.
- [ ] Back volta para Home.

## Arquivos esperados

### Novos

- `source/views/SettingsMenu.mc` — extends `Ui.Menu2`.
- `source/delegates/SettingsMenuDelegate.mc` — extends `Ui.Menu2InputDelegate`.
- `source/views/LanguageMenu.mc` — sub-menu para Language.
- `source/delegates/LanguageMenuDelegate.mc`.
- `source/views/AboutView.mc` — view simples com texto.
- `source/delegates/AboutDelegate.mc`.

### Modificados

- `source/delegates/HomeDelegate.mc` — onSelect do item Settings agora pushView de SettingsMenu real.
- `resources/strings/strings.xml` + `strings_pt.xml`:
  - `settings_title` ("Settings" / "Ajustes")
  - `settings_sound`, `settings_vibration`, `settings_backlight`, `settings_record_activity`, `settings_language`, `settings_history`, `settings_about` — já documentadas em `design_system.md` §7.1
  - `language_auto` ("Auto" / "Auto")
  - `language_en` ("English" / "Inglês")
  - `language_pt` ("Português" / "Português")
  - `about_tagline` ("Pomodoro for developers" / "Pomodoro para devs")
  - `about_version` ("v$1$" / "v$1$")
- `manifest.xml` — adicionar `version="1.0.0"` (ou similar — verificar formato Connect IQ).

## Referências obrigatórias

- `references/architecture.md` §3 (View extends Menu2).
- `references/design_system.md` §7 (strings), §6.2 (visual menu nativo).
- `references/garmin_platform.md` §2.5 (Menu2 + Menu2InputDelegate).
- `spec/spec.md` §2.P8, §4.B12.

## Notas de design

### Menu2 estrutura

```monkeyc
class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Ui.Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});

        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound), null, "soundEnabled",
            false, // default value (in-memory only nesta task)
            null
        ));
        // ... outros toggles

        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_language),
            "Auto", // sub-label
            "language",
            null
        ));

        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_history),
            null, "history", null
        ));

        addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.settings_about),
            null, "about", null
        ));
    }
}
```

### Estado in-memory

Como ainda não temos Properties, manter um singleton:

```monkeyc
class SettingsState {
    public static var soundEnabled as Boolean = false;
    public static var vibrationEnabled as Boolean = true;
    // ...
}
```

`SettingsMenuDelegate.onSelect` lê/escreve no singleton. A migração para Repository acontece em `02-08`.

### Language sub-menu

```monkeyc
class LanguageMenu extends Ui.Menu2 {
    function initialize() {
        Ui.Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_language)});
        addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.language_auto), null, "auto", null));
        addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.language_en), null, "en", null));
        addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.language_pt), null, "pt", null));
    }
}
```

Atual seleção indicada com sub-label no item pai (atualizar dinamicamente).

### AboutView

Layout simples:

```
   ┌───────────────────────┐
   │       toma            │  ← wordmark
   │                       │
   │       v1.0.0          │  ← versão
   │                       │
   │  Pomodoro for         │  ← tagline em 2 linhas
   │  developers           │
   │                       │
   │  Made by [seu nome]   │  ← créditos opcional
   └───────────────────────┘
```

## Out of scope desta task

- Persistência real (Properties) — `02-08-persistencia-settings`.
- Reagir à mudança de language em runtime (`02-12-localizacao-pt-en`) — por enquanto, mudança não tem efeito.
- Sub-menu de duração de vibração custom (V2).
