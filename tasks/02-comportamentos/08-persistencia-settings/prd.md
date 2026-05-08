# PRD — Task 02-08: Persistência de Settings + Recovery

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar `SettingsRepository` para persistir todas as settings em `Application.Properties` (substituindo o `SettingsState` in-memory atual) e criar o sistema de **recovery** completo: persiste estado do timer a cada 5s em `Application.Storage`, e ao reabrir o app oferece um diálogo "Resume session?" com tempo restante calculado. Inclui `RecoveryView` + `RecoveryDelegate` (componente C14) e integração no `TomaApp.getInitialView`.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que aproveitar |
|---|---|
| `source/model/SettingsState.mc` | Define as 5 keys exatas e defaults. Será **substituído** por leitura on-demand do `SettingsRepository`. |
| `source/repositories/CounterRepository.mc` | Pattern de leitura/escrita no `App.Storage` com validação de tipo e fallback. Usar como referência de estilo. |
| `source/views/ConfirmStopView.mc` | Layout de diálogo com 2 botões (PrimaryButton). **Reutilizar exato pattern** para RecoveryView. |
| `source/delegates/ConfirmStopDelegate.mc` | Lógica de navegação up/down entre botões + onSelect. Clonar para RecoveryDelegate. |
| `source/services/AttentionService.mc` | Já lê `SettingsState.*` — precisa migrar para `SettingsRepository.get*()`. |
| `source/views/SettingsMenu.mc` | Lê `SettingsState.*` para valores iniciais dos toggles — migrar para Repository. |
| `source/delegates/SettingsMenuDelegate.mc` | Escreve em `SettingsState.*` — migrar para Repository. |
| `source/TomaApp.mc` | Entry point. `getInitialView` receberá lógica de recovery. `onTimerTick` receberá `persistThrottled`. |
| `source/model/PomodoroModel.mc` | Expõe `getState()`, `getRemainingSeconds()`, `getPreset()`, `getCyclesCompleted()`, `getCurrentCycle()` — tudo que o RecoveryService precisa serializar. |
| `source/model/Preset.mc` | Precisa de um `toDict()` e `fromDict()` para serialização no Storage. |
| `source/model/PomodoroState.mc` | Enum numérico — serializável diretamente como Number no Storage. |
| `source/utils/TimeFormatter.mc` | Já formata MM:SS — usar para mostrar remaining no RecoveryView. |
| `source/ui/layout/Dimensions.mc` | Já tem `confirmDialog*` dimensions — reutilizar para RecoveryView (mesmo tamanho). |
| `source/ui/components/PrimaryButton.mc` | Componente de botão — usado nos 2 CTAs do RecoveryView. |

### 2.2 Assets disponíveis

- Strings: precisam de 4 novas (`recovery_title`, `recovery_remaining`, `recovery_resume`, `recovery_discard`).
- Cores: todas existem em `Colors` module — nenhuma nova necessária.
- Dimensões: reutilizar `confirmDialog*` do `Dimensions` module.
- Ícones: nenhum necessário para esta task.

### 2.3 Approach de implementação

**Decisão: leitura on-demand (sem cache).**

O `AttentionService` e demais consumidores leem diretamente via `SettingsRepository.get*()` a cada uso, em vez de cachear em variáveis module-level. Razão: elimina bug de stale data, simplifica o código (sem listener/observer pattern), e o custo de `Properties.getValue` é desprezível (leitura de flash local).

**Implicação:** o módulo `SettingsState` será **removido** completamente. Todo acesso a settings passa pelo `SettingsRepository`.

**Recovery:** estado serializado a cada 5s (throttle via timestamp diff). Ao reabrir, `RecoveryService.checkOnStart()` calcula remaining real. Se < 60s, descarta automaticamente.

**Serialização de estado:** `PomodoroState` já é enum numérico (0-5). Serializável diretamente como `Number` no Storage Dictionary. Não precisa converter para String.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `Toybox.Application.Properties.getValue(key as String) as PropertyValueType or Null` | Ler settings | Retorna null na primeira execução. |
| `Toybox.Application.Properties.setValue(key as String, value as PropertyValueType) as Void` | Persistir settings | PropertyValueType = Number, Float, Long, Double, String, Boolean, Char. |
| `Toybox.Application.Storage.getValue(key as String) as StorageValueType or Null` | Ler recovery state | StorageValueType inclui Dictionary e Array. |
| `Toybox.Application.Storage.setValue(key as String, value as StorageValueType) as Void` | Persistir recovery state | |
| `Toybox.Application.Storage.deleteValue(key as String) as Void` | Limpar recovery state | |
| `Toybox.Time.now() as Time.Moment` | Timestamp para savedAt | `.value()` retorna epoch seconds (Number). |

Fonte: `references/garmin_platform.md` §2.3, §2.4.

### 2.5 Cores/dimensões/strings necessárias

**Strings novas (EN):**

| ID | Valor |
|---|---|
| `recovery_title` | `Resume session?` |
| `recovery_remaining` | `Remaining: $1$` |
| `recovery_resume` | `Resume` |
| `recovery_discard` | `Discard` |

**Strings novas (PT):** (para task 02-12, mas registrar keys agora)

| ID | Valor |
|---|---|
| `recovery_title` | `Retomar sessão?` |
| `recovery_remaining` | `Restante: $1$` |
| `recovery_resume` | `Retomar` |
| `recovery_discard` | `Descartar` |

**Cores:** nenhuma nova. Usa `Colors.TEXT_PRIMARY`, `Colors.TEXT_MUTED`, `Colors.BG`, `Colors.BORDER`, `Colors.BRAND`.

**Dimensões:** reutiliza `confirmDialog*`, `confirmButton*`, `confirmTitle*` de `Dimensions.mc`. O RecoveryView terá um subtitle extra (remaining) — adicionar `confirmSubtitleY`.

### Properties keys (definidos em resources/settings/properties.xml):

| Key | Type | Default |
|---|---|---|
| `soundEnabled` | Boolean | false |
| `vibrationEnabled` | Boolean | true |
| `backlightOnAlert` | Boolean | true |
| `recordAsActivity` | Boolean | true |
| `language` | String | "auto" |
| `lastSelectedPreset` | Number | 0 |
| `customWorkMin` | Number | 25 |
| `customBreakMin` | Number | 5 |
| `customCycles` | Number | 4 |

---

## 3. Decisões a tomar

### D1: Manter ou remover `SettingsState` module?

| Opção | Pros | Contras |
|---|---|---|
| **A) Remover** (recomendado) | Elimina duplicação, single source of truth, impossível ter stale data | Todos os consumidores precisam ser migrados |
| B) Manter como cache | Leitura mais rápida, menos chamadas a Properties | Possibilidade de stale data, mais complexidade |

**Recomendação:** A — remover. O custo de `Properties.getValue` é negligível e a simplicidade compensa.

### D2: Threshold mínimo de recovery (MIN_RESUME_SECONDS)

| Opção | Pros | Contras |
|---|---|---|
| **A) 60s** (recomendado) | Não interrompe por quase nada, mas retoma sessões reais | Pode perder os últimos 59s de uma sessão de 5min |
| B) 30s | Mais agressivo em preservar | Diálogo aparece por qualquer saída acidental |

**Recomendação:** A — 60s conforme spec (§6 regra 7).

### D3: Custom preset — persistir em Properties ou manter in-memory?

| Opção | Pros | Contras |
|---|---|---|
| **A) Persistir em Properties** (recomendado) | Custom sobrevive a kill, alinhado com spec B2 | Precisa de `customWorkMin`/`customBreakMin`/`customCycles` keys |
| B) In-memory (atual) | Já funciona | Perde ao fechar, contradiz a spec |

**Recomendação:** A — a task já lista essas Properties keys na spec. O CustomBuilderDelegate deve persisitir ao confirmar.

### D4: `lastSelectedPreset` — quando persiste?

| Opção | Pros | Contras |
|---|---|---|
| **A) Ao iniciar sessão** (recomendado) | Persiste a última escolha efetiva | Mudar sem iniciar não persiste |
| B) Ao navegar no carousel | Persiste a última visualização | Pode persistir algo não intencional |

**Recomendação:** A — persistir no `HomeDelegate.onSelect` ao efetivamente iniciar.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | Properties retorna null na primeira execução (pre-`properties.xml`) | Todos os getters têm default explícito no código |
| 2 | Storage serialization do Dictionary — types complexos perdem type info | Serializar apenas primitivos (Number, String, Boolean) dentro do dict |
| 3 | Timer tick pode ocorrer com model em estado transitório durante recovery hydration | Não iniciar TimerService até model estar fully hydrated |
| 4 | Ao remover `SettingsState`, typecheck pode falhar em imports que o referenciam | Migrar todos os consumidores na mesma task |
| 5 | `Preset.toDict()` / `fromDict()` — se Preset mudar no futuro, recovery dict fica incompatível | Incluir schema version no dict? — overkill para V1, aceitar risco |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/repositories/SettingsRepository.mc` | **Criar** | Read/write todas as settings via Properties. Centraliza keys e defaults. |
| `source/services/RecoveryService.mc` | **Criar** | checkOnStart, persistThrottled, clear. Serializa/deserializa estado do model. |
| `source/model/RecoveryState.mc` | **Criar** | Tipo de dados que representa o estado recuperável (preset, phase, remaining, cyclesCompleted, currentCycle). |
| `source/views/RecoveryView.mc` | **Criar** | Diálogo C14: título, subtitle (remaining), 2 botões. |
| `source/delegates/RecoveryDelegate.mc` | **Criar** | Input do RecoveryView: Resume → hydrate + navega para TimerView; Discard → clear + navega para HomeView. |
| `source/model/Preset.mc` | **Modificar** | Adicionar `toDict()` e factory `fromDict()`. |
| `source/model/SettingsState.mc` | **Remover** | Substituído por SettingsRepository. |
| `source/TomaApp.mc` | **Modificar** | Adicionar `_recoveryService`, `_settingsRepo`. `getInitialView` checa recovery. `onTimerTick` chama `persistThrottled`. `stopSession` e `onComplete` chamam `clear`. |
| `source/services/AttentionService.mc` | **Modificar** | Trocar `SettingsState.*` por `SettingsRepository.get*()`. |
| `source/views/SettingsMenu.mc` | **Modificar** | Ler iniciais de `SettingsRepository` em vez de `SettingsState`. |
| `source/delegates/SettingsMenuDelegate.mc` | **Modificar** | Escrever via `SettingsRepository.set*()` em vez de `SettingsState.*`. |
| `source/delegates/HomeDelegate.mc` | **Modificar** | Persistir `lastSelectedPreset` ao iniciar sessão. |
| `source/views/HomeView.mc` | **Modificar** | Ler `lastSelectedPreset` no initialize para selecionar default. |
| `source/delegates/CustomBuilderDelegate.mc` | **Modificar** | Persistir custom values em Properties ao confirmar. Ler values do Properties no initialize. |
| `source/views/CustomBuilderView.mc` | **Modificar** | Receber valores iniciais (de Properties) no constructor. |
| `source/ui/layout/Dimensions.mc` | **Modificar** | Adicionar `confirmSubtitleY` para o RecoveryView. |
| `resources/strings/strings.xml` | **Modificar** | Adicionar 4 strings de recovery. |
| `resources/settings/properties.xml` | **Criar** | Declarar defaults de todas as Properties keys (para Garmin Connect mobile). |
| `tests/SettingsRepositoryTest.mc` | **Criar** | Testes de get defaults, set/get round-trip. |
| `tests/RecoveryServiceTest.mc` | **Criar** | Testes de check empty, check valid, check expired, throttle. |

---

## 6. Arquitetura do fluxo

### Fluxo de persistência de Settings

```
SettingsMenu (UI)
    │ onSelect(toggle)
    ▼
SettingsMenuDelegate
    │ SettingsRepository.set*(value)
    ▼
Application.Properties.setValue(key, value)
    │
    ▼ (próximo uso)
AttentionService / qualquer consumidor
    │ SettingsRepository.get*()
    ▼
Application.Properties.getValue(key) → valor atualizado
```

### Fluxo de Recovery — Persist

```
TomaApp.onTimerTick()
    │ (a cada 1s)
    ▼
RecoveryService.persistThrottled(model)
    │ if (now - lastSaved >= 5s)
    │   serialize model state → Dictionary
    ▼
Application.Storage.setValue("activeSession", dict)
```

### Fluxo de Recovery — Restore

```
TomaApp.getInitialView()
    │
    ▼
RecoveryService.checkOnStart()
    │ Storage.getValue("activeSession")
    │ if null → return null → show HomeView
    │ else:
    │   elapsed = now - savedAt
    │   newRemaining = remaining - elapsed
    │   if newRemaining < 60 → delete, return null
    │   else → return RecoveryState
    ▼
RecoveryView (show dialog)
    │ user picks Resume or Discard
    ▼
RecoveryDelegate
    ├── Resume → hydrate PomodoroModel → startTimerService → push TimerView
    └── Discard → RecoveryService.clear() → show HomeView
```

### Fluxo de Recovery — Clear

```
Sessão completa (ON_COMPLETE) ou Stop (ON_STOP)
    │
    ▼
TomaApp.onModelEvent
    │ RecoveryService.clear()
    ▼
Storage.deleteValue("activeSession")
```

### Fluxo de Custom Preset — Persist

```
CustomBuilderDelegate.onBack() (confirmar)
    │
    ▼
SettingsRepository.setCustomWorkMin(val)
SettingsRepository.setCustomBreakMin(val)
SettingsRepository.setCustomCycles(val)
    │
    ▼
Application.Properties.setValue(...)
```

---

## 7. Referências para o plan.md

| Referência | Seções relevantes |
|---|---|
| `references/architecture.md` | §3 (Repositories), §4 (coding rules), §7 (anti-patterns) |
| `references/garmin_platform.md` | §2.3 (Properties), §2.4 (Storage), §6 (Recovery strategy), §11 (gotchas) |
| `spec/spec.md` | §4.B12 (Settings persistentes), §4.B16 (Recovery após kill), §6 regra 7 (threshold 60s), §2.P8 (Settings menu) |
| `source/views/ConfirmStopView.mc` | Pattern visual para RecoveryView |
| `source/delegates/ConfirmStopDelegate.mc` | Pattern de delegate para RecoveryDelegate |
| `source/repositories/CounterRepository.mc` | Pattern de Storage read/write |
| `tests/CounterRepositoryTest.mc` | Pattern de teste para repositories |

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação (D1-D4).
- [x] Riscos identificados com mitigação (5 riscos).
- [x] Arquivos listados com responsabilidade clara (20 arquivos).
- [x] Fluxo de dados documentado (4 fluxos).
- [x] Strings e cores mapeadas (4 strings novas, 0 cores novas).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
