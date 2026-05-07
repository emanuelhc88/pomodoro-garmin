# PRD — Task 01-08: Tela Settings

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar a tela P8 (Settings) usando `WatchUi.Menu2` nativo do Connect IQ. O menu expõe 4 toggles (Sound, Vibration, Backlight, Record activity), 1 selector (Language via sub-menu), e 2 ações (History, About). Estado dos toggles vive em memória via singleton `SettingsState` — persistência com Properties fica para task `02-08`. A AboutView é uma tela estática com wordmark, versão e tagline.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | Reuso |
|---|---|
| `source/delegates/HomeDelegate.mc` | Ponto de integração — `onMenu()` (linha 74) já existe mas só faz `println`. Será modificado para pushView do SettingsMenu. O item `selectedIndex == 4` (Settings no carousel) também será atualizado. |
| `source/views/HistoryView.mc` | Já existe — será target do item "History" no menu Settings. |
| `source/delegates/HistoryDelegate.mc` | Já existe — delegate para HistoryView. |
| `source/ui/layout/Colors.mc` | Módulo de cores reutilizado na AboutView. |
| `source/ui/layout/Bucket.mc` | Detecção de bucket para layout da AboutView. |
| `source/ui/layout/Dimensions.mc` | Será estendido com dimensões para AboutView. |
| `source/ui/components/Wordmark.mc` | Reutilizado na AboutView para renderizar "toma". |

### 2.2 Assets disponíveis

- Wordmark component já existe em `source/ui/components/Wordmark.mc`.
- Cores definidas em `source/ui/layout/Colors.mc` (BG, TEXT_PRIMARY, TEXT_MUTED, BRAND, ACCENT).
- Strings base em `resources/strings/strings.xml` — já tem `settings_label` ("Settings").
- Launcher icon em `resources/drawables/launcher_icon.png`.

### 2.3 Approach de implementação

**Menu2 nativo:** usar `WatchUi.Menu2` com `ToggleMenuItem` para os 4 toggles e `MenuItem` para Language, History, About. Isso delega toda a renderização do menu ao sistema Garmin — sem custom draw.

**Singleton `SettingsState`:** módulo com variáveis estáticas `var` para manter estado in-memory dos toggles. O delegate lê/escreve nesse singleton. Na task `02-08` será substituído por `SettingsRepository` com Properties.

**AboutView custom:** como About não é um menu, será uma View customizada com `onUpdate` desenhando texto estático (wordmark, versão, tagline).

**LanguageMenu:** sub-menu Menu2 separado. Ao selecionar uma opção, atualiza `SettingsState.language` e o sub-label no item pai do SettingsMenu.

### 2.4 APIs Connect IQ utilizadas

| API | Uso |
|---|---|
| `WatchUi.Menu2` | Menu principal de Settings e sub-menu Language. `initialize({:title => ...})`, `addItem(...)` |
| `WatchUi.Menu2InputDelegate` | Delegate do menu. `onSelect(item as MenuItem)` para tratar toggles e ações. |
| `WatchUi.ToggleMenuItem` | 4 toggles. Construtor: `ToggleMenuItem(label, subLabel, id, enabled, options)`. `isEnabled()` retorna estado. |
| `WatchUi.MenuItem` | Items Language, History, About. Construtor: `MenuItem(label, subLabel, id, options)`. `setSubLabel(text)` para atualizar dinamicamente. |
| `WatchUi.pushView` / `WatchUi.popView` | Navegação entre menus e views. |
| `WatchUi.loadResource` | Carregar strings de `Rez.Strings`. |
| `Graphics.Dc` | Usado no AboutView para desenho manual. |

### 2.5 Cores/dimensões/strings necessárias

**Strings novas a adicionar (EN):**

| Key | EN |
|---|---|
| `settings_title` | Settings |
| `settings_sound` | Sound |
| `settings_vibration` | Vibration |
| `settings_backlight` | Backlight on alert |
| `settings_record_activity` | Record as activity |
| `settings_language` | Language |
| `settings_history` | History |
| `settings_about` | About |
| `language_auto` | Auto |
| `language_en` | English |
| `language_pt` | Português |
| `about_tagline` | Pomodoro for developers |
| `about_version` | v1.0.0 |
| `about_credits` | Made with focus |

**Strings novas (PT) — arquivo `strings_pt.xml` a criar:**

| Key | PT |
|---|---|
| `settings_title` | Ajustes |
| `settings_sound` | Som |
| `settings_vibration` | Vibração |
| `settings_backlight` | Iluminação no alerta |
| `settings_record_activity` | Gravar como atividade |
| `settings_language` | Idioma |
| `settings_history` | Histórico |
| `settings_about` | Sobre |
| `language_auto` | Auto |
| `language_en` | Inglês |
| `language_pt` | Português |
| `about_tagline` | Pomodoro para devs |
| `about_version` | v1.0.0 |
| `about_credits` | Feito com foco |

**Cores:** nenhuma nova — AboutView usa `Colors.BG`, `Colors.TEXT_PRIMARY`, `Colors.TEXT_MUTED`, `Colors.BRAND`.

**Dimensões (AboutView):** serão adicionadas ao módulo `Dimensions`:
- `aboutWordmarkY(bucket)` — posição Y do wordmark
- `aboutVersionY(bucket)` — posição Y da versão
- `aboutTaglineY(bucket)` — posição Y do tagline
- `aboutCreditsY(bucket)` — posição Y dos créditos

---

## 3. Decisões a tomar

### D1: Onde navegar para Settings — onMenu ou onSelect do item Settings?

**Opções:**
- A) `onMenu` (long-press) apenas — spec diz "Long-press Enter ou Menu: abrir Settings".
- B) `onSelect` quando `selectedIndex == 4` (item Settings no carousel) + `onMenu` como atalho.

**Recomendação:** B — o carousel já tem um 5º item "Settings" (index 4) no HomeDelegate. Manter ambos paths. O `onSelect` com index 4 já funciona parcialmente (atualmente faz pushView do HistoryView por erro). O `onMenu` passa a ser atalho de qualquer posição.

**Justificativa:** UX mais acessível — usuário pode navegar até Settings no carousel OU usar long-press de qualquer posição.

### D2: Versão — ler do manifest ou hardcode?

**Opções:**
- A) Ler de `Application.getApp().getProperty("appVersion")` — não existe esta API em Connect IQ.
- B) Hardcode `"1.0.0"` como string resource.
- C) Definir constante no código fonte.

**Recomendação:** B — usar string resource `about_version` com valor "v1.0.0". Simples de atualizar no futuro. Connect IQ não expõe versão do manifest programaticamente em runtime.

**Justificativa:** menor complexidade, segue o pattern de tudo via `Rez.Strings`.

### D3: Atualizar sub-label de Language dinamicamente?

**Opções:**
- A) Ao abrir o menu, o sub-label já mostra a seleção atual (lida de SettingsState).
- B) Após selecionar no sub-menu, atualizar o item no menu pai via `setSubLabel`.

**Recomendação:** A + B — inicializar o sub-label com o valor atual do SettingsState no `initialize()`, e também atualizar no retorno do sub-menu.

**Justificativa:** garante consistência visual em qualquer cenário.

### D4: Formato do singleton SettingsState

**Opções:**
- A) Módulo com variáveis estáticas (`module SettingsState`).
- B) Classe com instância singleton via `TomaApp`.

**Recomendação:** A — módulo com variáveis estáticas. Mais simples, sem necessidade de instanciar. Migração para Repository na task 02-08 é direta (troca acesso estático por chamada de método).

**Justificativa:** mínimo de boilerplate para estado in-memory temporário.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | `setSubLabel` em `MenuItem` pode não existir em SDK 4.1 | Verificar API docs. Se não existir, recriar o menu ao voltar do sub-menu Language. |
| 2 | `ToggleMenuItem` pode não refletir visualmente o toggle sem `requestUpdate` | Comportamento nativo do Menu2 — toggles se atualizam sozinhos ao interagir. Testar no simulador. |
| 3 | Index 4 no HomeDelegate atualmente abre HistoryView (bug/placeholder) | Corrigir para abrir SettingsMenu — HistoryView será acessível via Settings > History. |
| 4 | Não existe `strings_pt.xml` — internacionalização PT não está configurada no jungle | Criar arquivo e configurar resource path no `monkey.jungle` ou usar `resources-por/strings.xml` (formato Connect IQ padrão). |
| 5 | `Menu2` com título pode não mostrar title em todos os devices | Comportamento padrão do Menu2 — title é mostrado em todos. Validar nos 3 buckets. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/model/SettingsState.mc` (novo) | Módulo singleton com estado in-memory dos toggles e language. |
| `source/views/SettingsMenu.mc` (novo) | Extends `Ui.Menu2`. Monta menu com 4 toggles + 3 items. |
| `source/delegates/SettingsMenuDelegate.mc` (novo) | Extends `Ui.Menu2InputDelegate`. Trata toggle changes e navegação para sub-views. |
| `source/views/LanguageMenu.mc` (novo) | Sub-menu Menu2 com opções Auto/English/Português. |
| `source/delegates/LanguageMenuDelegate.mc` (novo) | Delegate do sub-menu Language. Atualiza SettingsState.language. |
| `source/views/AboutView.mc` (novo) | View estática com wordmark, versão, tagline, créditos. |
| `source/delegates/AboutDelegate.mc` (novo) | BehaviorDelegate simples — apenas `onBack` para popView. |
| `source/delegates/HomeDelegate.mc` (modificar) | `onSelect` index 4 → pushView SettingsMenu. `onMenu` → pushView SettingsMenu. |
| `source/ui/layout/Dimensions.mc` (modificar) | Adicionar dimensões `aboutWordmarkY`, `aboutVersionY`, `aboutTaglineY`, `aboutCreditsY`. |
| `resources/strings/strings.xml` (modificar) | Adicionar todas as strings settings/language/about em EN. |
| `resources-por/strings/strings.xml` (novo) | Tradução PT de todas as strings (formato Connect IQ i18n). |
| `monkey.jungle` (modificar) | Adicionar resource path para `resources-por`. |

---

## 6. Arquitetura do fluxo

```
HomeView (P1)
  │
  ├── onSelect(index=4) ────────┐
  │                              │
  └── onMenu() ─────────────────┤
                                 ▼
                         SettingsMenu (Menu2)
                           │  │  │  │  │  │  │
                           │  │  │  │  │  │  └── About → pushView(AboutView)
                           │  │  │  │  │  │                  │
                           │  │  │  │  │  │                  └── onBack → popView
                           │  │  │  │  │  │
                           │  │  │  │  │  └── History → pushView(HistoryView)
                           │  │  │  │  │                  │
                           │  │  │  │  │                  └── onBack → popView
                           │  │  │  │  │
                           │  │  │  │  └── Language → pushView(LanguageMenu)
                           │  │  │  │                  │
                           │  │  │  │                  ├── Auto → SettingsState.language = "auto"
                           │  │  │  │                  ├── EN   → SettingsState.language = "en"
                           │  │  │  │                  └── PT   → SettingsState.language = "pt"
                           │  │  │  │                       → popView, parent sub-label updated
                           │  │  │  │
                           │  │  │  └── Record activity (toggle) → SettingsState.recordAsActivity
                           │  │  └── Backlight (toggle) → SettingsState.backlightOnAlert
                           │  └── Vibration (toggle) → SettingsState.vibrationEnabled
                           └── Sound (toggle) → SettingsState.soundEnabled
                           
                         onBack → popView → HomeView
```

**Fluxo de dados dos toggles:**
```
User taps toggle → Menu2InputDelegate.onSelect(item)
  → item instanceof ToggleMenuItem
  → SettingsState.<key> = item.isEnabled()
  → (no requestUpdate needed — Menu2 handles visual)
```

**Fluxo Language sub-menu:**
```
User selects Language item → pushView(LanguageMenu, LanguageMenuDelegate)
  → User selects option → SettingsState.language = selected
  → popView (returns to SettingsMenu)
  → SettingsMenu language item sub-label shows current selection
```

---

## 7. Referências para o plan.md

| Referência | Seções relevantes |
|---|---|
| `references/architecture.md` | §3 (View extends Menu2), §4 (naming, strings, cores) |
| `references/design_system.md` | §7 (strings/tom de voz), §6.2 (mockup Menu nativo) |
| `references/garmin_platform.md` | §2.5 (Menu2 + Menu2InputDelegate — código de referência completo) |
| `spec/spec.md` | §2.P8 (conteúdo/inputs), §4.B12 (settings persistentes — para preparar interface) |
| `source/delegates/HomeDelegate.mc` | Código atual do onSelect/onMenu para entender integração |
| `source/views/HistoryView.mc` | Entender como History é instanciada (para reuso no item Settings>History) |

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação (D1-D4).
- [x] Riscos identificados com mitigação (5 riscos).
- [x] Arquivos listados com responsabilidade clara (12 arquivos).
- [x] Fluxo de dados documentado (diagrama textual).
- [x] Strings e cores mapeadas (15 strings EN + 15 PT, cores existentes).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
