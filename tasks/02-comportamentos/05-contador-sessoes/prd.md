# PRD — Task 02-05: Contador de Sessões (diário)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar o contador de sessões diário (B9): um repositório que persiste em `Application.Storage` a quantidade de work-phases completadas no dia corrente, com reset automático ao detectar mudança de data. O valor alimenta `CycleCompleteView` (P6) e `HistoryView` (P7).

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que serve |
|---|---|
| `source/model/PomodoroModel.mc:140` | Já emite `PomodoroEvent.ON_WORK_PHASE_COMPLETE` dentro de `_transitionPhase()` após `_cyclesCompleted += 1` |
| `source/model/PomodoroEvent.mc` | Enum `ON_WORK_PHASE_COMPLETE` já existe (linha 4) |
| `source/TomaApp.mc:60-88` | `onModelEvent` já escuta todos eventos do Model — ponto de integração |
| `source/utils/DateUtils.mc` | Módulo existente com `formatDate`, `getLocale`; falta `today()` e `isSameDay()` |
| `source/views/CycleCompleteView.mc` | Já recebe `todaySessions` no construtor (hardcoded 0 na chamada em TomaApp.mc:83) |
| `source/views/HistoryView.mc` | Usa mock data; header com contador ainda não implementado |
| `source/ui/layout/Dimensions.mc:109-113` | `cycleTodayY()` já existe para posicionar texto "Today" em P6 |

### 2.2 Assets disponíveis

| Asset | Status |
|---|---|
| String `today_sessions` ("Today: $1$ sessions") | Já existe em `strings.xml` |
| Cores `TEXT_MUTED`, `TEXT_PRIMARY` | Já em `Colors.mc` |
| Fonts do sistema (`FONT_TINY`) | Disponíveis via Gfx |

**Faltam:**
- String `today_sessions_singular` ("Today: 1 session") — decidir se implementar ou usar apenas plural.

### 2.3 Approach de implementação

**Decisão: CounterRepository como classe singleton instanciada no TomaApp.**

Justificativa:
1. Segue o padrão Repository definido em `architecture.md §3` — única camada que toca Storage.
2. O diretório `source/repositories/` ainda não existe, mas é canônico (architecture.md o prevê).
3. O Model não deve tocar Storage diretamente — o handler em TomaApp é o ponto correto para chamar `CounterRepository.increment()`.
4. O reset diário é lazy (detectado em `_load()` ao comparar datas) — simples e sem overhead.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Referência |
|---|---|---|
| `Toybox.Application.Storage.getValue(key)` | Ler `dailyCounter` | garmin_platform.md §2.4 |
| `Toybox.Application.Storage.setValue(key, value)` | Persistir `dailyCounter` | garmin_platform.md §2.4 |
| `Toybox.Time.Gregorian.info(moment, format)` | Obter data local (year/month/day) | SDK API Docs |
| `Toybox.Time.now()` | Momento atual para criar info | SDK API Docs |
| `Toybox.Lang.format(pattern, args)` | Formatar string de data YYYY-MM-DD | SDK API Docs |

**Assinaturas confirmadas:**
- `Storage.getValue(key as String) as Object?` — retorna `null` se key não existe
- `Storage.setValue(key as String, value as Object?) as Void` — aceita Dictionary
- `Gregorian.info(moment as Moment, format as Number) as Gregorian.Info` — `.year`, `.month`, `.day` como Number
- `Lang.format(pattern as String, args as Array) as String`

### 2.5 Cores/dimensões/strings necessárias

**Strings:**

| Key | EN | PT (futura) |
|---|---|---|
| `today_sessions` (existente) | `Today: $1$ sessions` | `Hoje: $1$ sessões` |
| `today_session_singular` (novo) | `Today: 1 session` | `Hoje: 1 sessão` |

**Decisão:** usar apenas `today_sessions` com `$1$` substituição (ex: "Today: 1 sessions" em EN). A pluralização perfeita ("1 session" vs "2 sessions") é nice-to-have mas Connect IQ não tem ICU plural rules — implementar manualmente com if/else simples.

**Cores:** Nenhuma nova necessária. Usa `Colors.TEXT_MUTED` para o texto "Today:".

**Dimensões:** `cycleTodayY()` já existe em Dimensions.mc.

---

## 3. Decisões a tomar

### D1. Pluralização da string "Today: N sessions"

| Opção | Prós | Contras |
|---|---|---|
| A) Duas strings (`singular` + `plural`) com if/else | Correto gramaticalmente | Mais código, mais strings |
| B) Sempre plural ("Today: 1 sessions") | Simples | Gramaticalmente incorreto para count=1 |
| C) Format sem "sessions" ("Today: 1") | Ultra simples | Perde contexto semântico |

**Recomendação: A) Duas strings.** A verificação é um if simples, e o resultado fica profissional. Connect IQ apps concorrentes fazem isso.

### D2. Onde colocar a lógica de plural?

| Opção | Prós | Contras |
|---|---|---|
| A) Na View (CycleCompleteView) | Lógica de apresentação fica na View | Duplicação se HistoryView também usar |
| B) No CounterRepository como método helper | Centraliza | Repository não deveria formatar strings (architecture) |
| C) Método em DateUtils ou novo StringUtils | Boa separação | Mais um arquivo |

**Recomendação: A) Na View.** Cada View decide como formatar, e a lógica é um if trivial (não justifica abstração).

### D3. Header no HistoryView

| Opção | Prós | Contras |
|---|---|---|
| A) Substituir título "HISTORY" por "HISTORY · Today: N" | Informativo, sem espaço extra | Título fica longo em telas pequenas |
| B) Adicionar linha separada abaixo do título | Mais espaço visual | Empurra lista para baixo |
| C) Não mostrar em History (só P6) | Simples | Spec diz "opcionalmente" — pode omitir |

**Recomendação: C) Omitir do HistoryView por enquanto.** A spec diz "opcionalmente como header" — P6 é o ponto principal. Simplifica a task. Se houver demanda futura, adicionar.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | `Storage.getValue` retorna Dictionary com tipos diferentes do esperado (corrupção) | `_load()` valida tipo com `instanceof`; se inválido, retorna struct fresh (count=0) |
| 2 | Gregorian.info `.month` e `.day` retornam Number sem zero-pad — string "2026-5-8" não matcha "2026-05-08" | Usar `Lang.format` com `%02d` — verificar: MC não suporta `%02d` em `format()`. Alternativa: `info.month.format("%02d")` (Integer.format existe em MC) |
| 3 | Reset diário não persiste imediatamente — se app é killada entre detecção de data nova e próximo `increment()`, o antigo `count` de ontem ainda está no Storage | Aceitar: é edge case mínimo. O próximo increment() fará reset+persist |
| 4 | Testes unitários precisam mockar `Time.now()` e `Storage` | Injetar dependência de "clock" no CounterRepository, ou aceitar que testes usam `Storage` real do simulador |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/repositories/CounterRepository.mc` | **Criar** | Leitura/escrita do `dailyCounter` em Storage. Métodos: `getTodayCount()`, `increment()` |
| `source/utils/DateUtils.mc` | **Modificar** | Adicionar `today() as String` e `isSameDay(a, b) as Boolean` |
| `source/TomaApp.mc` | **Modificar** | Instanciar `CounterRepository`; no handler `ON_WORK_PHASE_COMPLETE`, chamar `increment()` |
| `source/views/CycleCompleteView.mc` | **Modificar** | Substituir hardcoded `0` por valor real de `CounterRepository.getTodayCount()`; implementar pluralização |
| `resources/strings/strings.xml` | **Modificar** | Adicionar `today_session_singular` |
| `tests/CounterRepositoryTest.mc` | **Criar** | Testar increment, reset diário, persistência |
| `tests/DateUtilsTest.mc` | **Criar** | Testar `today()`, `isSameDay()` |

---

## 6. Arquitetura do fluxo

```
┌───────────────────┐         ┌─────────────────────┐
│   PomodoroModel   │         │    TomaApp          │
│                   │         │                     │
│ _transitionPhase()│         │ onModelEvent()      │
│   ↓               │  emit   │   ↓                 │
│ ON_WORK_PHASE_    │────────▶│ if WORK_PHASE_      │
│   COMPLETE        │         │   COMPLETE:         │
│                   │         │   _counterRepo      │
└───────────────────┘         │     .increment()    │
                              └─────────┬───────────┘
                                        │
                              ┌─────────▼───────────┐
                              │ CounterRepository    │
                              │                     │
                              │ increment():        │
                              │   data = _load()    │
                              │   data["count"]++   │
                              │   Storage.setValue() │
                              │                     │
                              │ _load():            │
                              │   stored = Storage  │
                              │     .getValue()     │
                              │   today = DateUtils │
                              │     .today()        │
                              │   if date != today: │
                              │     return fresh    │
                              │   return stored     │
                              └─────────────────────┘

┌───────────────────┐         ┌─────────────────────┐
│ CycleCompleteView │         │ CounterRepository    │
│                   │  read   │                     │
│ onUpdate():       │────────▶│ getTodayCount()     │
│   show "Today: N" │         │   → _load()["count"]│
└───────────────────┘         └─────────────────────┘
```

**Storage schema:**
```json
Key: "dailyCounter"
Value: { "date": "2026-05-08", "count": 5 }
```

---

## 7. Referências para o plan.md

| Referência | Seção | Motivo |
|---|---|---|
| `references/architecture.md` | §3 (Separação de responsabilidades — Repositories) | Padrão a seguir |
| `references/garmin_platform.md` | §2.4 (Storage) | API de persistência |
| `spec/spec.md` | §4.B9, §6 regra 4 e 5 | Regras de negócio exatas |
| `source/model/PomodoroModel.mc` | Linhas 135-170 | Onde ON_WORK_PHASE_COMPLETE é emitido |
| `source/TomaApp.mc` | Linhas 60-88 | Handler de eventos a estender |
| `source/views/CycleCompleteView.mc` | Inteiro | View a modificar |
| `source/utils/DateUtils.mc` | Inteiro | Módulo a estender |

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
