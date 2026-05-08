# PRD — Task 02-09: Histórico de Sessões (persistência)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar **B10** — `HistoryRepository` que persiste as últimas 50 sessões completas em `Application.Storage`, conectar ao evento `:onComplete` do `PomodoroModel` para append automático, e alimentar `HistoryView` com dados reais em vez do mock atual.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que serve |
|---|---|
| `source/model/Session.mc` | Classe já existe com todos os campos (completedAt, preset, workMin, breakMin, cycles, totalDuration) e `formatPreset()`. **Falta:** `toDict()` e `fromDict()` para serialização. |
| `source/views/HistoryView.mc` | View completa com scroll, empty state, e render via `HistoryItem.draw()`. Usa `getMockSessions()` — precisa trocar por `HistoryRepository.loadAll()`. |
| `source/delegates/HistoryDelegate.mc` | Delegate pronto (scroll up/down, back). Não precisa de alteração. |
| `source/ui/components/HistoryItem.mc` | Componente de render de item. Usa `session.formatPreset()`, `DateUtils.formatDate()`, `TimeFormatter.formatDuration()`. Sem alteração necessária. |
| `source/repositories/CounterRepository.mc` | **Pattern de referência** — usa `App.Storage.getValue/setValue` com mesmo padrão que HistoryRepository usará. |
| `source/TomaApp.mc` | Orquestra eventos via `onModelEvent()`. Já trata `ON_COMPLETE` (linhas 99-108). Precisa adicionar append ao histórico. |
| `source/model/PomodoroModel.mc` | Emite `ON_COMPLETE` corretamente. Getter `getPreset()` disponível. |
| `source/model/Preset.mc` | Tem `formatPrimary()` ("25 / 5"), `toDict()`, `fromDict()`. Campo `isCustom` para label. |
| `source/utils/DateUtils.mc` | `formatDate(epoch)` já formata datas para exibição no HistoryItem. |
| `source/utils/TimeFormatter.mc` | `formatDuration(totalSeconds)` já formata "2h 0m". |
| `tests/CounterRepositoryTest.mc` | **Pattern de teste** — usa `App.Storage.deleteValue()` para cleanup, `Test.assertEqualMessage`. |

### 2.2 Assets disponíveis

- Strings: `Rez.Strings.history_title`, `Rez.Strings.history_empty` já existem.
- Componentes visuais: `EmptyState`, `HistoryItem` — prontos.
- Cores: `Colors.TEXT_PRIMARY`, `Colors.TEXT_MUTED`, `Colors.BG`, `Colors.BORDER` — todos disponíveis.
- Dimensões: `Dimensions.historyTitleY()`, `Dimensions.historyListStartY()`, etc. — prontas.
- Nenhum asset novo necessário.

### 2.3 Approach de implementação

**Decisão: append + reverse no read.**

- Append no fim do array (O(1) amortizado) ao salvar.
- `loadAll()` retorna na ordem salva (ascendente por tempo).
- HistoryView inverte para mostrar mais recente no topo.
- Trim: quando `size() > 50`, fatia com `slice(1, null)` para remover os mais antigos.

**Justificativa:** prepend exigiria trim no final do array (mais complexo com slice), e append é a operação natural de "adicionar ao histórico".

**Construção do Session no onComplete:**
- `completedAt` = `Time.now().value()` (epoch seconds).
- `presetLabel` = `preset.isCustom ? "Custom" : preset.formatPrimary()` → simplificado para `session.formatPreset()` que já existe.
- Usar o preset do Model (`_model.getPreset()`) que ainda está disponível no momento do ON_COMPLETE.

### 2.4 APIs Connect IQ utilizadas

| API | Método | Uso |
|---|---|---|
| `Toybox.Application.Storage` | `getValue(key)` | Ler array de sessions do storage |
| `Toybox.Application.Storage` | `setValue(key, value)` | Persistir array de sessions |
| `Toybox.Application.Storage` | `deleteValue(key)` | Cleanup em testes |
| `Toybox.Time` | `Time.now().value()` | Obter epoch para `completedAt` |

**Assinatura confirmada** (garmin_platform.md §2.4):
- `App.Storage.getValue(key as String) as PropertyValueType?` — retorna null se não existe; aceita Dictionary e Array.
- `App.Storage.setValue(key as String, value as PropertyValueType) as Void` — aceita Array<Dictionary>.

### 2.5 Cores/dimensões/strings necessárias

Nenhum novo recurso visual necessário. Tudo já existe via HistoryView (task 01-07):
- Cores: `Colors.TEXT_PRIMARY`, `Colors.TEXT_MUTED`, `Colors.BG`, `Colors.BORDER`.
- Dimensões: `Dimensions.historyTitleY()`, `Dimensions.historyListStartY()`, `Dimensions.historyItemHeight()`.
- Strings: `Rez.Strings.history_title` ("HISTORY"), `Rez.Strings.history_empty` ("No sessions yet").

---

## 3. Decisões a tomar

### D1: Label do preset no Session — usar `formatPreset()` existente ou campo separado?

| Opção | Prós | Contras |
|---|---|---|
| A) Usar `Session.formatPreset()` que já gera "25/5 · 4" | Sem mudança no schema; consistente com o que HistoryItem já renderiza | Recalcula a cada render (custo negligível) |
| B) Salvar `presetLabel` separado no dict | Imutável após salvar | Adiciona campo redundante que pode ficar desincronizado |

**Recomendação: Opção A.** O campo `preset` no Session (ex: "25/5/4") já serve como label, e `formatPreset()` já está implementado e é usado pelo HistoryItem. Manter `workMin`, `breakMin`, `cycles` no dict é suficiente para reconstruir tudo.

### D2: Campo `preset` (String) no Session — manter ou remover?

O Session atual tem `var preset as String` que é o label (ex: "25/5/4"). O `formatPreset()` gera "25/5 · 4" a partir de workMin/breakMin/cycles.

| Opção | Prós | Contras |
|---|---|---|
| A) Manter `preset` como campo salvo | Compacto; label de exibição direto | Redundante com workMin/breakMin/cycles |
| B) Remover `preset`, usar apenas `formatPreset()` | Menos dados; DRY | `formatPreset()` depende de workMin/breakMin/cycles estarem corretos |

**Recomendação: Opção A.** Manter o campo `preset` como identificador do preset usado (valor simples como "25/5/4" ou "Custom"). Serve como referência legível no storage e no JSON sem precisar recalcular. A task spec já lista este campo.

### D3: Onde instanciar HistoryRepository?

| Opção | Prós | Contras |
|---|---|---|
| A) Singleton em `TomaApp` (como CounterRepository) | Consistente com padrão existente; acessível via getter | Mais um campo em TomaApp |
| B) Instanciar localmente no handler do ON_COMPLETE e em HistoryView | Menor acoplamento | Múltiplas instâncias; inconsistente com padrão |

**Recomendação: Opção A.** Seguir o padrão de `CounterRepository` — instância única em TomaApp com getter público.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | Storage excede limite de heap ao deserializar 50 sessions | Cada session é ~6 campos primitivos. 50 dicts ≈ 300 entries — bem abaixo do limite de Storage (~1-2 MB). Monitorar no Profiler. |
| 2 | `slice(1, null)` pode não funcionar como esperado em todas SDK versions | Testar no simulador. Alternativa: loop manual para copiar subarray. |
| 3 | Session não tem `toDict()`/`fromDict()` — precisa adicionar sem quebrar usos existentes | Aditivo; não altera interface existente. Mock em HistoryView já usa construtor diretamente. |
| 4 | Timing de `getPreset()` no ON_COMPLETE — Model pode ter limpo o preset | Verificar: no `_transitionPhase()` o `_preset` não é limpo ao entrar em COMPLETED. Confirmado: `stop()` limpa, mas ON_COMPLETE vem de `_transitionPhase()` antes de stop. Seguro. |
| 5 | HistoryView inicializa sessions no `initialize()` — se repository retorna vazio no primeiro frame, é correto | Design correto: empty state já tratado. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/repositories/HistoryRepository.mc` | **Criar** | CRUD de sessions em Storage (loadAll, append). Limite de 50 entries. |
| `source/model/Session.mc` | **Modificar** | Adicionar `toDict()` e `fromDict(d)` para serialização. |
| `source/TomaApp.mc` | **Modificar** | Instanciar HistoryRepository, chamar append no handler ON_COMPLETE, expor getter. |
| `source/views/HistoryView.mc` | **Modificar** | Substituir `getMockSessions()` por `HistoryRepository.loadAll()` com reverse. |
| `tests/HistoryRepositoryTest.mc` | **Criar** | Testes: list vazio, append, trim > 50, ordenação, serialização. |

---

## 6. Arquitetura do fluxo

```
┌─────────────────────────────────────────────────────────────────┐
│                        WRITE FLOW                                │
│                                                                  │
│  PomodoroModel._transitionPhase()                               │
│       │                                                          │
│       │ emits ON_COMPLETE                                        │
│       ▼                                                          │
│  TomaApp.onModelEvent(ON_COMPLETE)                              │
│       │                                                          │
│       ├── _buildSessionFromModel() → Session                    │
│       │        reads: _model.getPreset(), Time.now()            │
│       │        computes: totalDuration from preset              │
│       │                                                          │
│       ├── _historyRepo.append(session)                          │
│       │        │                                                 │
│       │        ├── session.toDict() → Dictionary                │
│       │        ├── Storage.getValue("sessionHistory")           │
│       │        ├── list.add(dict)                               │
│       │        ├── trim to MAX_ENTRIES (50)                     │
│       │        └── Storage.setValue("sessionHistory", list)     │
│       │                                                          │
│       └── (existing: vibrate, stop timer, show CycleComplete)   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        READ FLOW                                 │
│                                                                  │
│  HistoryView.initialize()                                       │
│       │                                                          │
│       ├── _historyRepo.loadAll() → Array<Session>               │
│       │        │                                                 │
│       │        ├── Storage.getValue("sessionHistory")           │
│       │        ├── if null → return []                          │
│       │        └── for each dict → Session.fromDict(d)         │
│       │                                                          │
│       ├── _reverseList(all) → mostRecent first                  │
│       │                                                          │
│       └── _sessions = reversed list                             │
│                                                                  │
│  HistoryView.onUpdate(dc)                                       │
│       │                                                          │
│       ├── if _sessions.size() == 0 → EmptyState.draw()         │
│       └── else → HistoryItem.draw() per visible session         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Referências para o plan.md

| Referência | Seção | Relevância |
|---|---|---|
| `references/architecture.md` | §3 (Repositories) | Padrão de Repository: stateless, key centralizada, métodos com tipos do projeto. |
| `references/garmin_platform.md` | §2.4 (Storage) | API Storage: getValue/setValue. Diferença com Properties. |
| `spec/spec.md` | §4.B10 | Regras: só session completa; 50 max; persistido em Storage. |
| `spec/spec.md` | §6 (regra 3) | "Sessão é gravada no histórico somente se completar todos os ciclos." |
| `source/repositories/CounterRepository.mc` | Inteiro | Pattern de repository com Storage usado como template. |
| `tests/CounterRepositoryTest.mc` | Inteiro | Pattern de teste com Storage cleanup. |

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (nenhuma nova necessária).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
