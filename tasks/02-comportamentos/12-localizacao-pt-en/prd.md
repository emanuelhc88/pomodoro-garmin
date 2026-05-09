# PRD — Task 02-12: Localisation PT/EN + Polish Final

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Implementar um modulo `Strings` wrapper que centraliza lookups de string com suporte a override manual de idioma (setting Language: Auto/EN/PT). Corrigir strings hardcoded em TimerView e PhaseTransitionView. Completar strings PT ausentes. Adicionar scripts de lint e build release. Fazer varredura final de polish.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que oferece |
|---|---|
| `resources/strings/strings.xml` | 48 strings EN (default) — completo |
| `resources-por/strings/strings.xml` | 43 strings PT — faltam 5 |
| `source/repositories/SettingsRepository.mc` | `getLanguage()` retorna "auto"/"en"/"pt" |
| `source/utils/DateUtils.mc` | `getLocale()` e `getMonthNames()` ja locale-aware, mas usa so system language |
| `source/views/LanguageMenu.mc` | Menu com 3 opcoes: Auto/English/Portugues |
| `source/delegates/LanguageMenuDelegate.mc` | Persiste escolha via `SettingsRepository` |
| `monkey.jungle` | `base.resourcePath = resources;resources-por` ja configurado |
| `manifest.xml` | `<iq:language>eng</iq:language>` e `por` ja declarados |

### 2.2 Assets disponiveis

- Nenhum asset novo necessario (task e puramente logica/strings).
- Icone launcher e drawables ja existem.

### 2.3 Approach de implementacao

**Decisao: Wrapper `Strings` module com dicionarios internos.**

Justificativa:
- Connect IQ NAO permite forcar locale em runtime — `Ui.loadResource(Rez.Strings.x)` sempre resolve pelo system language.
- O setting Language com override manual so funciona se resolvermos strings em codigo.
- O codebase atual ja usa `Ui.loadResource()` em ~35 pontos. Migrar para `Strings.get(:key)` e mecanico mas necessario.
- Alternativa rejeitada: remover override do settings. O task spec pede o wrapper.

**Mecanica:**
1. `Strings.get(:key)` verifica `SettingsRepository.getLanguage()`.
2. Se "auto" → delega para `Ui.loadResource(Rez.Strings.<key>)` (framework resolve).
3. Se "en" ou "pt" → retorna de dicionario interno `_en` ou `_pt`.
4. Views chamam `Strings.get(:phase_focus)` em vez de `Ui.loadResource(Rez.Strings.phase_focus)`.

**Trade-off aceito:** duplicacao de strings (XML + dicionario em .mc). Mas para V1 com apenas 2 idiomas e ~48 strings, a memoria extra e negligivel (~2KB).

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `System.getDeviceSettings().systemLanguage` | Detectar idioma do device | Retorna `Lang.Number` (constante `Sys.LANGUAGE_*`) |
| `Sys.LANGUAGE_POR` | Constante para portugues | `Lang.Number` |
| `Sys.LANGUAGE_ENG` | Constante para ingles | `Lang.Number` |
| `Ui.loadResource(Rez.Strings.*)` | Carregar string (modo auto) | `(Symbol) => Object` |

### 2.5 Cores/dimensoes/strings necessarias

**Strings ausentes em `resources-por/strings/strings.xml`:**

| Key | Valor PT |
|---|---|
| `today_session_singular` | Hoje: 1 sessao |
| `recovery_title` | Retomar sessao? |
| `recovery_remaining` | Restante: $1$ |
| `recovery_resume` | Retomar |
| `recovery_discard` | Descartar |

**Strings hardcoded que devem migrar para Strings.get():**

| Arquivo | Linha | String atual | Key |
|---|---|---|---|
| `TimerView.mc` | 90 | `"FOCUS"` | `:phase_focus` |
| `TimerView.mc` | 91 | `"BREAK"` | `:phase_break` |
| `TimerView.mc` | 92 | `"LONG BREAK"` | `:phase_long_break` |
| `PhaseTransitionView.mc` | 58 | `"Session"`, `"of"` | `:session_n_of_m` |

**Wordmark "toma"** em `Wordmark.mc:8`: manter — e nome da marca, nao traduzido.

---

## 3. Decisoes a tomar

### D1. Onde colocar o modulo Strings?

| Opcao | Pro | Contra |
|---|---|---|
| `source/utils/Strings.mc` | Padrao de utils existente | Strings nao e utility pura |
| `source/i18n/Strings.mc` | Semantica clara | Nova pasta, diverge de architecture.md |
| **`source/utils/Strings.mc`** (recomendado) | Consistente com TimeFormatter/DateUtils | — |

**Recomendacao:** `source/utils/Strings.mc`. Consistente com pattern existente.

### D2. Como o Strings.get() acessa o SettingsRepository?

| Opcao | Pro | Contra |
|---|---|---|
| Parametro no get: `Strings.get(:key, repo)` | Puro, sem acoplamento | Verbose em cada call site |
| Singleton: `Strings.init(repo)` no onStart | Uma unica vez | Acoplamento, mas aceitavel para V1 |
| **App.getApp() dentro do modulo** (recomendado) | Zero setup, pattern ja usado no codebase | Acoplamento com TomaApp |

**Recomendacao:** Acessar via `App.getApp().getSettingsRepo()` dentro de `Strings`. Pattern ja usado em HistoryView, HomeView, etc.

### D3. DateUtils.getLocale() deve respeitar setting ou so system?

**Recomendacao:** Sim, migrar `DateUtils.getLocale()` para usar a mesma logica de `Strings` (respeitar setting override). Caso contrario, datas aparecem em ingles mesmo com setting = PT.

### D4. Strings.get() deve fazer cache do dicionario ou resolver a cada chamada?

**Recomendacao:** Resolver a cada chamada. O custo e uma lookup em Dictionary (~O(1)). Cache adiciona complexidade (invalidacao quando setting muda) sem ganho mensuravel.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | Memoria: dicionarios PT + EN em codigo (~48 entries cada) somam ~4KB de heap | Budget e 512KB; 4KB = 0.8%. Negligivel. |
| 2 | `Ui.loadResource()` chamado no modo "auto" dentro de `onUpdate` pode alocar | Manter cache de strings em vars de instancia como feito hoje (pattern ja validado no codebase) |
| 3 | Mudar de `Rez.Strings` para `Strings.get()` em 35+ call sites — risco de typo | Compilar com `--typecheck=Strict`; se key nao existe no dicionario, retorna fallback |
| 4 | `Sys.LANGUAGE_POR` pode nao existir em todos SDKs | Usar constante numerica como fallback: `LANGUAGE_POR == 19` |
| 5 | Strings que usam `Lang.format` (com $1$, $2$) precisam de funcao separada | Implementar `Strings.format(:key, [args])` que faz `Lang.format(get(:key), args)` |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| **`source/utils/Strings.mc`** (NOVO) | Modulo wrapper com dicionarios EN/PT e funcoes get/format |
| `source/views/TimerView.mc` | Migrar hardcoded strings para `Strings.get()` |
| `source/views/PhaseTransitionView.mc` | Migrar hint hardcoded para `Strings.format()` |
| `source/views/HomeView.mc` | Migrar para `Strings.get()` |
| `source/views/CustomBuilderView.mc` | Migrar para `Strings.get()` |
| `source/views/CycleCompleteView.mc` | Migrar para `Strings.get()` |
| `source/views/HistoryView.mc` | Migrar para `Strings.get()` |
| `source/views/SettingsMenu.mc` | Migrar para `Strings.get()` |
| `source/views/ConfirmStopView.mc` | Migrar para `Strings.get()` |
| `source/views/RecoveryView.mc` | Migrar para `Strings.get()` |
| `source/views/AboutView.mc` | Migrar para `Strings.get()` |
| `source/utils/TimeFormatter.mc` | Migrar para `Strings.get()` |
| `source/utils/DateUtils.mc` | `getLocale()` respeitar setting override |
| `resources-por/strings/strings.xml` | Completar 5 strings ausentes |
| **`scripts/check-strings.sh`** (NOVO) | Linter grep para strings hardcoded em views/delegates/ui |
| **`scripts/build-release.sh`** (NOVO) | Gera `.iq` multi-device |
| **`README.md`** (NOVO) | README basico do projeto |

---

## 6. Arquitetura do fluxo

```
View.onUpdate() / View.initialize()
        │
        ▼
  Strings.get(:key) / Strings.format(:key, args)
        │
        ├── setting == "auto"?
        │       │
        │       ▼ YES
        │   Ui.loadResource(Rez.Strings.<key>)
        │       │
        │       ▼
        │   [Connect IQ resolve: EN se device EN, PT se device PT]
        │
        ├── setting == "en"?
        │       │
        │       ▼ YES
        │   _en[:key]  (dicionario interno)
        │
        └── setting == "pt"?
                │
                ▼ YES
            _pt[:key]  (dicionario interno)


DateUtils.getLocale()
        │
        ├── setting != "auto"?
        │       ▼ YES
        │   return setting como :pt ou :en
        │
        └── setting == "auto"?
                ▼ YES
            Sys.getDeviceSettings().systemLanguage == LANGUAGE_POR?
                ├── YES → :pt
                └── NO → :en
```

---

## 7. Referencias para o plan.md

- `references/design_system.md` secao 7 (glossario EN/PT completo)
- `spec/spec.md` secao 4.B13
- `resources/strings/strings.xml` (lista completa de keys EN)
- `resources-por/strings/strings.xml` (estado atual PT, precisa completar)
- `source/utils/DateUtils.mc` (logica de locale atual)
- `source/views/TimerView.mc:89-93` (hardcoded strings)
- `source/views/PhaseTransitionView.mc:57-59` (hardcoded hint)

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
