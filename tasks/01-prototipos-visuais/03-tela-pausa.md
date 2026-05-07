# Task 01-03: Tela Pausa (Paused state)

## Objetivo

Implementar **P4 (Paused)** como variação visual de **P3 (Timer Running)**. Mesmo layout, mas com:
- Anel desenhado em cor "dim" (versão escurecida da cor da fase).
- Display MM:SS em `textMuted` em vez de `textPrimary`.
- Label adicional "PAUSED" abaixo do display.

Validar com valor hardcoded — sem lógica de timer real ainda.

## Tipo

- [x] Protótipo Visual

## Cobre

- **P4** (Paused) — `spec/spec.md` §2.P4
- Sub-estado dos componentes C1, C2, C3, C4.

## Dependências

- `tasks/01-prototipos-visuais/02-tela-timer-rodando.md`.

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets sem crash.
- [ ] `--typecheck=Strict` passa.

### Manual

- [ ] TimerView aceita um parâmetro `isPaused as Boolean` (ou similar).
- [ ] Quando `isPaused == true`, anel é desenhado em cor "dim" (definir tabela de cor dim por fase em `colors.xml`).
- [ ] Display MM:SS muda para `textMuted` (`#888`) quando pausado.
- [ ] Phase label permanece visível mas em `textMuted`.
- [ ] Texto "PAUSED" / "PAUSADO" aparece abaixo do display, fonte `FONT_TINY` ou `FONT_XTINY`, cor `textMuted`.
- [ ] Session pills permanecem visíveis (estado não muda).
- [ ] Layout não tem overlap em nenhum bucket.

## Arquivos esperados

### Novos

- (Nenhum arquivo novo — adicionamos parâmetro a TimerView.)

### Modificados

- `source/views/TimerView.mc` — adicionar param `isPaused`. Em `onUpdate`, escolher cores condicionalmente. Adicionar render do label "PAUSED".
- `source/ui/components/TimerRing.mc` — adicionar versão "dim" da cor passada (helper `dimColor(color)` que escurece percentual).
- `source/ui/components/TimerDisplay.mc` — adicionar param `color`.
- `source/delegates/HomeDelegate.mc` — adicionar quarto estado de demo: `isPaused = true` para teste visual. Ex: `Ui.pushView(new TimerView(:running_work, 900, 1500, 2, 4, true), ...)`.
- `resources/drawables/colors.xml` — adicionar `brandDim`, `accentDim`, `textMutedDim` se necessário (alternativa: derivar em runtime via `Graphics.createColor` ou tabela hex).
- `resources/strings/strings.xml` + `strings_pt.xml` — adicionar `state_paused`.

## Referências obrigatórias

- `references/design_system.md` §2.2 (estados), §6.1 mockup Paused.
- `spec/spec.md` §2.P4.

## Notas de design

### Cor "dim" — opção A: tabela hex pré-calculada

Em `colors.xml`:
```xml
<color id="brandDim">0x6E2017</color>      <!-- ~50% darker do #E8432D -->
<color id="accentDim">0x803624</color>     <!-- ~50% darker do #FF6B47 -->
<color id="textMutedDim">0x444444</color>  <!-- ~50% darker do #888888 -->
```

### Cor "dim" — opção B: helper runtime

```monkeyc
function dimColor(rgb as Number) as Number {
    var r = (rgb >> 16) & 0xFF;
    var g = (rgb >> 8) & 0xFF;
    var b = rgb & 0xFF;
    return ((r >> 1) << 16) | ((g >> 1) << 8) | (b >> 1);
}
```

**Recomendação:** opção A. Garante consistência visual entre devices MIP (que mapeam cores), e evita cálculo em `onUpdate`.

### Layout do label "PAUSED"

Posicionar abaixo do display, mas acima das pills. Em medium bucket:
- Display em `timerCenterY` (ex: y=130).
- "PAUSED" em `timerCenterY + 30` (ex: y=160).
- Pills em `pillsOffsetY` (ex: y=220).

Adicionar dimension `pausedLabelOffsetY` em `dimensions.xml`.

## Out of scope desta task

- Toggle pause/resume real (`02-04-pausa-resume-stop`).
- Confirmação de stop (`02-04`).
