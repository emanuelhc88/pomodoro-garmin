# PRD — Task 02-10: FIT Activity Recording

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar **B11** — ao iniciar uma sessão Pomodoro (se `recordAsActivity == true`), criar uma FIT Activity via `Toybox.ActivityRecording.createSession` com nome "Focus" e sport genérico. A activity é salva no `onComplete` (sessão completa) ou descartada no `onStop` (sessão abortada). Isto é o diferencial competitivo principal do Toma — nenhum outro app Pomodoro no ecossistema Garmin grava sessões como activity FIT visível no Garmin Connect.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que serve |
|---------|-------------|
| [source/repositories/SettingsRepository.mc](source/repositories/SettingsRepository.mc) | Já tem `getRecordAsActivity()` (linha 32-34) e `setRecordAsActivity()` (linha 37-38). Pronto para uso. |
| [source/TomaApp.mc](source/TomaApp.mc) | Já tem `onModelEvent()` com handling de `ON_START`, `ON_COMPLETE`, `ON_STOP`. Precisa adicionar chamadas ao ActivityService. |
| [source/model/PomodoroEvent.mc](source/model/PomodoroEvent.mc) | Eventos `ON_START`, `ON_STOP`, `ON_COMPLETE` já existem. Suficientes para o wiring. |
| [source/services/AttentionService.mc](source/services/AttentionService.mc) | Padrão de Service com capability detection e DI de `SettingsRepository`. Serve de template para `ActivityService`. |
| [source/views/SettingsMenu.mc](source/views/SettingsMenu.mc) | Toggle "Record as activity" (linha 33-39) já existe e já persiste via `SettingsMenuDelegate`. |
| [resources/settings/properties.xml](resources/settings/properties.xml) | `recordAsActivity` já declarado com default `true`. |

### 2.2 Assets disponíveis

Nenhum asset novo necessário. Esta task é puramente lógica (sem UI).

### 2.3 Approach de implementação

**Decisão:** Criar `ActivityService` como wrapper fino sobre `Toybox.ActivityRecording`, seguindo exatamente o padrão de `AttentionService`:
- Recebe `SettingsRepository` no construtor.
- Faz capability detection via `Toybox has :ActivityRecording`.
- Expõe `start()`, `stop()`, `discard()`.
- Não expõe `pause()`/`resume()` — a ActivityRecording Session continua rodando durante pause do Pomodoro (decisão V1, Opção A da task).

**Justificativa para Opção A (não pausar a activity):**
- `ActivityRecording.Session` não tem método `pause()`/`resume()` direto. Seria preciso `stop()`+`save()` e criar nova session, perdendo continuidade.
- Tempo pausado contando na activity é aceitável — o usuário ainda está em "contexto focus".
- Simplifica enormemente a implementação.
- A task file já recomenda Opção A.

**Nota sobre conflito com spec §B5:** A spec menciona "ActivityService.pause() (se ativo)" em B5, mas a task file override isto com decisão explícita de Opção A. Seguir a task file, que é mais recente e específica.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura confirmada |
|-----|-----|----------------------|
| `Toybox.ActivityRecording.createSession(options as Dictionary)` | Criar session FIT | Params: `{:name => String, :sport => Number, :subSport => Number}`. Retorna `Session`. API Level 1.0.0. |
| `ActivityRecording.Session.start()` | Iniciar gravação | `function start() as Void` |
| `ActivityRecording.Session.stop()` | Parar gravação | `function stop() as Void` |
| `ActivityRecording.Session.save()` | Persistir no FIT | `function save() as Void` |
| `ActivityRecording.Session.discard()` | Descartar sem salvar | `function discard() as Void` |
| `ActivityRecording.Session.isRecording()` | Checar estado | `function isRecording() as Boolean` |
| `ActivityRecording.SPORT_GENERIC` | Sport type | Constante numérica |
| `ActivityRecording.SUB_SPORT_GENERIC` | Sub-sport type | Constante numérica |

**Confirmação:** Não existe `SPORT_FOCUS` nem `SUB_SPORT_FOCUS` no SDK. Usar `SPORT_GENERIC` + `SUB_SPORT_GENERIC` com `:name => "Focus"`.

### 2.5 Cores/dimensões/strings necessárias

Nenhuma. Task é backend-only (serviço). A UI do toggle "Record as activity" já existe em SettingsMenu.

---

## 3. Decisões a tomar

### D1. Pause da activity durante pause Pomodoro

| Opção | Descrição | Prós | Contras |
|-------|-----------|------|---------|
| **A (Recomendada)** | Manter activity rodando durante pause | Simples, sem perda de dados HR, implementação trivial | Tempo pausado conta na duração |
| B | Stop+save e criar nova session | Duração precisa | Perde continuidade, complexo, múltiplas activities por sessão |
| C | Usar stop sem save (discard parcial) | N/A | Perde tudo, sem sentido |

**Decisão: Opção A.** Já validada na task file e na análise da API (Session não tem pause nativo).

### D2. Permission FitContributor no manifest

| Opção | Descrição |
|-------|-----------|
| **Não adicionar (Recomendada)** | V1 não usa custom fields. Permission não necessária para activity básica. |
| Adicionar | Preparar para V1.1 com custom fields |

**Decisão: Não adicionar.** Menos permissões = menos fricção na Store review. Adicionar quando necessário.

### D3. Wiring no recovery path

| Opção | Descrição |
|-------|-----------|
| **Iniciar activity no resume from recovery (Recomendada)** | Quando o app recupera uma sessão, iniciar nova activity para o tempo restante |
| Não iniciar | Sessão recuperada não gera activity |

**Decisão: Iniciar no recovery.** O evento `ON_START` já é emitido por `hydrate()`, então o wiring em `onModelEvent` naturalmente captura esse caso. Activity terá duração parcial mas é melhor que nada.

### D4. Tratamento de erro em createSession

| Opção | Descrição |
|-------|-----------|
| **Try/catch + log + continuar (Recomendada)** | Nunca quebrar o Pomodoro por falha de ActivityRecording |
| Propagar exceção | Pomodoro para se activity falhar |

**Decisão: Try/catch.** Activity é feature secundária ao timer. Falha silenciosa (com log) é aceitável.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|-------|-----------|
| 1 | Device já tem activity em andamento (ex: corrida) → `createSession` falha | Try/catch captura. Log de debug. Sessão Pomodoro funciona normalmente sem activity. |
| 2 | Devices low-end sem `ActivityRecording` | Capability detection: `Toybox has :ActivityRecording && ActivityRecording has :createSession`. Já no padrão do projeto. |
| 3 | FIT no simulador salva em path local, não no Garmin Connect | Validação manual: checar `~/Library/Application Support/Garmin/ConnectIQ/Activities/`. Teste em device real para Garmin Connect sync. |
| 4 | Nome "Focus" pode ser truncado em alguns devices (max ~15 chars) | "Focus" tem 5 chars. Safe. |
| 5 | ActivityRecording pode afetar battery life (HR sensor fica ativo) | HR é coletado de qualquer forma em wrist-based devices. Impacto negligível. Documentar para usuário que pode desligar via toggle. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `source/services/ActivityService.mc` | **Criar** | Wrapper sobre `Toybox.ActivityRecording`. Métodos: `start()`, `stop()`, `discard()`. Capability detection + try/catch. |
| `source/TomaApp.mc` | **Modificar** | Instanciar `ActivityService`; chamar `start()` em `ON_START`, `stop()` em `ON_COMPLETE`, `discard()` em `ON_STOP`. |
| `tests/ActivityServiceTest.mc` | **Criar** | Smoke tests: branch logic (enabled/disabled, session nula, double-start guard). Não testa Toybox real. |

---

## 6. Arquitetura do fluxo

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TomaApp.onModelEvent()                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ON_START ──────────► ActivityService.start()                        │
│                           │                                          │
│                           ├── _isEnabled()? ── false → return        │
│                           ├── _session != null? → return (guard)     │
│                           ├── Toybox has :ActivityRecording? ── no → │
│                           │                                  return  │
│                           └── createSession({:name=>"Focus",         │
│                                  :sport=>SPORT_GENERIC,              │
│                                  :subSport=>SUB_SPORT_GENERIC})      │
│                               session.start()                        │
│                                                                      │
│  ON_COMPLETE ───────► ActivityService.stop()                         │
│                           │                                          │
│                           ├── _session == null? → return             │
│                           └── session.stop()                         │
│                               session.save()                         │
│                               _session = null                        │
│                                                                      │
│  ON_STOP ───────────► ActivityService.discard()                      │
│                           │                                          │
│                           ├── _session == null? → return             │
│                           └── session.stop()                         │
│                               session.discard()                      │
│                               _session = null                        │
│                                                                      │
│  ON_PAUSE / ON_RESUME → (nenhuma ação no ActivityService)            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Lifecycle durante sessão Pomodoro:**
```
User taps Start
    → Model.start() → emits ON_START
    → TomaApp.onModelEvent(ON_START)
    → ActivityService.start()  ← activity FIT começa

Timer ticks... (activity recording HR, calories, duration)

User pauses/resumes
    → Model.pause()/resume()
    → Activity NÃO é afetada (continua gravando)

Timer reaches 0, all cycles done
    → Model._transitionPhase() → emits ON_COMPLETE
    → TomaApp.onModelEvent(ON_COMPLETE)
    → ActivityService.stop()  ← activity salva, vai para Garmin Connect

OR user stops early
    → Model.stop() → emits ON_STOP
    → TomaApp.onModelEvent(ON_STOP)
    → ActivityService.discard()  ← activity descartada, nada no Connect
```

---

## 7. Referências para o plan.md

| Ref | Seção |
|-----|-------|
| `references/garmin_platform.md` | §2.7 (ActivityRecording), §3 (capability detection), §8 (permissions) |
| `references/architecture.md` | §3 (separação de responsabilidades — Services), §4 (regras de codificação) |
| `spec/spec.md` | §4.B11 (linhas 402-423) |
| `source/services/AttentionService.mc` | Template para o padrão de Service |
| `source/TomaApp.mc` | `onModelEvent()` — onde wiring será adicionado |
| `tests/AttentionServiceTest.mc` | Padrão de testes para Services |

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (N/A — task sem UI).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
