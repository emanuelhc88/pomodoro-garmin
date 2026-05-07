# PRD — Task 01-07: Tela History

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Implementar a pagina P7 (History): lista vertical scrollable com as ultimas N sessoes concluidas, com dados mockados (array hardcoded ~10 sessoes). Inclui componente HistoryItem (3 linhas por item), EmptyState, scroll manual por viewport offset, modelo Session como struct, e utilitarios de formatacao de data/duracao.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que aproveitar |
|---|---|
| `source/ui/layout/Bucket.mc` | `Bucket.detect()` para determinar bucket de tela |
| `source/ui/layout/Colors.mc` | Constantes `BG`, `TEXT_PRIMARY`, `TEXT_MUTED`, `BORDER` |
| `source/ui/layout/Dimensions.mc` | Padrao de funcoes por bucket — seguir mesmo estilo para dimensoes de History |
| `source/model/Preset.mc` | Pattern para model class simples com formatacao |
| `source/views/CycleCompleteView.mc` | Pattern para View com `onUpdate` renderizando via bucket + Dimensions |
| `source/delegates/CycleCompleteDelegate.mc` | Pattern para Delegate com navegacao (up/down/back) |
| `source/delegates/HomeDelegate.mc` | Local onde adicionar atalho demo para HistoryView |

### 2.2 Assets disponiveis

- Fontes nativas Garmin: `FONT_MEDIUM` (titulo), `FONT_TINY` (data), `FONT_SMALL` (duracao), `FONT_XTINY` (preset).
- Paleta ja definida em `Colors.mc`.
- Nenhum icone extra necessario (empty state sera apenas texto).

### 2.3 Approach de implementacao

**Scroll manual com viewport offset** (recomendado na task). Razao: `WatchUi.Scroll` legacy nao oferece controle visual fino; com offset manual temos highlight do item focused e controle de clamp.

Estrutura:
- `HistoryView` mantem `_scrollOffset` (indice do primeiro item visivel) e `_focusIdx` (item em destaque).
- `onUpdate` calcula quantos itens cabem na tela (`_visibleCount`), itera de `_scrollOffset` ate `_scrollOffset + _visibleCount`, renderiza cada HistoryItem.
- `HistoryDelegate` trata `onNextPage`/`onPreviousPage` para scroll e `onBack` para pop.

**Session como struct pura** (sem logica de persistencia). Apenas campos + helper `formatDuration()` e `formatDate()`.

**TimeFormatter e DateUtils como modules** (sem instanciacao). Funcs estaticas utilitarias.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura confirmada |
|---|---|---|
| `Time.now()` | Gerar timestamps mock | `Time.now() as Moment` → `.value() as Number` (epoch seconds) |
| `Time.Gregorian.info(moment, format)` | Converter epoch em dia/mes/hora/min | `Gregorian.info(moment as Moment, format as Number) as Info` |
| `Time.Gregorian.moment(options)` | Criar Moment a partir de epoch (via dict) | `Gregorian.moment({:year, :month, :day, :hour, :minute, :second}) as Moment` |
| `Toybox.Lang.format` | Formatar strings com parametros | `Lang.format(pattern, args)` |
| `WatchUi.requestUpdate()` | Forcar re-render apos scroll | Standard |
| `WatchUi.pushView/popView` | Navegacao | Standard |

**Nota:** `Time.Gregorian.info()` retorna struct com campos: `year`, `month`, `day`, `hour`, `min`, `sec`, `day_of_week`. O `month` e Number (1-12), nao string. Precisamos de arrays de nomes de mes para exibicao localizada.

### 2.5 Cores/dimensoes/strings necessarias

**Cores (ja existem em Colors.mc):**
| Token | Uso |
|---|---|
| `Colors.BG` | Fundo da tela |
| `Colors.TEXT_PRIMARY` | Duracao total (linha 2) |
| `Colors.TEXT_MUTED` | Data (linha 1) + preset (linha 3) + titulo |
| `Colors.BORDER` | Separador entre items (opcional), fundo do item focused |

**Dimensoes novas (a adicionar em Dimensions.mc):**
| Funcao | Small | Medium | Large | Uso |
|---|---|---|---|---|
| `historyTitleY` | 15 | 20 | 35 | Y do titulo "HISTORY" |
| `historyItemHeight` | 40 | 52 | 70 | Altura de cada item |
| `historyItemPadding` | 4 | 6 | 10 | Padding vertical entre items |
| `historyListStartY` | 35 | 45 | 70 | Y inicio da lista |
| `historyItemLine1Offset` | 2 | 4 | 6 | Offset da linha 1 (data) relativo ao topo do item |
| `historyItemLine2Offset` | 14 | 18 | 26 | Offset da linha 2 (duracao) relativo ao topo do item |
| `historyItemLine3Offset` | 28 | 36 | 50 | Offset da linha 3 (preset) relativo ao topo do item |

**Strings novas:**
| Key | EN | PT |
|---|---|---|
| `history_title` | HISTORY | HISTORICO |
| `history_empty` | No sessions yet | Sem sessoes ainda |
| `duration_hours_minutes` | $1$h $2$m | $1$h $2$min |
| `duration_minutes` | $1$m | $1$min |

**Arrays de nomes de mes (no TimeFormatter, hardcoded — nao ha recurso i18n para eles no Connect IQ):**
- EN: `["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]`
- PT: `["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]`

---

## 3. Decisoes a tomar

### D1: Highlight do item focused — cor de fundo ou borda lateral?

| Opcao | Pros | Contras |
|---|---|---|
| **A) Fundo `BORDER` (0x2A2A2A)** | Visivel em AMOLED e MIP; consistente com elevated surfaces | Pode ficar sutil em MIP |
| B) Borda lateral accent | Mais saliente | Adiciona complexidade visual, destoa do design minimalista |

**Recomendacao:** Opcao A — fundo `BORDER`. Task ja sugere `surface` ou `elevated`. `BORDER` (0x2A2A2A) e o mais proximo de `elevated` (0x1F1F1F) na paleta existente. Simples, funcional.

### D2: Locale detection para meses — system language ou string resource?

| Opcao | Pros | Contras |
|---|---|---|
| **A) Via `System.getDeviceSettings().systemLanguage`** | Simples, direto | Ignora override manual do setting `language` |
| B) Via string resource (array em strings.xml) | Respeita override | Connect IQ nao permite arrays em strings.xml facilmente |
| **C) Via helper que le `systemLanguage` e aplica meses hardcoded** | Funciona em runtime, simples | Meses ficam hardcoded no source |

**Recomendacao:** Opcao C — helper em `DateUtils` que retorna array de meses baseado em `systemLanguage`. Quando Settings real for implementado (task futura), o helper pode ser atualizado para checar o setting.

### D3: Formato de data — "May 6, 14:32" vs "6 May, 14:32"?

| Opcao | Pros | Contras |
|---|---|---|
| **A) "May 6, 14:32" (EN) / "6 Mai, 14:32" (PT)** | Conforme especificado na task | Precisa de logica condicional por locale |
| B) Formato unico ISO-ish "06/05 14:32" | Simples, sem locale | Menos legivel, nao respeita cultura |

**Recomendacao:** Opcao A — conforme a task. EN: "Mon D, HH:MM", PT: "D Mon, HH:MM".

### D4: Navegacao para HistoryView — via qual item do Home?

A task diz: "ao selecionar item Settings, pushView com HistoryView mock". O HomeDelegate tem 5 items (indices 0-4), sendo 4 = Settings.

**Recomendacao:** Quando `selectedIndex == 4` (Settings), pushView HistoryView. Temporario ate Settings real existir.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | `Time.Gregorian.info` pode retornar month como 1-based ou 0-based dependendo do SDK | Validar no simulador; assumir 1-based conforme docs oficiais |
| 2 | Heap apertado se mock array tiver 50 sessoes (cada Session e um objeto) | Mock com apenas 10 items; limitar array real a 50 em task futura |
| 3 | Scroll pode parecer "laggy" em devices MIP (refresh mais lento) | Scroll muda apenas offset numerico + requestUpdate(); render e simples |
| 4 | FONT_XTINY pode nao existir em todos devices | Fallback para FONT_TINY se bucket == :small |
| 5 | Nomes de mes hardcoded precisam de manutencao se mais linguas forem adicionadas | Aceitavel para V1 (apenas EN/PT); refatorar em V2 |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/views/HistoryView.mc` | **Novo.** View com scroll manual, renderiza titulo + lista/empty state |
| `source/delegates/HistoryDelegate.mc` | **Novo.** Input: up/down = scroll, back = pop |
| `source/ui/components/HistoryItem.mc` | **Novo.** Module com `draw(dc, x, y, session, focused, bucket)` |
| `source/ui/components/EmptyState.mc` | **Novo.** Module com `draw(dc, centerX, centerY, text, bucket)` |
| `source/model/Session.mc` | **Novo.** Class com campos: completedAt, preset, workMin, breakMin, cycles, totalDuration + formatters |
| `source/utils/TimeFormatter.mc` | **Novo.** Module: `formatDuration(seconds)`, `formatTime(hour, min)` |
| `source/utils/DateUtils.mc` | **Novo.** Module: `formatDate(epoch, locale)`, `getMonthNames(locale)`, `getLocale()` |
| `source/ui/layout/Dimensions.mc` | **Modificar.** Adicionar funcoes history* |
| `source/delegates/HomeDelegate.mc` | **Modificar.** Item 4 (Settings) → push HistoryView (demo) |
| `resources/strings/strings.xml` | **Modificar.** Adicionar 4 strings history |
| `resources-por/strings/strings.xml` | **Modificar.** Adicionar 4 strings history PT |

---

## 6. Arquitetura do fluxo

```
HomeDelegate.onSelect(idx=4)
    │
    ▼
Ui.pushView(HistoryView, HistoryDelegate, SLIDE_LEFT)
    │
    ▼
HistoryView.initialize()
    ├── _sessions = getMockSessions()  [10 Session objects]
    ├── _scrollOffset = 0
    ├── _focusIdx = 0
    └── _visibleCount = calculado no onUpdate

HistoryView.onUpdate(dc)
    ├── dc.clear(BG)
    ├── drawTitle("HISTORY", FONT_MEDIUM, TEXT_MUTED)
    ├── if _sessions.size() == 0:
    │       EmptyState.draw(dc, centerX, centerY, "No sessions yet")
    │       return
    ├── for i = _scrollOffset to min(_scrollOffset + _visibleCount, sessions.size()-1):
    │       HistoryItem.draw(dc, x, y, sessions[i], i == _focusIdx, bucket)
    │       y += historyItemHeight + historyItemPadding
    └── (clip: items fora da area visivel nao sao desenhados)

HistoryDelegate.onNextPage()
    ├── _focusIdx = min(_focusIdx + 1, sessions.size() - 1)
    ├── if _focusIdx >= _scrollOffset + _visibleCount:
    │       _scrollOffset++
    └── Ui.requestUpdate()

HistoryDelegate.onPreviousPage()
    ├── _focusIdx = max(_focusIdx - 1, 0)
    ├── if _focusIdx < _scrollOffset:
    │       _scrollOffset--
    └── Ui.requestUpdate()

HistoryDelegate.onBack()
    └── Ui.popView(SLIDE_RIGHT)
```

---

## 7. Referencias para o plan.md

| Referencia | Secoes relevantes |
|---|---|
| `references/architecture.md` | §2 (estrutura pastas), §3 (separacao responsabilidades), §4 (regras codificacao) |
| `references/design_system.md` | §2.1 (paleta), §3.2 (fontes), §4.1 (buckets), §7 (strings) |
| `references/garmin_platform.md` | §2.4 (Storage — schema futuro), §2.8 (getDeviceSettings) |
| `spec/spec.md` | §2.P7 (History), §4.B10 (historico persistente — schema) |
| Este PRD | Decisoes D1-D4, fluxo §6 |

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
