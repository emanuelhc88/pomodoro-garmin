# Task 01-02: Tela Timer Rodando

## Objetivo

Implementar a **P3 (Timer Running)** como protótipo visual estático: anel circular de progresso + display MM:SS + phase label + session pills. Ainda **sem** loop de timer real — vamos passar valores hardcoded (ex: 14:23 progresso 50%) para validar a visualização.

## Tipo

- [x] Protótipo Visual

## Cobre

- **P3** (Timer Running) — `spec/spec.md` §2.P3
- **C1** TimerRing, **C2** TimerDisplay, **C3** SessionPills, **C4** PhaseLabel — `spec/spec.md` §3

## Dependências

- `tasks/01-prototipos-visuais/01-tela-home.md` (scaffold + colors + dimensions já criados).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings em `monkeyc -d fr255`, `-d fr265`, `-d fr255s`.
- [ ] Roda nos simuladores acima sem crash.
- [ ] `--typecheck=Strict` passa.

### Manual

- [ ] Anel circular desenhado partindo do topo (12h), preenchendo sentido horário.
- [ ] Cor do anel reflete estado (testar 3 valores hardcoded: brand=Work, textMuted=Break, accent=LongBreak).
- [ ] Espessura do anel correta por bucket (small=6px, medium=8px, large=12px).
- [ ] MM:SS centralizado, fonte `FONT_NUMBER_THAI_HOT` (medium/large) ou `FONT_NUMBER_MEDIUM` (small).
- [ ] Phase label uppercase ("FOCUS", "BREAK", "LONG BREAK") acima do display.
- [ ] Session pills no rodapé: 4 pills, primeiros 2 preenchidos `brand`, 3º outline `accent` (current), 4º outline `border`.
- [ ] Layout não corta em nenhum bucket.
- [ ] Em FR255S (small), tudo cabe sem overlap.

## Arquivos esperados

### Novos

- `source/views/TimerView.mc`
- `source/delegates/TimerDelegate.mc`
- `source/ui/components/TimerRing.mc`
- `source/ui/components/TimerDisplay.mc`
- `source/ui/components/SessionPills.mc`
- `source/ui/components/PhaseLabel.mc`

### Modificados

- `source/delegates/HomeDelegate.mc` — `onSelect` agora pushView do TimerView com valores hardcoded de teste (ex: phase=`:running_work`, remaining=900s, total=1500s, completedCycles=2, currentCycle=3, totalCycles=4).
- `resources/drawables/dimensions.xml` (+ `resources-small`, `resources-large`) — adicionar `ringRadius`, `ringStroke`, `timerCenterY`, `phaseLabelOffsetY`, `pillsOffsetY`, `pillSize`, `pillSpacing`.
- `resources/strings/strings.xml` + `strings_pt.xml` — adicionar `phase_focus`, `phase_break`, `phase_long_break`.

## Referências obrigatórias

- `references/architecture.md` §3 (View vs Delegate vs Components).
- `references/design_system.md` §5.1 (TimerRing), §5.2 (TimerDisplay), §5.3 (SessionPills), §5.5 (PhaseLabel), §6.2 mockup Timer Running.
- `references/garmin_platform.md` §2.6 (BehaviorDelegate).
- `spec/spec.md` §2.P3.

## Notas de design

### TimerRing — render

Connect IQ Graphics não tem helper direto pra arc-with-progress. Estratégia:

```monkeyc
function drawArc(dc, cx, cy, r, stroke, startDeg, endDeg, color) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(stroke);
    dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, startDeg, endDeg);
}

// Para progresso 0..1, mapear para ângulo (12h = 90deg em coords Garmin):
// startDeg = 90 (topo)
// endDeg = 90 - (progress * 360) (sentido horário em Graphics)
```

Pintar o anel "background" em cor `border` (cinza fino) primeiro, depois o anel "preenchido" por cima.

### Estados (hardcoded para demo)

Adicionar parameter na `TimerView.initialize` que aceita um símbolo de phase. No HomeDelegate, alternar entre 3 valores ao apertar Enter (debug):

```monkeyc
function onSelect() {
    var states = [:running_work, :running_short_break, :running_long_break];
    var idx = (_selectedIndex % 3);
    Ui.pushView(new TimerView(states[idx], 900, 1500, 2, 4),
                new TimerDelegate(),
                Ui.SLIDE_LEFT);
    return true;
}
```

Isso é só para a task de protótipo; a navegação real será refinada na task `02-06-presets-builtin`.

### TimerDelegate — input mínimo

- `onBack`: popView (volta para Home).
- `onSelect`: nada por enquanto (ou log "TODO: pause/resume").

## Out of scope desta task

- Loop de timer real (vai pra `02-02-timer-loop`).
- Pause / Resume / Stop (vai pra `02-04-pausa-resume-stop`).
- Vibração (vai pra `02-03-vibracao-inicio-fim`).
- ActivityRecording (vai pra `02-10-fit-activity-recording`).
- Estado paused (P4 — próxima task).
