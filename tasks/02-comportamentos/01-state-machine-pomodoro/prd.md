# PRD — Task 02-01: State Machine Pomodoro

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar `PomodoroModel` — a state machine pura (sem dependências Toybox) que governa toda a lógica de domínio do timer Pomodoro. Cobre transições entre IDLE → RUNNING_WORK → RUNNING_SHORT_BREAK → ... → RUNNING_LONG_BREAK → COMPLETED, incluindo pause/resume/stop. Acompanha testes unitários completos.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que oferece |
|---|---|
| `source/model/Preset.mc` | Classe `Preset` com `workMin`, `breakMin`, `cycles`, `isCustom`. Já existe e tem construtor `Preset(workMin, breakMin, cycles, isCustom)`. |
| `source/model/Session.mc` | Classe `Session` para registro de sessão concluída — será usada em tasks posteriores (02-09), não nesta. |
| `monkey.jungle` | Atualmente mínimo (`base.sourcePath = source`). Precisará de configuração para testes. |

### 2.2 Assets disponíveis

Nenhum asset visual necessário — esta task é pure logic, sem UI.

### 2.3 Approach de implementação

**State machine baseada em símbolos (Symbols) com observer pattern via Method callbacks.**

- Estados representados como Symbols (`:idle`, `:running_work`, `:running_short_break`, `:running_long_break`, `:completed`).
- Eventos emitidos como Symbols para os observers.
- Model é 100% puro Monkey C — não importa nenhum módulo Toybox além de `Lang`.
- Observer pattern via array de `Method` callbacks (Connect IQ suporta `method(:name)` para function references).
- Testes via `(:test)` annotation e `Toybox.Test` module.

**Justificativa:** Symbols são a forma idiomática de enums no Monkey C. Observer pattern via Method references é suportado pelo runtime e mantém o Model desacoplado de View/Services.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `Toybox.Lang.Symbol` | Representar estados e eventos | Tipo nativo (`:symbol_name`) |
| `Toybox.Lang.Method` | Observer callbacks | `method(:methodName)` retorna `Method` |
| `Toybox.Lang.Array` | Array de observers | `new [0]` ou `[] as Array<Method>` |
| `Toybox.Test` | Framework de testes unitários | `(:test) function name(logger as Test.Logger) as Boolean` |
| `Toybox.Test.assertEqualMessage` | Asserção com mensagem | `Test.assertEqualMessage(expected, actual, message)` |

**Nota:** O PomodoroModel em si **não usa** APIs Toybox diretamente (exceto `Lang` para tipos básicos). Os testes usam `Toybox.Test`.

### 2.5 Cores/dimensões/strings necessárias

Nenhum. Task é pure logic.

---

## 3. Decisões a tomar

### 3.1 Duração do Long Break

**Contexto:** A spec define que long break ocorre após o último ciclo de work, mas não especifica a duração.

| Opção | Descrição | Prós | Contras |
|---|---|---|---|
| **A) 3× short break** | `longBreakMin = breakMin * 3` | Simples, derivado, previsível. Ex: 5min break → 15min long break. | Para breakMin=10 resultaria em 30min (pode ser longo). |
| B) Preset independente | Adicionar campo `longBreakMin` ao Preset | Mais flexível. | Requer alterar Preset.mc, UI do Custom Builder, Properties. Scope creep. |
| C) Hardcoded por preset | 25/5→15min, 30/5→15min, 50/10→20min | Convencional. | Não funciona para custom; lógica irregular. |

**Recomendação: Opção A (long break = 3× short break).**
- Simples e derivável.
- Não requer alterações em Preset.mc (calculado dinamicamente pelo Model).
- Para o preset padrão (breakMin=5), resulta em 15min — exatamente o Pomodoro clássico.
- Se no futuro quisermos customizar, basta adicionar campo ao Preset sem mudar a lógica do Model (usa `preset.longBreakMin` se existir, fallback para `breakMin * 3`).

### 3.2 Caso especial: preset com cycles == 1

**Contexto:** Se o preset tem apenas 1 ciclo, após a work-phase ele deveria ir para long break ou direto para completed?

| Opção | Descrição |
|---|---|
| **A) Sem long break se cycles == 1** | Após 1 work-phase → COMPLETED direto. Long break não faz sentido para 1 ciclo. |
| B) Sempre long break após último work | Mesmo com 1 ciclo, long break após o work. |

**Recomendação: Opção A (sem long break se cycles == 1).**
- A spec diz: "Long break **só** após o último ciclo de work (não a cada N)."
- Para 1 ciclo, o propósito do long break (descanso entre blocos de trabalho) não se aplica.
- Simplifica UX.

### 3.3 Comportamento de ações inválidas (ex: pause() em IDLE)

**Contexto:** Task diz "no-op + log" para combinações inválidas.

| Opção | Descrição |
|---|---|
| **A) Silently return (no-op)** | Ignora ação inválida sem efeitos. Debug log via `(:debug)` annotation. |
| B) Throw exception | Lança exception para sinalizar bug de programação. |

**Recomendação: Opção A (no-op com debug log).**
- Per architecture.md §4: "Não usar try/catch para mascarar bugs. Se transição inválida, logar e retornar."
- `(:debug)` annotation garante que logs não entram no release build.

### 3.4 Formato dos eventos emitidos para observers

**Contexto:** Task mostra observers recebendo `eventType as Symbol`. Mas spec §4.B4 mostra assinaturas mais ricas como `:onPhaseChange(oldPhase, newPhase)`.

| Opção | Descrição |
|---|---|
| **A) Symbol only** | `callback.invoke(:onTick)`. Observer consulta model getters para dados. |
| B) Symbol + Dictionary payload | `callback.invoke(:onTick, { "remaining" => 1499 })`. |
| **C) Symbol + primitives** | `callback.invoke(:onPhaseChange, oldState, newState)`. |

**Recomendação: Opção A (Symbol only).**
- Assinatura uniforme: `function onModelEvent(event as Symbol) as Void`.
- Observer acessa dados via getters (`model.getRemainingSeconds()`).
- Evita alocação de Dictionary em cada tick (memória — architecture.md §5.3).
- Simplifica o contrato do observer (não precisa variar assinatura por tipo de evento).

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | `(:test)` annotation pode não funcionar sem setup especial no `monkey.jungle` | Investigar na fase de plan: Connect IQ testes precisam de target de teste com flag `--unit-test`. Se `monkey.jungle` atual não suporta, adicionar `base.barrelPath` ou verificar CLI flags. |
| 2 | `Method` type como observer — limitações de GC (se Model guarda referência a um Method de uma View destroyed) | Exigir `removeObserver` no `onHide` da View. Documentar padrão no plan. |
| 3 | Bug no pseudocode da task: condição `_cyclesCompleted < _preset.cycles - 1` está incorreta | Para preset de 4 cycles: após 1ª work, cyclesCompleted=1. Condição `1 < 3` → short break. Após 2ª, `2 < 3` → short break. Após 3ª, `3 < 3` → false. Cai no `== cycles-1` → `3 == 3` → long break. Após long break → completed. Mas faltou o 4º work! **Correção:** usar `_cyclesCompleted < _preset.cycles` para ir a short break, e `_cyclesCompleted == _preset.cycles` para completed ou long break. Ver seção 6 para fluxo correto. |
| 4 | Testes unitários em Connect IQ podem não suportar `assert` com Symbols diretamente | Se `assertEqualMessage` não compara symbols, usar workaround com `.toString()` ou comparação manual. Validar na implementação. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/model/PomodoroState.mc` | Criar | Module com constantes Symbol para estados + helper de validação |
| `source/model/PomodoroEvent.mc` | Criar | Module com constantes Symbol para eventos |
| `source/model/PomodoroModel.mc` | Criar | Classe principal: state machine, tick, pause/resume/stop, observer pattern |
| `tests/PomodoroModelTest.mc` | Criar | Testes unitários cobrindo todas as transições e edge cases |
| `monkey.jungle` | Modificar | Adicionar configuração para unit tests (se necessário) |

---

## 6. Arquitetura do fluxo

### 6.1 State machine — fluxo corrigido

```
          start(preset)
               │
               ▼
     ┌────── IDLE
     │
     │  state = :running_work
     │  remaining = preset.workMin * 60
     │  currentCycle = 1
     │  cyclesCompleted = 0
     │  emit(:onStart), emit(:onPhaseChange)
     ▼
┌─► RUNNING_WORK ◄──────────────────────┐
│        │                                │
│        │ tick(): remaining -= 1         │
│        │                                │
│        │ remaining == 0                 │
│        │ cyclesCompleted += 1           │
│        │ emit(:onWorkPhaseComplete)     │
│        ▼                                │
│   ┌─────────────────────────────┐       │
│   │ cyclesCompleted < cycles    │───┐   │
│   │ AND cycles > 1              │   │   │
│   └─────────────────────────────┘   │   │
│        │ NO                          │   │
│        ▼                            │   │
│   ┌─────────────────────────────┐   │   │
│   │ cyclesCompleted == cycles   │   │   │
│   └─────────────────────────────┘   │   │
│        │ YES                        │   │
│        ▼                            │   │
│   cycles == 1?                      │   │
│     YES → COMPLETED                 │   │
│     NO  → RUNNING_LONG_BREAK        │   │
│             remaining = breakMin*3*60│   │
│             emit(:onPhaseChange)    │   │
│             │                       │   │
│             │ remaining == 0        │   │
│             ▼                       │   │
│           COMPLETED                 │   │
│             emit(:onComplete)       │   │
│                                     │   │
│                                     ▼   │
│                          RUNNING_SHORT_BREAK
│                            remaining = breakMin*60
│                            emit(:onPhaseChange)
│                                     │
│                                     │ remaining == 0
│                                     │
└─────────────────────────────────────┘
     state = :running_work
     remaining = workMin * 60
     currentCycle += 1
     emit(:onPhaseChange)
```

### 6.2 Transição lógica corrigida (pseudocode)

```monkeyc
function _transitionPhase() as Void {
    if (_state == :running_work) {
        _cyclesCompleted += 1;
        _emit(:onWorkPhaseComplete);

        if (_cyclesCompleted >= _preset.cycles) {
            // Todos os work-phases concluídos
            if (_preset.cycles == 1) {
                // Sem long break para 1 ciclo
                _state = :completed;
                _emit(:onPhaseChange);
                _emit(:onComplete);
            } else {
                // Long break após último work
                _state = :running_long_break;
                _remainingSeconds = _preset.breakMin * 3 * 60;
                _emit(:onPhaseChange);
            }
        } else {
            // Mais work-phases a fazer; short break
            _state = :running_short_break;
            _remainingSeconds = _preset.breakMin * 60;
            _emit(:onPhaseChange);
        }
    } else if (_state == :running_short_break) {
        _currentCycle += 1;
        _state = :running_work;
        _remainingSeconds = _preset.workMin * 60;
        _emit(:onPhaseChange);
    } else if (_state == :running_long_break) {
        _state = :completed;
        _emit(:onPhaseChange);
        _emit(:onComplete);
    }
}
```

### 6.3 Sequência completa para preset 25/5/4

```
IDLE
  → start(25/5/4)
  → RUNNING_WORK (25min, cycle=1, completed=0)
  → tick×1500 → remaining=0 → completed=1
  → RUNNING_SHORT_BREAK (5min)
  → tick×300 → remaining=0 → cycle=2
  → RUNNING_WORK (25min, cycle=2, completed=1)
  → tick×1500 → remaining=0 → completed=2
  → RUNNING_SHORT_BREAK (5min)
  → tick×300 → remaining=0 → cycle=3
  → RUNNING_WORK (25min, cycle=3, completed=2)
  → tick×1500 → remaining=0 → completed=3
  → RUNNING_SHORT_BREAK (5min)
  → tick×300 → remaining=0 → cycle=4
  → RUNNING_WORK (25min, cycle=4, completed=3)
  → tick×1500 → remaining=0 → completed=4 (== cycles)
  → RUNNING_LONG_BREAK (15min)
  → tick×900 → remaining=0
  → COMPLETED
```

### 6.4 Observer interaction

```
TimerView                    PomodoroModel              TimerService
   │                              │                         │
   │  onShow()                    │                         │
   │──addObserver(method(:onModelEvent))──►│               │
   │                              │                         │
   │                              │◄── tick() ──────────────│ (1Hz)
   │                              │   remaining -= 1        │
   │                              │   emit(:onTick)         │
   │◄── callback(:onTick) ────────│                         │
   │  requestUpdate()             │                         │
   │                              │                         │
   │  onHide()                    │                         │
   │──removeObserver(method(...))─►│                        │
```

---

## 7. Referências para o plan.md

O plan.md deve ler:
1. Este PRD completo.
2. `source/model/Preset.mc` — para alinhar construtores e tipos.
3. `references/architecture.md` §3 (Model) e §4 (naming/tipos) — para seguir padrões.
4. `spec/spec.md` §4.B4 e §6 — regras de negócio.

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (N/A — pure logic).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
