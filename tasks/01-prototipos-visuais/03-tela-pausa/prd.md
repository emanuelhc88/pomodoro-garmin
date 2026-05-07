# PRD — Task 01-03: Tela Pausa (Paused state)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Implementar P4 (Paused) como variacao visual de P3 (Timer Running) ja existente. Mesmo layout de `TimerView`, mas com anel em cor "dim" (escurecida), display MM:SS em `textMuted`, phase label em `textMuted`, e label adicional "PAUSED" abaixo do display. Valores hardcoded — sem logica de timer real.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que ja existe |
|---|---|
| `source/views/TimerView.mc` | View completa com render de P3. Aceita `phase`, `remaining`, `total`, `completedCycles`, `totalCycles`. Ja chama todos os componentes. |
| `source/ui/components/TimerRing.mc` | Modulo `TimerRing.draw()` — recebe `color` por parametro. |
| `source/ui/components/TimerDisplay.mc` | Modulo `TimerDisplay.draw()` — cor fixa em `Colors.TEXT_PRIMARY`. Precisa aceitar parametro `color`. |
| `source/ui/components/PhaseLabel.mc` | Modulo `PhaseLabel.draw()` — ja aceita `color` por parametro. Pronto. |
| `source/ui/components/SessionPills.mc` | Modulo `SessionPills.draw()` — sem alteracoes. Pills permanecem visiveis. |
| `source/ui/layout/Colors.mc` | Constantes `BG`, `BRAND`, `ACCENT`, `TEXT_PRIMARY`, `TEXT_MUTED`, `BORDER`. |
| `source/ui/layout/Dimensions.mc` | Todas dimensoes de timer. Falta `pausedLabelOffsetY`. |
| `source/delegates/HomeDelegate.mc` | Demo com 3 estados (work, short break, long break). Precisa de 4o estado pausado. |
| `source/delegates/TimerDelegate.mc` | `onSelect()` com TODO pause/resume. Ponto de integracao futuro. |

### 2.2 Assets disponiveis

- Fontes: nativas Garmin (FONT_TINY, FONT_XTINY disponivel para label "PAUSED").
- Cores: paleta Toma completa em `Colors.mc`. Falta apenas cores dim.
- Strings: `strings.xml` ja tem `phase_focus`, `phase_break`, `phase_long_break`. Falta `state_paused`.

### 2.3 Approach de implementacao

**Decisao: Opcao A (tabela hex pre-calculada para cores dim).**

Justificativa:
- Evita calculo em `onUpdate()` (regra de arquitetura: nao alocar/computar em render loop).
- Garante consistencia visual em MIP (64 cores) que mapeiam valores hex — resultado previsivel.
- Opcao B (helper runtime `dimColor()`) seria mais flexivel mas viola a regra de minimo processamento no render e gera cores imprevisíveis em MIP.

**Modelo de parametrizacao:** adicionar `isPaused as Lang.Boolean` ao construtor de `TimerView`. O `onUpdate` usa esse flag para:
1. Passar cor dim ao `TimerRing` em vez da cor da fase.
2. Passar `Colors.TEXT_MUTED` ao `TimerDisplay` em vez de `TEXT_PRIMARY`.
3. Passar `Colors.TEXT_MUTED` ao `PhaseLabel` (a label ja recebe cor por argumento).
4. Desenhar label "PAUSED" adicional.

### 2.4 APIs Connect IQ utilizadas

Nenhuma API nova. Apenas APIs ja em uso:
- `Gfx.Dc.drawText(x, y, font, text, justify)` — para label "PAUSED".
- `Gfx.Dc.drawArc(...)` — ja usado por TimerRing.
- `Gfx.FONT_TINY` / `Gfx.FONT_XTINY` — para label paused.
- `Gfx.getFontHeight(font)` — para calcular posicao Y.

### 2.5 Cores/dimensoes/strings necessarias

**Cores novas (em `Colors.mc`):**

| Token | Hex | Derivacao |
|---|---|---|
| `BRAND_DIM` | `0x6E2017` | ~50% do `#E8432D` (shift right 1 cada canal) |
| `TEXT_MUTED_DIM` | `0x444444` | ~50% do `#888888` |
| `ACCENT_DIM` | `0x803624` | ~50% do `#FF6B47` |

**Dimensoes novas (em `Dimensions.mc`):**

| Token | Small | Medium | Large | Uso |
|---|---|---|---|---|
| `pausedLabelOffsetY` | 30 | 35 | 60 | Offset Y do label "PAUSED" abaixo do centerY do display |

**Strings novas (em `strings.xml`):**

| Key | EN | PT (futura) |
|---|---|---|
| `state_paused` | PAUSED | PAUSADO |

---

## 3. Decisoes a tomar

### D1: Cor dim — tabela ou runtime?

| Opcao | Pros | Contras |
|---|---|---|
| A) Tabela hex em `Colors.mc` | Zero compute em render; previsivel em MIP | Mais constantes manuais |
| B) Helper `dimColor(rgb)` runtime | Uma funcao resolve todos | Compute em onUpdate; resultado imprevisivel MIP |

**Recomendacao: A.** Alinhado com a task (que tambem recomenda A) e com a regra da arquitetura de nao computar em onUpdate.

### D2: Parametro `isPaused` — boolean no construtor ou symbol de estado unificado?

| Opcao | Pros | Contras |
|---|---|---|
| A) `isPaused as Boolean` como 6o param do construtor | Simples; task pede explicitamente isso | Acumula parametros |
| B) Unificar phase em symbol que inclui paused (ex: `:paused_work`) | State machine mais limpa (futuro) | Over-engineering para prototipo visual |

**Recomendacao: A.** Task explicitamente pede `isPaused as Boolean`. Unificacao de states fica para tasks de comportamento (02-xx).

### D3: Label "PAUSED" — como string?

| Opcao | Pros | Contras |
|---|---|---|
| A) Via `Rez.Strings.state_paused` (i18n) | Correto para producao | Requer carregar resource no onUpdate |
| B) Hardcoded `"PAUSED"` por enquanto | Prototipo visual, zero overhead | Violaria regra de "nunca string hardcoded" |

**Recomendacao: A.** Adicionar a string em `strings.xml` e usar `WatchUi.loadResource(Rez.Strings.state_paused)`. Carregar no `initialize()` e guardar em var membro para nao alocar no onUpdate.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | Cores dim ficam indistinguiveis do BG em MIP 64 cores | Validar no simulador FR255 apos implementar. Se necessario, ajustar hex. |
| 2 | Label "PAUSED" sobrepoe SessionPills em bucket small | Usar offset menor (30px) e FONT_XTINY no small bucket. Validar visualmente. |
| 3 | `FONT_XTINY` pode nao existir em todos devices | Connect IQ garante FONT_XTINY em System 7+. Sem risco real. |
| 4 | Acumulo de parametros no construtor (6 params) | Aceitavel para prototipo. Refactor para struct/dict fica para behavior tasks. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/views/TimerView.mc` | Adicionar param `isPaused`. Condicional de cores e render da label "PAUSED". |
| `source/ui/components/TimerDisplay.mc` | Adicionar param `color as Lang.Number` ao `draw()`. |
| `source/ui/layout/Colors.mc` | Adicionar `BRAND_DIM`, `ACCENT_DIM`, `TEXT_MUTED_DIM`. |
| `source/ui/layout/Dimensions.mc` | Adicionar `pausedLabelOffsetY(bucket)`. |
| `source/delegates/HomeDelegate.mc` | Adicionar 4o estado demo com `isPaused = true`. |
| `resources/strings/strings.xml` | Adicionar `state_paused`. |

---

## 6. Arquitetura do fluxo

```
HomeDelegate.onSelect() [idx=3, isPaused=true]
  │
  ├── pushView(new TimerView(:running_work, 900, 1500, 2, 4, true), ...)
  │
  └── TimerView.onUpdate(dc)
        │
        ├── isPaused? → phaseColor = getDimColor(_phase)   // BRAND_DIM, etc.
        │               displayColor = TEXT_MUTED
        │               labelColor = TEXT_MUTED
        │
        ├── PhaseLabel.draw(dc, x, y, text, labelColor, bucket)
        │
        ├── TimerRing.draw(dc, x, y, r, s, progress, phaseColor)
        │
        ├── TimerDisplay.draw(dc, x, y, remaining, bucket, displayColor)
        │                                               ^^^^^^^^^^^^^
        │                                          NOVO PARAMETRO
        │
        ├── if isPaused:
        │     drawPausedLabel(dc, x, pausedLabelY)
        │
        └── SessionPills.draw(dc, x, pillsY, total, completed, size, spacing)
              (inalterado)
```

---

## 7. Referencias para o plan.md

O plan.md deve ler:
- Este PRD (`tasks/01-prototipos-visuais/03-tela-pausa/prd.md`)
- `source/views/TimerView.mc` (estado atual)
- `source/ui/components/TimerDisplay.mc` (interface a alterar)
- `source/ui/layout/Colors.mc` (adicionar constantes)
- `source/ui/layout/Dimensions.mc` (adicionar funcao)
- `source/delegates/HomeDelegate.mc` (adicionar demo state)
- `resources/strings/strings.xml` (adicionar string)
- `references/design_system.md` §2.2 (tabela de cores por estado)

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeca gerar plan.md.