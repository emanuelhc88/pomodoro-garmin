# PRD — Task 02-07: Preset Personalizado (persistência)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar `PresetRepository` como camada dedicada com clamping de valores, e corrigir o fluxo de `CustomBuilderDelegate` para salvar o preset e retornar à Home (P1) em vez de iniciar sessão automaticamente. A Home (P1) ao selecionar Custom para iniciar, carrega valores persistidos via `PresetRepository`.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que oferece |
|---|---|
| [source/repositories/SettingsRepository.mc](source/repositories/SettingsRepository.mc) | Já possui `getCustomWorkMin/setCustomWorkMin`, `getCustomBreakMin/setCustomBreakMin`, `getCustomCycles/setCustomCycles` — leitura/escrita direta em Properties com defaults corretos (25/5/4). **Não tem clamping.** |
| [source/model/Preset.mc](source/model/Preset.mc) | Struct `Preset` com `workMin`, `breakMin`, `cycles`, `isCustom`. Possui `toDict()`/`fromDict()`. Módulo `PresetLimits` com constantes de range e step já definidas. |
| [source/views/CustomBuilderView.mc](source/views/CustomBuilderView.mc) | Recebe `workMin/breakMin/cycles` no `initialize()`. Métodos de edição com clamping local (via `_getMin/_getMax`). `buildPreset()` retorna Preset com valores editados. |
| [source/delegates/CustomBuilderDelegate.mc](source/delegates/CustomBuilderDelegate.mc) | `onBack()` já salva via `repo.setCustomWorkMin(...)` etc. **Problema:** também inicia sessão — deve apenas salvar e `popView`. |
| [source/delegates/HomeDelegate.mc](source/delegates/HomeDelegate.mc) | Para `selectedIndex == 3` (Custom), já lê valores via `repo.getCustomWorkMin()` etc e cria Preset antes de pushView para CustomBuilder. |
| [tests/SettingsRepositoryTest.mc](tests/SettingsRepositoryTest.mc) | Testes existentes cobrem defaults e set/get de custom values. |
| [resources/settings/properties.xml](resources/settings/properties.xml) | Keys `customWorkMin`, `customBreakMin`, `customCycles` já declaradas com defaults. |

### 2.2 Assets disponíveis

Não há novos assets visuais. A UI do Custom Builder (P2) já existe e funciona.

### 2.3 Approach de implementação

**Decisão: criar `PresetRepository` como camada fina sobre `SettingsRepository` que adiciona clamping.**

Justificativa:
- A task exige que valores fora de range sejam "clamped" ao ler (proteção contra dados corrompidos ou edição via Garmin Connect mobile no futuro).
- `SettingsRepository` já faz a I/O — `PresetRepository` adiciona apenas a semântica de validação e a interface de domínio (`loadCustom()`/`saveCustom(preset)`).
- Manter `SettingsRepository` intocado evita regressão nos tests existentes.

**Correção do fluxo:** `CustomBuilderDelegate.onBack()` deve salvar e `popView(SLIDE_RIGHT)` para retornar à P1 — não iniciar sessão. A sessão só é iniciada quando o usuário seleciona Custom em P1 e pressiona Enter novamente (fluxo já implementado em `HomeDelegate`).

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `Toybox.Application.Properties.getValue(key as String) as PropertyValueType or Null` | Leitura de custom values | Confirmado em garmin_platform.md §2.3 |
| `Toybox.Application.Properties.setValue(key as String, value as PropertyValueType) as Void` | Escrita de custom values | Confirmado em garmin_platform.md §2.3 |

Nenhuma API nova necessária. Todas já utilizadas pelo `SettingsRepository`.

### 2.5 Cores/dimensões/strings necessárias

Nenhuma nova — a UI de P2 já existe com todas as strings (`custom_builder_title`, `custom_label_work`, `custom_label_break`, `custom_label_cycles`, `unit_min`, `hints_nav`, `hints_edit`).

---

## 3. Decisões a tomar

### 3.1 PresetRepository vs expandir SettingsRepository

| Opção | Prós | Contras |
|---|---|---|
| A) Criar `PresetRepository` separado (delegando I/O para SettingsRepo) | Separação de responsabilidades, clamping encapsulado, segue a task spec | Mais um arquivo |
| B) Adicionar `loadCustom()/saveCustom()` direto no SettingsRepository | Menos arquivos | Mistura settings genéricos com lógica de domínio de preset, viola SRP |

**Recomendação: Opção A.** A task spec pede explicitamente `PresetRepository`. A architecture.md §3 define repositories como camada única de persistência com tipos do projeto.

### 3.2 CustomBuilderDelegate.onBack() — fluxo ao confirmar

| Opção | Prós | Contras |
|---|---|---|
| A) Salvar + popView (retorna a P1) | Segue spec B2 à risca: editar → salvar → voltar. Sessão inicia só quando usuário seleciona Custom em P1 de novo | Requer 2 ações para editar+iniciar |
| B) Manter fluxo atual (salvar + iniciar sessão direto) | 1 ação menos | Contradiz spec B2 que diz "volta para P1 com Custom selecionado" |

**Recomendação: Opção A.** A spec é clara: P2 é editor, não initiator. Iniciar sessão é responsabilidade de P1 (`HomeDelegate.onSelect`).

### 3.3 HomeDelegate ao iniciar com Custom — quem constrói o Preset?

| Opção | Prós | Contras |
|---|---|---|
| A) Ler via `PresetRepository.loadCustom()` | Clamping garantido, API limpa | Delegate depende de PresetRepository |
| B) Ler via `SettingsRepository.getCustom*()` direto (como está hoje) | Já funciona | Sem clamping, não usa novo repo |

**Recomendação: Opção A.** Delegate obtém `PresetRepository` via `app.getPresetRepo()`.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | `Number.max()` / `Number.min()` podem não existir em Monkey C (ou ter semântica diferente) | Usar comparação manual: `if (v < min) { v = min; }` — abordagem já usada no CustomBuilderView |
| 2 | `CustomBuilderDelegate.onBack()` mudança de comportamento quebra fluxo UX se alguém esperava sessão automática | A spec B2 é explícita sobre o fluxo correto. Testes manuais validam |
| 3 | Dados corrompidos em Properties (null ou tipo errado) | PresetRepository aplica clamping + fallback defaults. SettingsRepository já trata null |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/repositories/PresetRepository.mc` | CRIAR | `loadCustom()` → lê de SettingsRepo + clamp. `saveCustom(preset)` → clamp + escreve via SettingsRepo. |
| `tests/PresetRepositoryTest.mc` | CRIAR | Testes: defaults, save/load round-trip, clamping de valores fora de range. |
| `source/delegates/CustomBuilderDelegate.mc` | MODIFICAR | `onBack()` → salvar via PresetRepository + `popView(SLIDE_RIGHT)` (remover início de sessão). |
| `source/delegates/HomeDelegate.mc` | MODIFICAR | `onSelect()` para index==3: ao entrar em P2, carrega via `PresetRepository.loadCustom()`. |
| `source/TomaApp.mc` | MODIFICAR | Adicionar `_presetRepo` e `getPresetRepo()` getter. |

---

## 6. Arquitetura do fluxo

```
┌─────────────────── HOME (P1) ────────────────────┐
│                                                    │
│  User selects "Custom" → Enter                    │
│  │                                                │
│  ├─ app.getPresetRepo().loadCustom() → Preset     │
│  │                                                │
│  └─ pushView(CustomBuilderView(preset), ...)      │
│                                                    │
└────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────── CUSTOM BUILDER (P2) ─────────────────┐
│                                                    │
│  User edits work/break/cycles                     │
│  User presses Back (not editing)                  │
│  │                                                │
│  ├─ preset = _view.buildPreset()                  │
│  ├─ app.getPresetRepo().saveCustom(preset)        │
│  └─ Ui.popView(SLIDE_RIGHT) → volta para P1      │
│                                                    │
└────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────── HOME (P1) ────────────────────┐
│                                                    │
│  Custom selecionado (index=3 preservado)          │
│  User presses Enter                               │
│  │                                                │
│  ├─ preset = app.getPresetRepo().loadCustom()     │
│  ├─ app.startSession(preset)                      │
│  └─ pushView(TimerView) → sessão com 45:00       │
│                                                    │
└────────────────────────────────────────────────────┘

PresetRepository internals:
┌──────────────────────────────────────────────────┐
│  loadCustom():                                    │
│    work  = settingsRepo.getCustomWorkMin()        │
│    brk   = settingsRepo.getCustomBreakMin()       │
│    cyc   = settingsRepo.getCustomCycles()         │
│    return Preset(clamp(work), clamp(brk),         │
│                  clamp(cyc), isCustom=true)        │
│                                                    │
│  saveCustom(preset):                              │
│    settingsRepo.setCustomWorkMin(clamp(work))     │
│    settingsRepo.setCustomBreakMin(clamp(brk))     │
│    settingsRepo.setCustomCycles(clamp(cyc))       │
│                                                    │
│  _clampWork(v): max(WORK_MIN, min(WORK_MAX, v))  │
│  _clampBreak(v): max(BREAK_MIN, min(BREAK_MAX,v))│
│  _clampCycles(v): max(CYC_MIN, min(CYC_MAX, v))  │
└──────────────────────────────────────────────────┘
```

---

## 7. Referências para o plan.md

- `tasks/02-comportamentos/07-preset-personalizado.md` — task completa.
- `references/architecture.md` §3 — Repository pattern, DI manual.
- `references/garmin_platform.md` §2.3 — Properties API.
- `spec/spec.md` §4.B2, §6 regra 2 (limites Custom) e regra 9 (Custom único).
- `source/model/Preset.mc` — struct existente + `PresetLimits`.
- `source/repositories/SettingsRepository.mc` — I/O layer existente.
- `source/delegates/CustomBuilderDelegate.mc` — fluxo a corrigir.
- `source/delegates/HomeDelegate.mc` — fluxo de iniciar sessão com Custom.
- `tests/SettingsRepositoryTest.mc` — padrão de testes para referência.

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (nenhuma nova necessária).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
