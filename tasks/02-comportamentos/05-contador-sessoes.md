# Task 02-05: Contador de Sessões (diário)

## Objetivo

Implementar **B9 — Contagem de sessões concluídas (diária)**: contador que incrementa a cada work-phase concluída e reseta diariamente. Persistido em `Application.Storage`. Mostrado em P6 (Cycle Complete) e P7 (History header).

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B9** Contagem de sessões concluídas (dia) — `spec/spec.md` §4.B9

## Dependências

- `tasks/02-comportamentos/01-state-machine-pomodoro.md` (eventos Model existem).
- `tasks/02-comportamentos/02-timer-loop.md`.
- `tasks/01-prototipos-visuais/04-tela-fim-sessao.md` (CycleCompleteView).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings, `--typecheck=Strict` passa.
- [ ] Testes em `tests/CounterRepositoryTest.mc`:
  - Increment funciona.
  - Reset acontece quando data muda.
  - Persistência via Storage funciona (mockando Storage ou usando diretamente).
- [ ] Testes em `tests/DateUtilsTest.mc`: `isSameDay`, `today` retornam valores corretos.

### Manual

- [ ] Ao completar uma work-phase (não pausa, não stop), contador incrementa.
- [ ] Contador NÃO incrementa em break-phase.
- [ ] CycleCompleteView (P6) mostra "Today: %d sessions" com valor real.
- [ ] HistoryView (P7) header mostra contador diário.
- [ ] Forçar mudança de dia no simulador (avançar relógio) → contador volta a 0 ao completar próxima sessão.
- [ ] Persistência sobrevive a app close/reopen.

## Arquivos esperados

### Novos

- `source/repositories/CounterRepository.mc` — leitura/escrita do `dailyCounter` em Storage.
- `source/utils/DateUtils.mc` (já criado em `01-07-tela-historico` provavelmente; aqui adicionar `isSameDay`, `today`).
- `tests/CounterRepositoryTest.mc`.
- `tests/DateUtilsTest.mc`.

### Modificados

- `source/TomaApp.mc` — registrar handler `:onWorkPhaseComplete` que chama `CounterRepository.increment()`.
- `source/views/CycleCompleteView.mc` — usar `CounterRepository.getTodayCount()` em vez de mock.
- `source/views/HistoryView.mc` — adicionar header com contador.
- `resources/strings/strings.xml` + `strings_pt.xml` — `today_sessions_singular` ("Today: 1 session" / "Hoje: 1 sessão"), `today_sessions_plural` ("Today: %d sessions" / "Hoje: %d sessões").

## Referências obrigatórias

- `references/architecture.md` §3 (Repository pattern).
- `references/garmin_platform.md` §2.4 (Storage).
- `spec/spec.md` §4.B9, §6 (regras de negócio — reset diário usa hora local).

## Especificação técnica

### Storage schema

Key: `"dailyCounter"`.
Value: `{ "date": "2026-05-06", "count": 5 }`.

Date como string `YYYY-MM-DD` (mais simples que epoch para comparar dias, locale-aware).

### CounterRepository API

```monkeyc
using Toybox.Application as App;
using Toybox.Time;

class CounterRepository {
    private const KEY = "dailyCounter";

    function getTodayCount() as Number {
        var data = _load();
        return data["count"];
    }

    function increment() as Void {
        var data = _load();
        data["count"] += 1;
        App.Storage.setValue(KEY, data);
    }

    private function _load() as Dictionary {
        var stored = App.Storage.getValue(KEY);
        var todayStr = DateUtils.today();
        if (stored == null || !stored["date"].equals(todayStr)) {
            return { "date" => todayStr, "count" => 0 };
        }
        return stored;
    }
}
```

**Nota:** `_load` retorna sempre data atualizada. Se data mudou, retorna struct novo (não persiste imediatamente — só persiste no próximo `increment`).

### DateUtils

```monkeyc
using Toybox.Time.Gregorian;

module DateUtils {
    function today() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$",
            [info.year.format("%04d"), info.month.format("%02d"), info.day.format("%02d")]);
    }

    function isSameDay(a as String, b as String) as Boolean {
        return a.equals(b);
    }
}
```

### Handler no TomaApp

```monkeyc
function _onModelEvent(eventType as Symbol) {
    if (eventType == :onWorkPhaseComplete) {
        _counterRepo.increment();
    }
    // ... outros handlers
}
```

### Timezone

Garmin Connect IQ usa hora local do device. Se o usuário viaja e muda timezone durante uma sessão, comportamento é "lenient":
- Se durante sessão a data muda (ex: cruzou meia-noite), próxima incrementação detecta e reseta. Resultado: a sessão atravessa para um novo dia "limpo".
- Aceita como edge case raro. Documentar em `spec/spec.md` §6.

## Out of scope desta task

- Histórico semanal/mensal (V2 com gráficos).
- Streaks (V2).
