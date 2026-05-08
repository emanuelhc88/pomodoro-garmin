# PRD — Task 02-06: Presets Builtin

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Consolidar os 4 presets builtin (25/5, 30/5, 50/10, Custom) como constantes do codigo, adicionar `getLongBreakSeconds()` ao `Preset`, garantir que `HomeDelegate.onSelect` despacha corretamente Custom para `CustomBuilderView` vs builtin para `startSession`, e fechar o ciclo com testes unitarios em `tests/PresetsTest.mc`.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que ja tem | Status |
|---|---|---|
| `source/model/Preset.mc` | Classe `Preset` com `workMin`, `breakMin`, `cycles`, `isCustom`, `formatPrimary()`, `formatSecondary()`. Modulo `Presets.builtinList()` retorna 4 presets. | Completo — ja retorna os 4 presets corretos |
| `source/model/PomodoroModel.mc` | `_transitionPhase()` ja usa `preset.breakMin * 3 * 60` inline na L150 | Precisa refatorar para usar `getLongBreakSeconds()` |
| `source/delegates/HomeDelegate.mc` | `onSelect()` ja despacha: index 3 → `CustomBuilderView`, index 4 → `SettingsMenu`, else → `startSession(preset)` | Completo — fluxo B1 ja funciona |
| `source/views/HomeView.mc` | Usa `Presets.builtinList()` no `initialize()`, renderiza com `PresetCard` | Completo |
| `source/TomaApp.mc` | `startSession(preset)`, `getLastPreset()`, observer de eventos | Completo |
| `source/delegates/CycleCompleteDelegate.mc` | "Start again" usa `app.getLastPreset()` → `startSession` | Completo |
| `source/views/CustomBuilderView.mc` | Editor de valores com limites. Privados `_workMin`, `_breakMin`, `_cycles`. Sem getter publico para construir `Preset`. | Precisa: getter ou metodo `buildPreset()` |
| `source/delegates/CustomBuilderDelegate.mc` | `onBack` faz `popView`. Nao cria Preset nem inicia sessao. | Precisa: ao sair (Back sem editing), deveria armar custom preset e/ou iniciar sessao |

### 2.2 Assets disponiveis

Nenhum asset novo necessario. Strings ja existem (`unit_cycles`, `preset_custom_label`, `settings_label`, `custom_builder_title`, labels work/break/cycles).

### 2.3 Approach de implementacao

1. **Adicionar `getLongBreakSeconds()` a `Preset`** — encapsula a regra `breakMin * 60 * 3`.
2. **Refatorar `PomodoroModel._transitionPhase()`** para usar `preset.getLongBreakSeconds()` ao inves do calculo inline.
3. **Adicionar `buildPreset()` a `CustomBuilderView`** — retorna `new Preset(_workMin, _breakMin, _cycles, true)`.
4. **Modificar `CustomBuilderDelegate.onBack`** — quando nao esta editando, antes de `popView`, armazenar o preset customizado no app para que o proximo `onSelect` em Home com index 3 possa iniciar sessao (task 02-06 pede: "Apos editar Custom, selecionar Custom no Home → TimerView roda com valores editados").
5. **Escrever `tests/PresetsTest.mc`** com 4 testes conforme spec.

**Decisao de fluxo Custom (nesta task, sem persistencia):**
- Custom em Home (index 3): se nao editado ainda, abre `CustomBuilderView` (como ja faz).
- Apos usuario editar Custom e dar Back, `CustomBuilderDelegate` salva o Preset no `TomaApp._customPreset` em memoria (nao Properties — isso e task 02-07).
- Na proxima selecao de index 3 em Home, se `app.getCustomPreset() != null`, inicia sessao com ele. Senao, abre builder.

**Porém**: a task diz "Custom preset abre CustomBuilderView, nao TimerView (a menos que ja configurado)". Isto indica que o fluxo atual (index 3 → sempre CustomBuilderView) e correto para V1 pre-persistencia. O usuario edita, volta, e so inicia se re-selecionar. Mas a task tambem quer "Apos editar Custom, selecionar Custom no Home → TimerView roda com valores editados". Conclusao: precisamos de um estado intermediario.

**Approach escolhido:** Guardar em `TomaApp._customPreset` (in-memory) quando sai do builder. No `HomeDelegate.onSelect` index 3: se `app.getCustomPreset() != null`, chama `startSession(customPreset)`; senao abre builder. O builder sempre permite re-editar via long-press ou outra nav (fora de escopo desta task — pode ser via Settings > "Edit Custom" ou simplesmente re-entrar no builder ao dar long-press em custom. Mas a task pede apenas Enter em Home index 3 → se configurado, roda).

### 2.4 APIs Connect IQ utilizadas

Nenhuma API Toybox nova. Todas ja em uso:
- `Toybox.Lang` — tipos basicos
- `Toybox.Test` — framework de testes (:test annotation)
- `Toybox.WatchUi` — pushView/popView/switchToView

### 2.5 Cores/dimensoes/strings necessarias

Nenhuma nova. Todas ja presentes nas tasks anteriores.

---

## 3. Decisoes a tomar

### D1: Comportamento de "Custom" em Home quando ja editado

| Opcao | Descricao |
|---|---|
| A) Enter → sempre abre Builder, Start dentro do Builder inicia sessao | Mais intuitivo mas requer botao Start no Builder (fora de escopo desta task) |
| B) Enter → se custom configurado inicia sessao, senao abre Builder | Alinhado com a task spec. Simples. Para re-editar, precisa de outro path. |
| C) Enter → sempre inicia sessao (usando defaults 25/5/4 se nao editado) | Nao alinhado — task pede que Custom sem editar abre Builder |

**Recomendacao: B.** E exatamente o que a task pede. Re-editar pode ser feito por long-press no custom ou via Settings (futuro). Nesta task, para "resetar" custom o usuario pode reabrir o builder de outra forma (nao coberto).

**Refinamento:** Para manter a possibilidade de re-editar, `HomeDelegate.onSelect` index 3 pode usar: `onSelect` → startSession; `onMenu` ou long-press enquanto index=3 → abre builder. Mas isso e scope creep para esta task. Manter simples: se custom != null → start. Para re-editar, pode-se adicionar um "Edit Custom" em Settings futuramente.

**Decisao final:** Opcao B, sem path de re-edicao nesta task (consistente com "Out of scope: Persistir Custom").

### D2: Onde armazenar custom preset em memoria

| Opcao | Descricao |
|---|---|
| A) `TomaApp._customPreset` | Simples, acessivel de qualquer delegate via `App.getApp()` |
| B) Atualizar `Presets.builtinList()[3]` dinamicamente | Modulos nao tem estado em Monkey C — impossivel |
| C) Variavel global ou modulo com var | Anti-pattern no projeto |

**Recomendacao: A.** Adicionar `_customPreset` ao `TomaApp` com getter/setter.

### D3: Como CustomBuilderDelegate sinaliza "custom configurado"

| Opcao | Descricao |
|---|---|
| A) `onBack` sem editing → chama `app.setCustomPreset(view.buildPreset())` antes de popView | Simples e direto |
| B) Adicionar botao "Save" explícito | Fora de escopo — spec P2 usa apenas Back para sair |

**Recomendacao: A.**

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | Custom preset perde-se ao fechar app (sem persistencia) | Esperado — task 02-07 adiciona persistencia. Documentar na UI ou aceitar. |
| 2 | Ao re-selecionar Custom apos edicao, usuario nao consegue re-editar | Aceitavel para esta task. Futuramente: long-press ou Settings path. |
| 3 | `CustomBuilderView._workMin` etc sao privados — nao ha getter publico | Adicionar metodo `buildPreset()` publico. Simples. |
| 4 | Testes precisam rodar sem `App.getApp()` | Testes de `Presets.builtinList()` e `Preset.getLongBreakSeconds()` sao puros — sem dependencia do app. OK. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/model/Preset.mc` | Adicionar `getLongBreakSeconds()` ao class `Preset` |
| `source/model/PomodoroModel.mc` | Usar `preset.getLongBreakSeconds()` em `_transitionPhase()` (L150) |
| `source/views/CustomBuilderView.mc` | Adicionar `buildPreset() as Preset` publico |
| `source/delegates/CustomBuilderDelegate.mc` | No `onBack` (sem editing): chamar `app.setCustomPreset(view.buildPreset())` antes de popView |
| `source/delegates/HomeDelegate.mc` | No `onSelect` index 3: se `app.getCustomPreset() != null` → startSession, senao abre builder |
| `source/TomaApp.mc` | Adicionar `_customPreset`, `getCustomPreset()`, `setCustomPreset()` |
| `tests/PresetsTest.mc` | **NOVO** — testes para builtinList, isCustom, formatPrimary/Secondary, getLongBreakSeconds |

---

## 6. Arquitetura do fluxo

```
Home (P1)
  │
  │ onSelect, index 0-2 (builtin)
  ├──────────────────────────────────────► TomaApp.startSession(preset)
  │                                              │
  │                                              ▼
  │                                        PomodoroModel.start(preset)
  │                                              │
  │                                              ▼
  │                                        TimerView (P3)
  │
  │ onSelect, index 3 (custom)
  ├──► app.getCustomPreset() != null?
  │       │ YES                    │ NO
  │       ▼                        ▼
  │  startSession(custom)    pushView(CustomBuilderView)
  │       │                        │
  │       ▼                        │ user edits, Back
  │  TimerView (P3)                ▼
  │                          CustomBuilderDelegate.onBack
  │                                │
  │                                ▼
  │                          app.setCustomPreset(view.buildPreset())
  │                                │
  │                                ▼
  │                          popView → Home (P1)
  │                          (next onSelect index 3 will startSession)
  │
  │ onSelect, index 4 (settings)
  └──────────────────────────────────────► SettingsMenu (P8)
```

**Long break calculation:**
```
Preset.getLongBreakSeconds()
  = breakMin * 60 * 3

PomodoroModel._transitionPhase()
  RUNNING_WORK → cyclesCompleted >= preset.cycles → RUNNING_LONG_BREAK
    _remainingSeconds = preset.getLongBreakSeconds()
```

---

## 7. Referencias para o plan.md

- `source/model/Preset.mc` — inteiro (46 linhas)
- `source/model/PomodoroModel.mc` — L135-170 (`_transitionPhase`)
- `source/delegates/HomeDelegate.mc` — inteiro (49 linhas)
- `source/delegates/CustomBuilderDelegate.mc` — inteiro (47 linhas)
- `source/views/CustomBuilderView.mc` — L1-10, L119-148 (campos privados e getters)
- `source/TomaApp.mc` — L1-15 (campos), L32-37 (`startSession`), L101-104 (`getLastPreset`)
- `tests/PomodoroModelTest.mc` — como referencia de estilo de teste

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (nenhuma nova necessaria).
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
