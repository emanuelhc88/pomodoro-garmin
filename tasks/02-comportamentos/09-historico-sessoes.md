# Task 02-09: Histórico de Sessões (persistência)

## Objetivo

Implementar **B10** — `HistoryRepository` que persiste as últimas 50 sessões em `Application.Storage`. Conectar com:
- Append ao completar uma sessão (cycle complete).
- Read em P7 (HistoryView) para mostrar lista real.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B10** Histórico persistente — `spec/spec.md` §4.B10

## Dependências

- `tasks/01-prototipos-visuais/07-tela-historico.md` (HistoryView visual existe).
- `tasks/02-comportamentos/04-pausa-resume-stop.md` (CycleComplete dispara onComplete).
- `tasks/02-comportamentos/01-state-machine-pomodoro.md` (Model emite onComplete).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings, `--typecheck=Strict` passa.
- [ ] Testes em `tests/HistoryRepositoryTest.mc`:
  - List vazio inicialmente.
  - Append adiciona corretamente.
  - Append > 50 trim os mais antigos.
  - List é ordenada do mais recente para o mais antigo.
  - Schema serializa/deserializa Session corretamente.

### Manual

- [ ] Iniciar sessão de 25/5/4 com preset rápido (use 1/1/2 para teste rápido), deixar completar.
- [ ] Abrir HistoryView (via Settings → History).
- [ ] Lista mostra a sessão recém-completada com data/hora corretas, duração e preset.
- [ ] Completar mais 5 sessões diferentes (alternar presets).
- [ ] HistoryView lista as 6 mais recentes (mais nova no topo).
- [ ] Stopar uma sessão (não completar) → não aparece no histórico.
- [ ] Persiste após fechar/reabrir app.

## Arquivos esperados

### Novos

- `source/repositories/HistoryRepository.mc`.
- `tests/HistoryRepositoryTest.mc`.

### Modificados

- `source/model/Session.mc` — adicionar serialização (`toDict()`, `fromDict(d)`) se ainda não tem.
- `source/TomaApp.mc` — handler de `:onComplete` chama `HistoryRepository.append(session)`.
- `source/views/HistoryView.mc` — usar `HistoryRepository.loadAll()` em vez de mock.

## Referências obrigatórias

- `references/architecture.md` §3 (Repository).
- `references/garmin_platform.md` §2.4 (Storage).
- `spec/spec.md` §4.B10, §6 (regras de negócio — só sessões completas).

## Especificação técnica

### Session.mc — serialização

```monkeyc
class Session {
    public var completedAt as Number;     // epoch seconds
    public var presetLabel as String;     // "25/5/4" ou "Custom 50/10/3"
    public var workMin as Number;
    public var breakMin as Number;
    public var cycles as Number;
    public var totalDuration as Number;   // segundos totais (work + breaks)

    function initialize(completedAt, label, workMin, breakMin, cycles, totalDuration) {
        // ...
    }

    function toDict() as Dictionary {
        return {
            "completedAt" => completedAt,
            "presetLabel" => presetLabel,
            "workMin" => workMin,
            "breakMin" => breakMin,
            "cycles" => cycles,
            "totalDuration" => totalDuration
        };
    }

    static function fromDict(d as Dictionary) as Session {
        return new Session(
            d["completedAt"], d["presetLabel"],
            d["workMin"], d["breakMin"], d["cycles"], d["totalDuration"]
        );
    }
}
```

### HistoryRepository

```monkeyc
using Toybox.Application as App;

class HistoryRepository {
    private const KEY = "sessionHistory";
    private const MAX_ENTRIES = 50;

    function loadAll() as Array<Session> {
        var raw = App.Storage.getValue(KEY);
        if (raw == null) { return []; }
        var list = raw as Array<Dictionary>;
        var sessions = [] as Array<Session>;
        for (var i = 0; i < list.size(); i++) {
            sessions.add(Session.fromDict(list[i]));
        }
        return sessions;
    }

    function append(session as Session) as Void {
        var raw = App.Storage.getValue(KEY);
        var list = (raw == null) ? [] : raw as Array;
        list.add(session.toDict());
        // Trim para MAX
        while (list.size() > MAX_ENTRIES) {
            list = list.slice(1, null);
        }
        App.Storage.setValue(KEY, list);
    }
}
```

### Ordenação

`loadAll` retorna na ordem que foi salvo (ascending por completedAt, mais antigo primeiro). HistoryView precisa **inverter** para mostrar mais recente no topo.

Alternativa: salvar prepended em vez de appended. Mais simples para read, mas trim fica mais complexo. Manter append + reverse no read.

```monkeyc
class HistoryView {
    function _getOrderedSessions() as Array<Session> {
        var all = _historyRepo.loadAll();
        var reversed = [] as Array<Session>;
        for (var i = all.size() - 1; i >= 0; i--) {
            reversed.add(all[i]);
        }
        return reversed;
    }
}
```

### Handler em TomaApp

```monkeyc
function _onModelEvent(eventType as Symbol) {
    if (eventType == :onComplete) {
        var session = _buildSessionFromModel();
        _historyRepo.append(session);
        // ... outros handlers (cycle complete view, ActivityService.stop, etc.)
    }
}

private function _buildSessionFromModel() as Session {
    var preset = _model.getPreset();
    var label = preset.isCustom ? "Custom" : preset.formatPrimary();
    return new Session(
        Time.now().value(),
        label,
        preset.workMin, preset.breakMin, preset.cycles,
        _calculateTotalDuration(preset)
    );
}

private function _calculateTotalDuration(preset) as Number {
    var work = preset.cycles * preset.workMin * 60;
    var shortBreaks = (preset.cycles - 1) * preset.breakMin * 60;
    var longBreak = preset.getLongBreakSeconds();
    return work + shortBreaks + longBreak;
}
```

## Out of scope desta task

- Delete de entrada (V1.x).
- Filtros (V2).
- Stats agregados (V2).
- Sync entre devices (V2).
