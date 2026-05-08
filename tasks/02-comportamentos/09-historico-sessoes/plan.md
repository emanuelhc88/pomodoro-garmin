# Plan — Task 02-09: Histórico de Sessões (persistência)

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar **B10** — criar `HistoryRepository` que persiste as últimas 50 sessões completas em `Application.Storage`, adicionar `toDict()`/`fromDict()` ao `Session`, conectar ao evento `ON_COMPLETE` no `TomaApp` para append automático, e substituir o mock do `HistoryView` por dados reais.

---

## 2. Cenários

### Caminho feliz
1. Usuário completa todos os ciclos de um preset.
2. `PomodoroModel` emite `ON_COMPLETE`.
3. `TomaApp.onModelEvent` constrói um `Session` a partir do preset atual e `Time.now()`.
4. `HistoryRepository.append(session)` serializa via `toDict()`, carrega lista do Storage, adiciona, faz trim se > 50, salva.
5. Usuário navega para History — `HistoryView` carrega via `HistoryRepository.loadAll()`, inverte (mais recente primeiro), renderiza.

### Edge cases
- **Storage vazio (primeira sessão):** `loadAll()` retorna `[]`; append cria array com 1 item.
- **Exatamente 50 sessões:** append chega a 51 → trim remove a mais antiga (índice 0) com `slice(1, null)`.
- **Sessão pausada e retomada:** ainda gera `ON_COMPLETE` ao final — conta normalmente.
- **HistoryView com 0 sessões:** EmptyState já tratado na view existente.

### Erros
- **Storage corrompido (não é Array):** `loadAll()` retorna `[]` (ignora dados inválidos).
- **Dict com campos faltantes:** `fromDict()` trata com defaults seguros para não crashar.
- **Preset null no ON_COMPLETE:** impossível — `_transitionPhase()` emite ON_COMPLETE antes de stop(), e stop() é o único que nulifica `_preset`. Guard check adicionado por segurança.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/repositories/HistoryRepository.mc` | CRUD de sessions em Storage: `loadAll()`, `append(session)`. Limite de 50 entries. |
| 2 | `tests/HistoryRepositoryTest.mc` | Testes: lista vazia, append, trim > 50, persistência, dados corrompidos. |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/model/Session.mc` | Adicionar `toDict()` e `fromDict(d)` para serialização. |
| 2 | `source/TomaApp.mc` | Instanciar `HistoryRepository`, expor getter, append no ON_COMPLETE. |
| 3 | `source/views/HistoryView.mc` | Substituir `getMockSessions()` por `HistoryRepository.loadAll()` com reverse. |

---

### 4.1 `source/model/Session.mc`

**Antes:**
```monkeyc
    function formatPreset() as Lang.String {
        return Lang.format("$1$/$2$ · $3$", [workMin, breakMin, cycles]);
    }
}
```

**Depois:**
```monkeyc
    function formatPreset() as Lang.String {
        return Lang.format("$1$/$2$ · $3$", [workMin, breakMin, cycles]);
    }

    function toDict() as Lang.Dictionary {
        return {
            "completedAt" => completedAt,
            "preset" => preset,
            "workMin" => workMin,
            "breakMin" => breakMin,
            "cycles" => cycles,
            "totalDuration" => totalDuration
        };
    }

    static function fromDict(d as Lang.Dictionary) as Session {
        return new Session(
            (d.hasKey("completedAt") ? d["completedAt"] : 0) as Lang.Number,
            (d.hasKey("preset") ? d["preset"] : "") as Lang.String,
            (d.hasKey("workMin") ? d["workMin"] : 25) as Lang.Number,
            (d.hasKey("breakMin") ? d["breakMin"] : 5) as Lang.Number,
            (d.hasKey("cycles") ? d["cycles"] : 4) as Lang.Number,
            (d.hasKey("totalDuration") ? d["totalDuration"] : 0) as Lang.Number
        );
    }
}
```

---

### 4.2 `source/TomaApp.mc`

**Antes (campos privados, linha 9-10):**
```monkeyc
    private var _counterRepo as CounterRepository;
    private var _settingsRepo as SettingsRepository;
```

**Depois:**
```monkeyc
    private var _counterRepo as CounterRepository;
    private var _historyRepo as HistoryRepository;
    private var _settingsRepo as SettingsRepository;
```

---

**Antes (initialize, linha 24):**
```monkeyc
        _counterRepo = new CounterRepository();
        _model.addObserver(method(:onModelEvent));
```

**Depois:**
```monkeyc
        _counterRepo = new CounterRepository();
        _historyRepo = new HistoryRepository();
        _model.addObserver(method(:onModelEvent));
```

---

**Antes (onModelEvent ON_COMPLETE, linhas 99-108):**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            _recoveryService.clear();
            var todaySessions = _counterRepo.getTodayCount();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), todaySessions);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
```

**Depois:**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _appendSessionToHistory();
            _timerService.stop();
            _recoveryService.clear();
            var todaySessions = _counterRepo.getTodayCount();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), todaySessions);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
```

---

**Antes (final do arquivo, antes do último `}`):**
```monkeyc
    function resumeFromRecovery(recovery as RecoveryState) as Void {
        _skipNextPhaseChange = true;
        _model.hydrate(recovery.preset, recovery.state, recovery.remainingSeconds, recovery.cyclesCompleted, recovery.currentCycle);
        _timerService.start(method(:onTimerTick), 1000);
    }
}
```

**Depois:**
```monkeyc
    function resumeFromRecovery(recovery as RecoveryState) as Void {
        _skipNextPhaseChange = true;
        _model.hydrate(recovery.preset, recovery.state, recovery.remainingSeconds, recovery.cyclesCompleted, recovery.currentCycle);
        _timerService.start(method(:onTimerTick), 1000);
    }

    function getHistoryRepo() as HistoryRepository {
        return _historyRepo;
    }

    private function _appendSessionToHistory() as Void {
        var preset = _model.getPreset();
        if (preset == null) {
            return;
        }
        var p = preset as Preset;
        var presetLabel = p.isCustom ? "Custom" : Lang.format("$1$/$2$/$3$", [p.workMin, p.breakMin, p.cycles]);
        var totalDuration = (p.workMin + p.breakMin) * p.cycles * 60;
        var session = new Session(
            Time.now().value(),
            presetLabel,
            p.workMin,
            p.breakMin,
            p.cycles,
            totalDuration
        );
        _historyRepo.append(session);
    }
}
```

---

### 4.3 `source/views/HistoryView.mc`

**Antes (imports e initialize):**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class HistoryView extends Ui.View {
    private var _sessions as Lang.Array<Session>;
    private var _scrollOffset as Lang.Number;
    private var _focusIdx as Lang.Number;
    private var _visibleCount as Lang.Number;
    private var _titleText as Lang.String;
    private var _emptyText as Lang.String;

    function initialize() {
        View.initialize();
        _sessions = getMockSessions();
        _scrollOffset = 0;
        _focusIdx = 0;
        _visibleCount = 3;
        _titleText = Ui.loadResource(Rez.Strings.history_title) as Lang.String;
        _emptyText = Ui.loadResource(Rez.Strings.history_empty) as Lang.String;
    }
```

**Depois:**
```monkeyc
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Lang;

class HistoryView extends Ui.View {
    private var _sessions as Lang.Array<Session>;
    private var _scrollOffset as Lang.Number;
    private var _focusIdx as Lang.Number;
    private var _visibleCount as Lang.Number;
    private var _titleText as Lang.String;
    private var _emptyText as Lang.String;

    function initialize() {
        View.initialize();
        _sessions = _loadSessions();
        _scrollOffset = 0;
        _focusIdx = 0;
        _visibleCount = 3;
        _titleText = Ui.loadResource(Rez.Strings.history_title) as Lang.String;
        _emptyText = Ui.loadResource(Rez.Strings.history_empty) as Lang.String;
    }
```

---

**Antes (getMockSessions, fim do arquivo):**
```monkeyc
    private function getMockSessions() as Lang.Array<Session> {
        var now = Time.now().value();
        var day = 86400;
        return [
            new Session(now - day * 0, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 1, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 1, "50/10/4", 50, 10, 4, 14400),
            new Session(now - day * 2, "30/5/4", 30, 5, 4, 8400),
            new Session(now - day * 3, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 4, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 5, "50/10/4", 50, 10, 4, 14400),
            new Session(now - day * 6, "30/5/4", 30, 5, 4, 8400),
            new Session(now - day * 7, "25/5/4", 25, 5, 4, 7200),
            new Session(now - day * 8, "25/5/4", 25, 5, 4, 7200)
        ];
    }
}
```

**Depois:**
```monkeyc
    private function _loadSessions() as Lang.Array<Session> {
        var app = App.getApp() as TomaApp;
        var all = app.getHistoryRepo().loadAll();
        var reversed = new [all.size()] as Lang.Array<Session>;
        for (var i = 0; i < all.size(); i++) {
            reversed[i] = all[all.size() - 1 - i] as Session;
        }
        return reversed;
    }
}
```

---

## 5. Storage/Properties

| Key | Tipo | Default | Onde lido | Onde escrito |
|---|---|---|---|---|
| `"sessionHistory"` | `Array<Dictionary>` | `null` (tratado como `[]`) | `HistoryRepository.loadAll()` | `HistoryRepository.append()` |

---

## 6. Arquivo novo: `source/repositories/HistoryRepository.mc`

```monkeyc
using Toybox.Application as App;
using Toybox.Lang;

class HistoryRepository {
    private const STORAGE_KEY = "sessionHistory";
    private const MAX_ENTRIES = 50;

    function loadAll() as Lang.Array<Session> {
        var stored = App.Storage.getValue(STORAGE_KEY);
        if (!(stored instanceof Lang.Array)) {
            return [] as Lang.Array<Session>;
        }
        var list = stored as Lang.Array;
        var sessions = [] as Lang.Array<Session>;
        for (var i = 0; i < list.size(); i++) {
            var item = list[i];
            if (item instanceof Lang.Dictionary) {
                sessions.add(Session.fromDict(item as Lang.Dictionary));
            }
        }
        return sessions;
    }

    function append(session as Session) as Void {
        var stored = App.Storage.getValue(STORAGE_KEY);
        var list;
        if (stored instanceof Lang.Array) {
            list = stored as Lang.Array<Lang.Dictionary>;
        } else {
            list = [] as Lang.Array<Lang.Dictionary>;
        }
        list.add(session.toDict());
        if (list.size() > MAX_ENTRIES) {
            list = list.slice(1, null) as Lang.Array<Lang.Dictionary>;
        }
        App.Storage.setValue(STORAGE_KEY, list);
    }
}
```

---

## 7. Arquivo novo: `tests/HistoryRepositoryTest.mc`

```monkeyc
using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testHistoryLoadAllEmpty(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    var sessions = repo.loadAll();
    Test.assertEqualMessage(0, sessions.size(), "Empty storage should return empty array");
    return true;
}

(:test)
function testHistoryAppendOne(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    var session = new Session(1000000, "25/5/4", 25, 5, 4, 7200);
    repo.append(session);
    var sessions = repo.loadAll();
    Test.assertEqualMessage(1, sessions.size(), "After 1 append, should have 1 session");
    Test.assertEqualMessage(1000000, (sessions[0] as Session).completedAt, "completedAt should match");
    Test.assertEqualMessage("25/5/4", (sessions[0] as Session).preset, "preset should match");
    return true;
}

(:test)
function testHistoryAppendMultiple(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    repo.append(new Session(1000, "25/5/4", 25, 5, 4, 7200));
    repo.append(new Session(2000, "50/10/4", 50, 10, 4, 14400));
    repo.append(new Session(3000, "30/5/4", 30, 5, 4, 8400));
    var sessions = repo.loadAll();
    Test.assertEqualMessage(3, sessions.size(), "Should have 3 sessions");
    Test.assertEqualMessage(1000, (sessions[0] as Session).completedAt, "First should be oldest");
    Test.assertEqualMessage(3000, (sessions[2] as Session).completedAt, "Last should be newest");
    return true;
}

(:test)
function testHistoryTrimAt50(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo = new HistoryRepository();
    for (var i = 0; i < 52; i++) {
        repo.append(new Session(i * 1000, "25/5/4", 25, 5, 4, 7200));
    }
    var sessions = repo.loadAll();
    Test.assertEqualMessage(50, sessions.size(), "Should trim to 50 max");
    Test.assertEqualMessage(2000, (sessions[0] as Session).completedAt, "Oldest 2 should be trimmed");
    return true;
}

(:test)
function testHistoryCorruptedStorage(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("sessionHistory", "invalid");
    var repo = new HistoryRepository();
    var sessions = repo.loadAll();
    Test.assertEqualMessage(0, sessions.size(), "Corrupted storage should return empty array");
    return true;
}

(:test)
function testHistoryPersistsAcrossInstances(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("sessionHistory");
    var repo1 = new HistoryRepository();
    repo1.append(new Session(5000, "25/5/4", 25, 5, 4, 7200));
    var repo2 = new HistoryRepository();
    var sessions = repo2.loadAll();
    Test.assertEqualMessage(1, sessions.size(), "Should persist across instances");
    return true;
}
```

---

## 8. Checklist de execução

- [x] 1. Criar `source/repositories/HistoryRepository.mc`
- [x] 2. Modificar `source/model/Session.mc` — adicionar `toDict()` e `fromDict()`
- [x] 3. Modificar `source/TomaApp.mc` — adicionar campo `_historyRepo`, instanciar no `initialize()`, adicionar getter `getHistoryRepo()`
- [x] 4. Modificar `source/TomaApp.mc` — adicionar `_appendSessionToHistory()` e chamá-lo no handler ON_COMPLETE
- [x] 5. Adicionar import `using Toybox.Time;` em `source/TomaApp.mc` (necessário para `Time.now()`)
- [x] 6. Modificar `source/views/HistoryView.mc` — adicionar import `App`, substituir `getMockSessions()` por `_loadSessions()` com reverse
- [x] 7. Criar `tests/HistoryRepositoryTest.mc`
- [x] 8. Build para fr255, fr255s, fr265
- [ ] 9. Testar no simulador (caminho feliz)

---

## 9. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [ ] Testes em `tests/HistoryRepositoryTest.mc` passam (6 testes)

### Manual (simulador)
- [ ] Completar uma sessão → navegar para History → sessão aparece no topo da lista
- [ ] Completar segunda sessão → History mostra 2 entries, mais recente no topo
- [ ] Fechar e reabrir o app → History mantém as sessões salvas
- [ ] History com 0 sessões mostra EmptyState corretamente
- [ ] Stopar sessão no meio (B4) → History NÃO ganha nova entry

---

## 10. Out of scope

- Tela de detalhe de uma sessão individual (task futura).
- Exportação/sync de histórico com Garmin Connect (FIT = task 02-11).
- Limpar histórico manualmente (não está no spec V1).
- Filtros ou busca no histórico.
