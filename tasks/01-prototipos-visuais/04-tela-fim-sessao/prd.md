# PRD — Task 01-04: Tela Fim de Sessão (Phase Transition + Cycle Complete)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar duas telas estáticas de protótipo visual:
- **P5 (PhaseTransitionView)** — tela fullscreen com texto gigante da próxima fase, auto-dismiss via Timer.Timer one-shot (3s), qualquer input dispensa imediatamente.
- **P6 (CycleCompleteView)** — tela de conclusão com heading, número grande, contador de sessões, e dois PrimaryButtons navegáveis por Up/Down.

Ambas são navegáveis via demo no HomeDelegate (novos modos adicionados ao ciclo de Enter).

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que serve |
|---|---|
| `source/ui/layout/Bucket.mc` | `Bucket.detect()` retorna `:small`, `:medium`, `:large` |
| `source/ui/layout/Colors.mc` | Todas as cores: `BG`, `BRAND`, `ACCENT`, `TEXT_PRIMARY`, `TEXT_MUTED`, `BORDER` |
| `source/ui/layout/Dimensions.mc` | Pattern de dimensões por bucket (adicionar novas funções) |
| `source/ui/components/PhaseLabel.mc` | Base para label de fase — mas P5 precisa de versão "gigante" (font diferente), reutilizar o pattern mas não a mesma função |
| `source/delegates/HomeDelegate.mc` | Pattern de demo cycling (já faz cycle de 4 TimerViews; expandir para incluir P5 e P6) |
| `source/delegates/TimerDelegate.mc` | Pattern de delegate simples com `onBack` → popView |
| `source/views/TimerView.mc` | Pattern de View: `onUpdate` limpa dc, pega bucket, desenha componentes via módulos |

### 2.2 Assets disponíveis

- Nenhum asset gráfico adicional necessário (tudo é texto + primitivas geométricas).
- Fontes nativas Garmin: `FONT_NUMBER_HOT` para texto gigante P5, `FONT_NUMBER_MEDIUM` para número P6.
- Strings existentes: `phase_focus`, `phase_break`, `phase_long_break` (reutilizáveis na P5).

### 2.3 Approach de implementação

**Decisão:** seguir o mesmo pattern das tasks anteriores — Views como classes extends `Ui.View`, Delegates como classes extends `Ui.BehaviorDelegate`, componentes como módulos stateless em `source/ui/components/`.

Para P5:
- `PhaseTransitionView` cria um `Timer.Timer` one-shot de 3s no `onShow` e faz `popView` no callback.
- `PhaseTransitionDelegate` intercepta `onSelect`, `onBack`, `onKey` — qualquer input chama `dismiss()`.
- A View recebe por parâmetro o `phase` (`:focus`, `:break`, `:long_break`) e exibe o texto/cor correspondente.

Para P6:
- `CycleCompleteView` recebe dados estáticos: `completedCycles`, `totalCycles`, `todaySessions`.
- Renderiza heading, número, hint, e dois botões via novo componente `PrimaryButton`.
- `CycleCompleteDelegate` gerencia foco entre 2 botões (Up/Down alterna, Enter ativa).

Para PrimaryButton:
- Módulo stateless: `PrimaryButton.draw(dc, x, y, w, h, label, isFocused, bucket)`.
- Focused: `fillRoundedRectangle` com `brand` + texto `textPrimary`.
- Unfocused: `drawRoundedRectangle` com `border` + texto `textMuted`.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `Toybox.Timer.Timer` | Auto-dismiss P5 (3s one-shot) | `start(callback as Method, period as Number, repeat as Boolean)` |
| `Toybox.Timer.Timer.stop()` | Cancelar timer no `onHide` ou dismiss manual | `stop() as Void` |
| `Toybox.WatchUi.popView` | Sair de P5/P6 | `popView(transition as Number) as Void` |
| `Toybox.WatchUi.pushView` | Demo navigation do HomeDelegate | `pushView(view, delegate, transition)` |
| `Toybox.Graphics.Dc.fillRoundedRectangle` | Fundo do PrimaryButton | `fillRoundedRectangle(x, y, w, h, radius)` |
| `Toybox.Graphics.Dc.drawRoundedRectangle` | Outline do PrimaryButton | `drawRoundedRectangle(x, y, w, h, radius)` |

Fonte: `references/garmin_platform.md` §2.1 (Timer), §2.6 (BehaviorDelegate).

### 2.5 Cores/dimensões/strings necessárias

**Cores (já existem em Colors.mc):**
- P5: `BG` (fundo), cor da fase para texto (`BRAND` = Focus, `TEXT_MUTED` = Break, `ACCENT` = Long Break).
- P6: `BG` (fundo), `ACCENT` (heading), `TEXT_PRIMARY` (número), `TEXT_MUTED` (hint/botão unfocused), `BRAND` (botão focused bg), `BORDER` (botão unfocused outline).

**Dimensões (novas funções em Dimensions.mc):**

| Função | Small | Medium | Large | Uso |
|---|---|---|---|---|
| `phaseGiantY` | 85 | 110 | 180 | Y do texto gigante P5 |
| `phaseHintY` | 130 | 160 | 260 | Y do hint "Session N of M" P5 |
| `cycleHeadingY` | 20 | 30 | 50 | Y do heading P6 |
| `cycleNumberY` | 55 | 75 | 130 | Y do número grande P6 |
| `cycleTodayY` | 100 | 130 | 220 | Y do hint "Today: X sessions" P6 |
| `cycleButton1Y` | 130 | 165 | 280 | Y do primeiro botão P6 |
| `cycleButton2Y` | 160 | 200 | 340 | Y do segundo botão P6 |
| `buttonWidth` | 130 | 160 | 240 | Largura do PrimaryButton |
| `buttonHeight` | 26 | 30 | 44 | Altura do PrimaryButton |

**Strings (novas em strings.xml):**

| Key | EN | PT |
|---|---|---|
| `cycle_complete_title` | CYCLE COMPLETE | CICLO COMPLETO |
| `session_n_of_m` | Session %1$d of %2$d | Sessão %1$d de %2$d |
| `today_sessions` | Today: %d sessions | Hoje: %d sessões |
| `start_again` | Start again | Recomeçar |
| `done` | Done | Pronto |

---

## 3. Decisões a tomar

### 3.1 Fonte do texto gigante em P5

**Opções:**
- A) `FONT_NUMBER_HOT` — fonte numérica muito grande, funciona com letras mas espaçamento pode ser irregular.
- B) `FONT_LARGE` — sans-serif legível mas menor que o desejado para impacto visual.

**Recomendação:** A (`FONT_NUMBER_HOT`). A task já sugere isso. "BREAK" e "FOCUS" são strings curtas (5-10 chars) que cabem. Para `:small` bucket, usar `FONT_NUMBER_MEDIUM` como fallback.

**Justificativa:** O propósito da P5 é impacto visual — a transição é efêmera (3s), precisa ser imediatamente legível. Tamanho >> elegância neste caso.

### 3.2 "LONG BREAK" pode não caber em FONT_NUMBER_HOT no small bucket

**Opções:**
- A) Usar "LONG BREAK" mesmo, e aceitar truncamento se não couber.
- B) Usar "L.BREAK" ou abreviação no small.
- C) Reduzir a fonte para `FONT_LARGE` quando o texto é "LONG BREAK" no small bucket.

**Recomendação:** C. Checar comprimento do texto vs width disponível. Se `LONG BREAK` com `FONT_NUMBER_HOT` excede a largura do `:small` bucket (218px), usar `FONT_LARGE` como fallback apenas para essa string nesse bucket.

**Justificativa:** Manter texto íntegro é prioridade (spec pede o texto completo), e reduzir a fonte preserva legibilidade sem inventar abreviações fora do design system.

### 3.3 Layout do PrimaryButton como módulo vs classe

**Opções:**
- A) Módulo stateless (`PrimaryButton.draw(...)`) — consistente com `TimerRing`, `PhaseLabel`, `SessionPills`.
- B) Classe com `initialize(x, y, w, h, label)` e `draw(dc, isFocused)` — como sugere a task.

**Recomendação:** A (módulo). Toda a codebase usa módulos stateless para componentes. Manter consistência. O foco (focused/unfocused) é passado como parâmetro.

**Justificativa:** Consistência arquitetural. Estado de foco pertence à View/Delegate, não ao componente.

### 3.4 Navegação do demo no HomeDelegate

**Opções:**
- A) Adicionar P5 e P6 ao array de cycling existente (expandir o `_demoIdx` cycle de 4 para 6+).
- B) Mapeamento baseado no preset selecionado: item 4 → P5, item 5 (Settings) → P6.

**Recomendação:** A. Expandir o cycle: após os 4 states de timer, adicionar 3 P5 variants (Focus, Break, Long Break) e 1 P6. Total: 8 demo views.

**Justificativa:** Permite validar todas as variantes em sequência sem navegar no menu. Coerente com o pattern estabelecido na task anterior.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | `FONT_NUMBER_HOT` pode não renderizar letras corretamente em todos devices (é otimizada para números) | Validar no simulador FR255. Se falhar, fallback para `FONT_LARGE` |
| 2 | `fillRoundedRectangle` / `drawRoundedRectangle` pode não existir em SDK antigo | Confirmar que SDK 4.1+ suporta (sim, existe desde SDK 3.x). Usar `has` check se necessário |
| 3 | Timer.Timer callback no `PhaseTransitionView` pode falhar se View já sofreu `popView` de outro input | No callback `dismiss()`, checar se timer não é null antes de parar. Limpar no `onHide`. Pattern idêntico ao sugerido na task |
| 4 | Layout P6 pode não caber no small bucket (218×218) com todos os elementos | Omitir hint "Today: X sessions" no `:small` bucket, como sugere a task |
| 5 | Formatação de `session_n_of_m` com 2 placeholders pode exigir `Lang.format` diferente | Usar `Lang.format("$1$ $2$ $3$", [prefix, n, suffix])` ou similar |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `source/views/PhaseTransitionView.mc` | Criar | View P5: fundo bg, texto gigante, hint, Timer 3s |
| `source/delegates/PhaseTransitionDelegate.mc` | Criar | Input P5: qualquer input → dismiss |
| `source/views/CycleCompleteView.mc` | Criar | View P6: heading, número, hint, 2 botões |
| `source/delegates/CycleCompleteDelegate.mc` | Criar | Input P6: Up/Down foco, Enter ativa, Back = Done |
| `source/ui/components/PrimaryButton.mc` | Criar | Módulo: draw botão (filled ou outline) |
| `source/delegates/HomeDelegate.mc` | Modificar | Expandir demo cycling para incluir P5 e P6 |
| `source/ui/layout/Dimensions.mc` | Modificar | Adicionar funções P5/P6 |
| `resources/strings/strings.xml` | Modificar | Adicionar 5 novas strings |

---

## 6. Arquitetura do fluxo

```
HomeDelegate.onSelect() (demo mode)
    │
    ├── idx 0-3: pushView(TimerView) [existente]
    │
    ├── idx 4: pushView(PhaseTransitionView(:focus))
    ├── idx 5: pushView(PhaseTransitionView(:break))
    ├── idx 6: pushView(PhaseTransitionView(:long_break))
    │       │
    │       ├── onShow(): Timer.start(dismiss, 3000, false)
    │       ├── onUpdate(): desenha texto gigante + hint
    │       └── dismiss(): Timer.stop(), popView(SLIDE_LEFT)
    │           ↑ chamado por: timer callback OU delegate (any input)
    │
    └── idx 7: pushView(CycleCompleteView(4, 4, 8))
            │
            ├── onUpdate(): heading + número + hint + 2 botões
            └── CycleCompleteDelegate:
                ├── onPreviousPage(): focusIdx = 0 (Start again)
                ├── onNextPage(): focusIdx = 1 (Done)
                ├── onSelect(): log + popView
                └── onBack(): popView (= Done)
```

---

## 7. Referências para o plan.md

- `tasks/01-prototipos-visuais/04-tela-fim-sessao.md` — spec da task completa.
- `references/architecture.md` §3 — separação View/Delegate/Component.
- `references/design_system.md` §2.2 (cores por estado), §3.2 (fontes por bucket), §5.4 (PrimaryButton), §5.5 (PhaseLabel), §6.2 (mockup Cycle Complete).
- `references/garmin_platform.md` §2.1 (Timer.Timer one-shot).
- `spec/spec.md` §2.P5, §2.P6.
- `source/views/TimerView.mc` — pattern de implementação de View.
- `source/delegates/HomeDelegate.mc` — pattern de demo cycling.
- `source/ui/layout/Dimensions.mc` — pattern de dimensões por bucket.

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeça gerar plan.md.