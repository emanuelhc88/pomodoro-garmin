# Task 01-06: Tela Custom Builder

## Objetivo

Implementar a **P2 (Custom Builder)**: tela com 3 linhas editáveis (WORK, BREAK, CYCLES) que permite ao usuário ajustar os valores do preset Custom. Visual completo + lógica de navegação/edição local — persistência fica para a task de Properties (02-08).

## Tipo

- [x] Protótipo Visual
- [x] Comportamento (lógica local — navegação e edição)

## Cobre

- **P2** (Custom Builder) — `spec/spec.md` §2.P2
- **B2** Construir preset personalizado — `spec/spec.md` §4.B2 (parcial — sem persistência)
- **C9** Spec Line, **C10** Hints rodapé

## Dependências

- `tasks/01-prototipos-visuais/05-tela-presets.md` (Preset.mc existente).

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets.
- [ ] `--typecheck=Strict` passa.

### Manual

- [ ] Tela mostra 3 linhas: WORK (25 min), BREAK (5 min), CYCLES (4).
- [ ] Up/Down navega entre as 3 linhas (highlight = `accent`).
- [ ] Enter na linha selecionada entra em "edit mode" (highlight muda para piscar ou cor diferente — definir na implementação).
- [ ] Em edit mode, Up/Down ajusta valor com passo correto:
  - WORK: ±5 min, range 5–90.
  - BREAK: ±1 min, range 1–30.
  - CYCLES: ±1, range 1–10.
- [ ] Enter em edit mode confirma e volta ao modo navigation.
- [ ] Back em edit mode cancela edição (volta valor anterior).
- [ ] Back em navigation mode volta para Home (P1).
- [ ] Hints no rodapé mudam conforme contexto: navigation ("UP/DOWN to select · ENTER to edit") vs edit ("UP/DOWN to change · ENTER to confirm").
- [ ] Em FR265 (touch), tap na linha entra em edit mode.
- [ ] Layout cabe no small bucket (FR255S) — ver notas.

## Arquivos esperados

### Novos

- `source/views/CustomBuilderView.mc`
- `source/delegates/CustomBuilderDelegate.mc`
- `source/ui/components/SpecLine.mc` — componente que renderiza uma linha "LABEL : valor".
- `source/ui/components/Hints.mc` — componente que renderiza dicas de input no rodapé.

### Modificados

- `source/delegates/HomeDelegate.mc` — `onSelect` para preset Custom: pushView de CustomBuilderView (em vez de TimerView). Para outros presets, mantém TimerView demo.
- `resources/strings/strings.xml` + `strings_pt.xml`:
  - `custom_builder_title` ("Custom" / "Personalizado")
  - `custom_label_work` ("WORK" / "FOCO")
  - `custom_label_break` ("BREAK" / "PAUSA")
  - `custom_label_cycles` ("CYCLES" / "CICLOS")
  - `unit_min` ("min" / "min")
  - `hints_navigation` ("UP/DOWN to select · ENTER to edit" / "UP/DOWN para mover · ENTER para editar")
  - `hints_edit` ("UP/DOWN to change · ENTER to confirm" / "UP/DOWN para mudar · ENTER para confirmar")
- `resources/drawables/dimensions.xml` — `customLineHeight`, `customLine1Y`, `customLine2Y`, `customLine3Y`, `hintsY`.
- `source/model/Preset.mc` — adicionar limites como constantes:
  ```monkeyc
  const WORK_MIN_MIN = 5;
  const WORK_MIN_MAX = 90;
  const WORK_MIN_STEP = 5;
  // ...
  ```

## Referências obrigatórias

- `references/architecture.md` §3 (View vs Delegate).
- `references/design_system.md` §5 (componentes), §7 (strings).
- `spec/spec.md` §2.P2, §6 (regras de negócio).

## Notas de design

### Layout (medium 260×260)

```
   ┌───────────────────────┐
   │       Custom          │  ← título FONT_TINY, textMuted
   │                       │
   │   WORK    25 min  ←   │  ← selected (accent)
   │   BREAK    5 min      │
   │   CYCLES   4          │
   │                       │
   │   UP/DOWN to select   │  ← hints (FONT_XTINY)
   │   ENTER to edit       │
   └───────────────────────┘
```

### State machine local

```
[NAVIGATING] ── enter ─→ [EDITING_WORK] ── enter ─→ [NAVIGATING]
                                  ↑                     │
                                  └──── back ───────────┘
```

`CustomBuilderView` mantém:
- `_selectedLine: Number` (0=work, 1=break, 2=cycles)
- `_editing: Boolean`
- `_workMin, _breakMin, _cycles: Number` (working values)
- `_originalValues: Dict` (para Back em edit cancelar)

### Layout small bucket (218×218)

Apertado. Estratégia:
- Esconder título "Custom" (já estava na home).
- Reduzir hints para 1 linha apenas.
- Linhas com altura menor.
- Se ainda apertado, hints em FONT_XTINY ou rotativo.

### Edição com touch (AMOLED)

- Tap em linha: seleciona + entra em edit.
- Tap em valor (área específica): mesma coisa.
- Em edit mode: swipe up = +, swipe down = -.

## Out of scope desta task

- Persistência (`02-08-persistencia-settings`).
- Validação de input com mensagens de erro UI (nesta task, apenas clamp silencioso aos limites).
