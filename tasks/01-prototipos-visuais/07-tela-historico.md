# Task 01-07: Tela History

## Objetivo

Implementar a **P7 (History)**: lista vertical scrollable das últimas N sessões concluídas. Visual completo + lógica de scroll. Para esta task, **dados mockados** (array hardcoded com ~10 sessões) — persistência real em `02-09-historico-sessoes`.

## Tipo

- [x] Protótipo Visual
- [x] Comportamento (lógica local — scroll)

## Cobre

- **P7** (History) — `spec/spec.md` §2.P7
- **C11** History Item, **C12** Empty State

## Dependências

- `tasks/01-prototipos-visuais/01-tela-home.md` (scaffold + components básicos).

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets.
- [ ] `--typecheck=Strict` passa.

### Manual

- [ ] Título "HISTORY" / "HISTÓRICO" no topo (FONT_MEDIUM, textPrimary).
- [ ] Lista de até 50 entradas, cada uma com:
  - Linha 1: data + hora (ex: "May 6, 14:32" em EN; "6 Mai, 14:32" em PT). Fonte FONT_TINY, textMuted.
  - Linha 2: duração total (ex: "2h 0m" / "2h 0min"). Fonte FONT_SMALL, textPrimary.
  - Linha 3: preset (ex: "25/5 · 4" ou "Custom 50/10 · 6"). Fonte FONT_XTINY, textMuted.
- [ ] Empty state: "No sessions yet" / "Sem sessões ainda" centralizado, FONT_TINY, textMuted.
- [ ] Up/Down faz scroll (suave, item por item).
- [ ] Em FR265 (touch), swipe up/down também faz scroll.
- [ ] Item destacado (current focus) tem highlight visual (fundo `surface` ou `elevated`).
- [ ] Back volta para tela anterior.
- [ ] Lista não passa do final (clamp).

## Arquivos esperados

### Novos

- `source/views/HistoryView.mc`
- `source/delegates/HistoryDelegate.mc`
- `source/ui/components/HistoryItem.mc`
- `source/ui/components/EmptyState.mc`
- `source/model/Session.mc` — tipo `Session { completedAt, preset, workMin, breakMin, cycles, totalDuration }`. Apenas struct + helpers de formatação.
- `source/utils/TimeFormatter.mc` — helpers para formatar duração ("2h 30m"), data ("May 6, 14:32" / locale-aware).
- `source/utils/DateUtils.mc` — `Time.now()` wrappers, locale detection.

### Modificados

- `source/delegates/HomeDelegate.mc` — adicionar atalho de demo: ao selecionar item Settings, pushView com `HistoryView` mock (com array de demo). Quando Settings real for implementado, History será sub-item dele.
- `resources/strings/strings.xml` + `strings_pt.xml`:
  - `history_title` ("HISTORY" / "HISTÓRICO")
  - `history_empty` ("No sessions yet" / "Sem sessões ainda")
  - `duration_hours_minutes` ("$1$h $2$m" / "$1$h $2$min")
  - `duration_minutes` ("$1$m" / "$1$min")
- `resources/drawables/dimensions.xml` — `historyTitleY`, `historyItemHeight`, `historyItemPadding`.

## Referências obrigatórias

- `references/architecture.md` §2, §3.
- `references/design_system.md` §5.5 (componentes derivados), §7 (strings).
- `references/garmin_platform.md` §2.4 (Storage — não usado nesta task, mas estrutura definida aqui informa o que vamos persistir).
- `spec/spec.md` §2.P7, §4.B10.

## Notas de design

### Mock data

Em `HistoryView.mc`:

```monkeyc
function getMockSessions() as Array<Session> {
    return [
        new Session(Time.now().value() - 3600, "25/5/4", 25, 5, 4, 7200),
        new Session(Time.now().value() - 7200, "30/5/4", 30, 5, 4, 8400),
        new Session(Time.now().value() - 86400, "custom 50/10/3", 50, 10, 3, 10800),
        // ... mais 7 sessões
    ];
}
```

A lista mockada é descartada quando a task `02-09-historico-sessoes` integra com `HistoryRepository`.

### Layout do item (medium)

```
   ┌───────────────────────┐
   │ May 6, 14:32          │  ← FONT_TINY textMuted
   │ 2h 0m                 │  ← FONT_SMALL textPrimary
   │ 25/5 · 4              │  ← FONT_XTINY textMuted
   ├───────────────────────┤
   │ May 6, 11:00          │
   │ ...                   │
```

Altura de cada item: ~52px medium, ~40px small, ~70px large.

### Scroll

Usar `WatchUi.Scroll` (legacy, mas funciona) ou implementar scroll manual com viewport offset.

**Recomendação:** scroll manual — mais controle visual.

```monkeyc
class HistoryView extends Ui.View {
    private var _scrollOffset as Number = 0;

    function scrollDown() {
        _scrollOffset = (_scrollOffset + 1).min(maxScroll());
        Ui.requestUpdate();
    }
    // ...
}
```

### Empty state

Quando lista vazia, renderizar EmptyState com texto + ícone simples (drawable opcional). Em `onUpdate`, checar `if sessions.size() == 0` e desenhar EmptyState ao invés da lista.

### Locale-aware date

`Time.Gregorian.info(time, Time.FORMAT_SHORT)` retorna formato local. Formatar via `Lang.format` com strings traduzidas.

## Out of scope desta task

- Persistência real (`02-09-historico-sessoes`).
- Delete de entrada (V1.x).
- Filtros (V2).
