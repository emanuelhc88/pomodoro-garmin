# Task 01-04: Tela Fim de Sessão (Phase Transition + Cycle Complete)

## Objetivo

Implementar duas telas conceitualmente próximas:
- **P5 (Phase Transition)** — tela curta de 3s anunciando próxima fase ("BREAK", "FOCUS", "LONG BREAK").
- **P6 (Cycle Complete)** — tela final do ciclo com contagem do dia e CTAs.

Visual estático, sem timing automático real (vamos simular a transição manualmente via Enter para validar visualmente).

## Tipo

- [x] Protótipo Visual

## Cobre

- **P5** (Phase Transition) — `spec/spec.md` §2.P5
- **P6** (Cycle Complete) — `spec/spec.md` §2.P6
- **C5** PrimaryButton, **C4** PhaseLabel (versão grande)

## Dependências

- `tasks/01-prototipos-visuais/02-tela-timer-rodando.md`.
- `tasks/01-prototipos-visuais/03-tela-pausa.md`.

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets sem crash.
- [ ] `--typecheck=Strict` passa.

### Manual — P5 (Phase Transition)

- [ ] Tela ocupa toda área visível com fundo `bg`.
- [ ] PhaseLabel gigante (FONT_NUMBER_HOT ou FONT_LARGE muito grande, depende do bucket) centralizado.
- [ ] Cor do texto = cor da fase começando (brand=Focus, textMuted=Break, accent=Long Break).
- [ ] Hint pequeno abaixo: "Session 2 of 4" / "Sessão 2 de 4".
- [ ] Auto-dismiss após 3s (usar Timer.Timer one-shot).
- [ ] Qualquer input (Enter, tap, Back) também dismissa imediatamente.

### Manual — P6 (Cycle Complete)

- [ ] Heading "CYCLE COMPLETE" / "CICLO COMPLETO" no topo, cor `accent`, FONT_MEDIUM.
- [ ] Número grande no centro: `4 / 4`. FONT_NUMBER_HOT.
- [ ] Linha "Today: 8 sessions" / "Hoje: 8 sessões" abaixo, FONT_TINY, `textMuted`.
- [ ] PrimaryButton "Start again" / "Recomeçar" — fundo `brand`, texto `textPrimary`. Em foco por default.
- [ ] PrimaryButton "Done" / "Pronto" — outline `border`, texto `textMuted`.
- [ ] Up/Down alterna foco entre os 2 botões.
- [ ] Enter no botão focado: log + popView (TODO real action).
- [ ] Layout não corta em small bucket (FR255S).

## Arquivos esperados

### Novos

- `source/views/PhaseTransitionView.mc`
- `source/delegates/PhaseTransitionDelegate.mc`
- `source/views/CycleCompleteView.mc`
- `source/delegates/CycleCompleteDelegate.mc`
- `source/ui/components/PrimaryButton.mc`

### Modificados

- `source/delegates/HomeDelegate.mc` — adicionar 2 novos modos de demo: pushView de PhaseTransitionView e pushView de CycleCompleteView.
- `resources/strings/strings.xml` + `strings_pt.xml` — adicionar `cycle_complete_title`, `today_sessions` (com placeholder %d), `start_again`, `done`, `session_n_of_m`.
- `resources/drawables/dimensions.xml` (+ small/large) — adicionar `phaseGiantFontMargin`, `cycleCompleteHeadingY`, `cycleCompleteNumberY`, `cycleCompleteCounterY`, `cycleCompleteButton1Y`, `cycleCompleteButton2Y`.

## Referências obrigatórias

- `references/architecture.md` §3.
- `references/design_system.md` §5.4 (PrimaryButton), §5.5 (PhaseLabel), §6.2 mockup Cycle Complete.
- `references/garmin_platform.md` §2.1 (Timer.Timer one-shot para auto-dismiss).
- `spec/spec.md` §2.P5, §2.P6.

## Notas de design

### P5 — Auto-dismiss

```monkeyc
class PhaseTransitionView extends Ui.View {
    private var _dismissTimer as Timer.Timer?;

    function onShow() {
        _dismissTimer = new Timer.Timer();
        _dismissTimer.start(method(:dismiss), 3000, false);
    }

    function dismiss() as Void {
        if (_dismissTimer != null) {
            _dismissTimer.stop();
            _dismissTimer = null;
        }
        Ui.popView(Ui.SLIDE_LEFT);
    }

    function onHide() {
        if (_dismissTimer != null) {
            _dismissTimer.stop();
            _dismissTimer = null;
        }
    }
}
```

Delegate intercepta input e chama `dismiss()`.

### P5 — Texto gigante

Em medium (260×260):
- FONT_NUMBER_HOT mostra texto numérico grande, mas pode ser usado para letras com `dc.drawText`.
- Alternativa: usar `FONT_LARGE` mas em strings curtas tipo "BREAK" parece pequeno.
- **Decisão:** começar com FONT_NUMBER_HOT, ajustar visualmente.

### P6 — PrimaryButton

Componente reutilizável:

```monkeyc
class PrimaryButton {
    function initialize(label, x, y, w, h);
    function draw(dc, isFocused as Boolean);
    // Focused = fundo brand + texto textPrimary
    // Unfocused = outline border + texto textMuted
}
```

Usar `dc.fillRoundedRectangle` para fundo, `dc.drawRoundedRectangle` para outline. `radius = 8` (Rez.Dimensions.cardRadius).

### P6 — Layout small bucket

Em FR255S (218×218), todos os elementos não cabem confortavelmente. Estratégia:
- Encolher heading para FONT_TINY.
- Encolher número para FONT_NUMBER_MEDIUM.
- Botões em coluna com altura reduzida.
- Se ainda não couber, omitir hint "Today: %d sessions" no small bucket.

Documentar a decisão no `design_system.md` se for omissão.

## Out of scope desta task

- Lógica real de transição (vai pra `02-04-pausa-resume-stop` e relacionadas).
- Persistência de contagem diária (`02-05-contador-sessoes`).
- ActivityRecording stop/save (`02-10-fit-activity-recording`).
