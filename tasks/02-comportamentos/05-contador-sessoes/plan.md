# Plan — Task 02-05: Contador de Sessões (diário)

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Implementar o `CounterRepository` que persiste em `Application.Storage` a quantidade de work-phases completadas no dia corrente, com reset automático ao detectar mudança de data. Integrar no fluxo existente (`TomaApp.onModelEvent`) e alimentar `CycleCompleteView` com o valor real.

---

## 2. Cenários

### Caminho feliz
1. Usuário completa uma work-phase → Model emite `ON_WORK_PHASE_COMPLETE` → `TomaApp.onModelEvent` chama `_counterRepo.increment()` → Storage é atualizado.
2. Ao completar o ciclo todo, `CycleCompleteView` é exibida mostrando "Today: N sessions" (ou "Today: 1 session") com valor real do `CounterRepository.getTodayCount()`.

### Edge cases
- **Primeira execução:** Storage retorna `null` → `_load()` retorna `{ "date": today, "count": 0 }`.
- **Mudança de dia:** App abre no dia seguinte → `_load()` detecta data diferente → retorna count=0 (reset lazy).
- **Contagem == 1:** exibir string singular "Today: 1 session".
- **Storage corrompido:** valor não é Dictionary ou falta keys → tratar como fresh (count=0).

### Erros
- `Storage.getValue` retorna tipo inesperado → validar com `instanceof Dictionary`; se falhar, retornar fresh struct.

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `source/repositories/CounterRepository.mc` | Leitura/escrita do `dailyCounter` em Storage. Métodos: `getTodayCount()`, `increment()` |
| 2 | `tests/CounterRepositoryTest.mc` | Testar increment, getTodayCount, reset diário |
| 3 | `tests/DateUtilsTest.mc` | Testar `today()`, `isSameDay()` |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `source/utils/DateUtils.mc` | Adicionar funções `today()` e `isSameDay()` |
| 2 | `source/TomaApp.mc` | Instanciar `CounterRepository`; chamar `increment()` no handler; passar count real ao CycleCompleteView |
| 3 | `source/views/CycleCompleteView.mc` | Usar string resource com pluralização ao renderizar "Today: N sessions" |
| 4 | `resources/strings/strings.xml` | Adicionar `today_session_singular` |

---

### 4.1 `source/utils/DateUtils.mc`

**Antes:**
```monkeyc
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;

module DateUtils {
    function formatDate(epoch as Lang.Number) as Lang.String {
```

**Depois:**
```monkeyc
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;

module DateUtils {
    function today() as Lang.String {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var year = info.year as Lang.Number;
        var month = info.month as Lang.Number;
        var day = info.day as Lang.Number;
        return Lang.format("$1$-$2$-$3$", [year.format("%04d"), month.format("%02d"), day.format("%02d")]);
    }

    function isSameDay(a as Lang.String, b as Lang.String) as Lang.Boolean {
        return a.equals(b);
    }

    function formatDate(epoch as Lang.Number) as Lang.String {
```

---

### 4.2 `source/TomaApp.mc`

**Antes (campos e initialize):**
```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _attentionService = new AttentionService();
        _model.addObserver(method(:onModelEvent));
    }
```

**Depois (campos e initialize):**
```monkeyc
class TomaApp extends App.AppBase {
    private var _model as PomodoroModel;
    private var _timerService as TimerService;
    private var _attentionService as AttentionService;
    private var _counterRepo as CounterRepository;
    private var _lastPreset as Preset or Null;
    private var _skipNextPhaseChange as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        _model = new PomodoroModel();
        _timerService = new TimerService();
        _attentionService = new AttentionService();
        _counterRepo = new CounterRepository();
        _model.addObserver(method(:onModelEvent));
    }
```

**Antes (onModelEvent — trecho ON_COMPLETE):**
```monkeyc
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), 0);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
```

**Depois (onModelEvent — trecho ON_WORK_PHASE_COMPLETE + ON_COMPLETE):**
```monkeyc
        } else if (event == PomodoroEvent.ON_WORK_PHASE_COMPLETE) {
            _counterRepo.increment();
        } else if (event == PomodoroEvent.ON_COMPLETE) {
            _attentionService.alertCycleComplete();
            _timerService.stop();
            var todaySessions = _counterRepo.getTodayCount();
            var view = new CycleCompleteView(_model.getCyclesCompleted(), _model.getTotalCycles(), todaySessions);
            var delegate = new CycleCompleteDelegate();
            delegate.setView(view);
            Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        }
```

---

### 4.3 `source/views/CycleCompleteView.mc`

**Antes (todayText no onUpdate):**
```monkeyc
        if (bucket != :small) {
            var todayY = Dimensions.cycleTodayY(bucket);
            var todayFont = Gfx.FONT_TINY;
            var todayText = Lang.format("$1$ $2$ $3$", ["Today:", _todaySessions, "sessions"]);
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, todayY, todayFont, todayText, Gfx.TEXT_JUSTIFY_CENTER);
        }
```

**Depois:**
```monkeyc
        if (bucket != :small) {
            var todayY = Dimensions.cycleTodayY(bucket);
            var todayFont = Gfx.FONT_TINY;
            var todayText;
            if (_todaySessions == 1) {
                todayText = Ui.loadResource(Rez.Strings.today_session_singular) as Lang.String;
            } else {
                todayText = Lang.format(Ui.loadResource(Rez.Strings.today_sessions) as Lang.String, [_todaySessions]);
            }
            dc.setColor(Colors.TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, todayY, todayFont, todayText, Gfx.TEXT_JUSTIFY_CENTER);
        }
```

---

### 4.4 `resources/strings/strings.xml`

**Antes:**
```xml
    <string id="today_sessions">Today: $1$ sessions</string>
```

**Depois:**
```xml
    <string id="today_sessions">Today: $1$ sessions</string>
    <string id="today_session_singular">Today: 1 session</string>
```

---

## 5. Storage/Properties

| Key | Tipo | Default | Onde lido | Onde escrito |
|---|---|---|---|---|
| `dailyCounter` | `Dictionary { "date": String, "count": Number }` | `{ "date": today(), "count": 0 }` | `CounterRepository._load()` | `CounterRepository.increment()` |

---

## 6. Arquivo novo: `source/repositories/CounterRepository.mc`

```monkeyc
using Toybox.Application as App;
using Toybox.Lang;

class CounterRepository {
    private const STORAGE_KEY = "dailyCounter";

    function getTodayCount() as Lang.Number {
        var data = _load();
        return data["count"] as Lang.Number;
    }

    function increment() as Void {
        var data = _load();
        var count = data["count"] as Lang.Number;
        data["count"] = count + 1;
        App.Storage.setValue(STORAGE_KEY, data);
    }

    private function _load() as Lang.Dictionary {
        var stored = App.Storage.getValue(STORAGE_KEY);
        var today = DateUtils.today();

        if (stored instanceof Lang.Dictionary) {
            var dict = stored as Lang.Dictionary;
            if (dict.hasKey("date") && dict.hasKey("count")) {
                var storedDate = dict["date"];
                if (storedDate instanceof Lang.String && DateUtils.isSameDay(storedDate as Lang.String, today)) {
                    return dict;
                }
            }
        }

        return { "date" => today, "count" => 0 };
    }
}
```

---

## 7. Arquivo novo: `tests/CounterRepositoryTest.mc`

```monkeyc
using Toybox.Test;
using Toybox.Application as App;
using Toybox.Lang;

(:test)
function testIncrementFromZero(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("dailyCounter");
    var repo = new CounterRepository();
    repo.increment();
    Test.assertEqualMessage(1, repo.getTodayCount(), "After 1 increment, count should be 1");
    return true;
}

(:test)
function testIncrementMultiple(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("dailyCounter");
    var repo = new CounterRepository();
    repo.increment();
    repo.increment();
    repo.increment();
    Test.assertEqualMessage(3, repo.getTodayCount(), "After 3 increments, count should be 3");
    return true;
}

(:test)
function testResetOnNewDay(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("dailyCounter", { "date" => "2020-01-01", "count" => 5 });
    var repo = new CounterRepository();
    Test.assertEqualMessage(0, repo.getTodayCount(), "Old date should reset to 0");
    return true;
}

(:test)
function testCorruptedStorageReturnsZero(logger as Test.Logger) as Lang.Boolean {
    App.Storage.setValue("dailyCounter", "invalid");
    var repo = new CounterRepository();
    Test.assertEqualMessage(0, repo.getTodayCount(), "Corrupted data should return 0");
    return true;
}

(:test)
function testIncrementPersists(logger as Test.Logger) as Lang.Boolean {
    App.Storage.deleteValue("dailyCounter");
    var repo = new CounterRepository();
    repo.increment();
    var repo2 = new CounterRepository();
    Test.assertEqualMessage(1, repo2.getTodayCount(), "Count should persist across instances");
    return true;
}
```

---

## 8. Arquivo novo: `tests/DateUtilsTest.mc`

```monkeyc
using Toybox.Test;
using Toybox.Lang;

(:test)
function testTodayReturnsFormattedDate(logger as Test.Logger) as Lang.Boolean {
    var result = DateUtils.today();
    Test.assert(result.length() == 10);
    Test.assertEqualMessage("-", result.substring(4, 5), "Should have dash at pos 4");
    Test.assertEqualMessage("-", result.substring(7, 8), "Should have dash at pos 7");
    return true;
}

(:test)
function testIsSameDayTrue(logger as Test.Logger) as Lang.Boolean {
    Test.assert(DateUtils.isSameDay("2026-05-08", "2026-05-08"));
    return true;
}

(:test)
function testIsSameDayFalse(logger as Test.Logger) as Lang.Boolean {
    Test.assert(!DateUtils.isSameDay("2026-05-08", "2026-05-09"));
    return true;
}
```

---

## 9. Checklist de execução

- [x] 1. Criar diretório `source/repositories/` (se não existir)
- [x] 2. Criar `source/repositories/CounterRepository.mc`
- [x] 3. Modificar `source/utils/DateUtils.mc` — adicionar `today()` e `isSameDay()`
- [x] 4. Modificar `source/TomaApp.mc` — adicionar campo `_counterRepo`, instanciar no `initialize()`, adicionar handler `ON_WORK_PHASE_COMPLETE`, passar count real no `ON_COMPLETE`
- [x] 5. Modificar `source/views/CycleCompleteView.mc` — pluralização com string resources
- [x] 6. Modificar `resources/strings/strings.xml` — adicionar `today_session_singular`
- [x] 7. Criar `tests/CounterRepositoryTest.mc`
- [x] 8. Criar `tests/DateUtilsTest.mc`
- [x] 9. Build para fr255, fr255s, fr265
- [ ] 10. Testar no simulador (caminho feliz + reset diário)

---

## 10. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [ ] Testes unitários passam (`CounterRepositoryTest`, `DateUtilsTest`)

### Manual (simulador)
- [ ] Completar 1 work-phase → CycleCompleteView mostra "Today: 1 session"
- [ ] Completar 2 work-phases → CycleCompleteView mostra "Today: 2 sessions"
- [ ] Simular data antiga no Storage → contador reseta para 0 no próximo incremento
- [ ] Bucket `:small` (fr255s) não exibe linha "Today" (comportamento já existente mantido)

---

## 11. Out of scope

- Mostrar contador no `HistoryView` (P7) — PRD decidiu omitir (opção C da D3).
- Localização PT da string singular — será feita na task de i18n.
- Injeção de clock para testes de data (aceitar uso de Storage real no simulador).
- Persistência do contador entre app kills durante sessão ativa (edge case aceito no PRD — risco #3).
