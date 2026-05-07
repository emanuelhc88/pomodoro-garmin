# PRD — Task 01-02: Tela Timer Rodando

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar a página P3 (Timer Running) como protótipo visual estático: anel circular de progresso, display MM:SS, phase label e session pills. Sem loop de timer real — valores hardcoded passados pelo HomeDelegate para validação visual nos 3 buckets (small/medium/large).

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

| Arquivo | O que aproveitar |
|---|---|
| `source/ui/layout/Bucket.mc` | `Bucket.detect()` retorna `:small`, `:medium`, `:large` — usar diretamente nos componentes |
| `source/ui/layout/Colors.mc` | Constantes `Colors.BG`, `Colors.BRAND`, `Colors.ACCENT`, `Colors.TEXT_PRIMARY`, `Colors.TEXT_MUTED`, `Colors.BORDER` |
| `source/ui/layout/Dimensions.mc` | Pattern de funções bucket-aware — estender com funções para timer |
| `source/delegates/HomeDelegate.mc` | Modificar `onSelect()` para pushView do TimerView |
| `source/views/HomeView.mc` | Referência de pattern View (onUpdate com dc) |
| `source/ui/components/Wordmark.mc` | Referência de componente stateless com `draw(dc, ...)` |

### 2.2 Assets disponíveis

- Paleta completa em `Colors.mc` (já implementada na task 01).
- Fontes nativas Garmin (`FONT_NUMBER_THAI_HOT`, `FONT_NUMBER_MEDIUM`, `FONT_MEDIUM`, `FONT_TINY`).
- Nenhum asset gráfico adicional necessário (tudo é desenhado via Graphics API).

### 2.3 Approach de implementação

**Decisão: componentes stateless com método `draw(dc, ...params)`.**

Justificativa:
- Segue o pattern já estabelecido (`Wordmark.draw`, `PresetCard.draw`, `DotsIndicator.draw`).
- Componentes não alocam memória em `onUpdate` — recebem tudo por parâmetro.
- TimerView orquestra: calcula posições e chama cada componente.

**Render do anel circular:**
- `Dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, startAngle, endAngle)` com `setPenWidth(stroke)`.
- Fundo do anel: `Colors.BORDER` (anel completo 360°).
- Progresso: cor da fase desenhada por cima, de 90° (12h) até `90 - (progress * 360)`.

### 2.4 APIs Connect IQ utilizadas

| API | Método | Uso |
|---|---|---|
| `Toybox.Graphics.Dc` | `drawArc(x, y, r, direction, startAngle, endAngle)` | Desenhar anel de progresso |
| `Toybox.Graphics.Dc` | `setPenWidth(width)` | Espessura do anel |
| `Toybox.Graphics.Dc` | `drawText(x, y, font, text, justification)` | MM:SS, phase label |
| `Toybox.Graphics.Dc` | `fillCircle(x, y, radius)` | Session pills preenchidas |
| `Toybox.Graphics.Dc` | `drawCircle(x, y, radius)` | Session pills outline |
| `Toybox.Graphics` | `ARC_CLOCKWISE` | Constante de direção |
| `Toybox.Graphics` | `FONT_NUMBER_THAI_HOT`, `FONT_NUMBER_MEDIUM` | Fonte do timer |
| `Toybox.Graphics` | `FONT_MEDIUM`, `FONT_TINY` | Fonte para labels |
| `Toybox.Graphics` | `TEXT_JUSTIFY_CENTER` | Justificação de texto |
| `Toybox.WatchUi` | `pushView(view, delegate, transition)` | Navegar Home → Timer |
| `Toybox.WatchUi` | `popView(transition)` | Voltar Timer → Home |
| `Toybox.WatchUi` | `requestUpdate()` | Forçar re-render (não necessário nesta task sem timer) |

### 2.5 Cores/dimensões/strings necessárias

**Cores por estado (já existem em Colors.mc):**

| Estado | Anel | Label |
|---|---|---|
| `running_work` | `Colors.BRAND` | `Colors.BRAND` |
| `running_short_break` | `Colors.TEXT_MUTED` | `Colors.TEXT_MUTED` |
| `running_long_break` | `Colors.ACCENT` | `Colors.ACCENT` |

**Dimensões novas (adicionar em Dimensions.mc):**

| Função | Small | Medium | Large |
|---|---|---|---|
| `ringRadius(bucket)` | 85 | 100 | 175 |
| `ringStroke(bucket)` | 6 | 8 | 12 |
| `timerCenterY(bucket)` | 109 | 130 | 227 |
| `phaseLabelOffsetY(bucket)` | -48 | -60 | -100 |
| `pillsOffsetY(bucket)` | 75 | 90 | 160 |
| `pillSize(bucket)` | 6 | 8 | 10 |
| `pillSpacing(bucket)` | 3 | 4 | 6 |

**Strings novas:**

| Key | EN | PT (futura) |
|---|---|---|
| `phase_focus` | FOCUS | FOCO |
| `phase_break` | BREAK | PAUSA |
| `phase_long_break` | LONG BREAK | PAUSA LONGA |

---

## 3. Decisões a tomar

### D1. drawArc ângulo de início

**Opções:**
- A) `startAngle = 90` (12h em coordenadas Garmin, onde 0° = 3h e sentido anti-horário é positivo)
- B) `startAngle = 0` (3h)

**Recomendação: A) startAngle = 90.**
Justificativa: spec define "preenche da posição 12h" e a task confirma "anel partindo do topo (12h)". Em Connect IQ, `drawArc` com `ARC_CLOCKWISE` usa ângulo trigonométrico: 90° = 12h.

### D2. SessionPills: quando total > 4

**Opções:**
- A) Sempre pills (até 10)
- B) Pills para ≤ 4, texto "2/8" para > 4 (como no design_system.md §5.3)

**Recomendação: B) Threshold em 4.**
Justificativa: design_system.md §5.3 especifica explicitamente este comportamento. Acima de 4 pills, o espaço horizontal não cabe bem em devices small.

### D3. Font do timer por bucket

**Opções:**
- A) `FONT_NUMBER_THAI_HOT` para todos
- B) `FONT_NUMBER_THAI_HOT` para medium/large, `FONT_NUMBER_MEDIUM` para small (como na task)

**Recomendação: B) Diferenciado por bucket.**
Justificativa: task e design_system.md §3.3 especificam isso explicitamente. `FONT_NUMBER_THAI_HOT` pode não caber no bucket small (218px).

### D4. Valores hardcoded para demo

**Recomendação:** No HomeDelegate, ao pressionar Enter, alternar ciclicamente entre 3 estados:
1. `:running_work` — remaining=900, total=1500, completed=2, total_cycles=4
2. `:running_short_break` — remaining=180, total=300, completed=2, total_cycles=4
3. `:running_long_break` — remaining=420, total=600, completed=3, total_cycles=4

Isso testa todas as variantes visuais conforme a task exige.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| 1 | `drawArc` pode ter comportamento diferente entre SDK versions para ângulos | Testar no simulador FR255 + FR265. Se necessário, calcular endAngle com `mod 360` |
| 2 | `FONT_NUMBER_THAI_HOT` pode não existir em todos devices | Fallback para `FONT_NUMBER_MEDIUM` se necessário; `Graphics has :FONT_NUMBER_THAI_HOT` check |
| 3 | Anel com `setPenWidth` grande pode ter artefatos em raios pequenos (small bucket) | Reduzir stroke para 6px no small e testar; radius deve ser > 2× stroke |
| 4 | Pills outline com `drawCircle` + `setPenWidth(1)` pode não renderizar corretamente em MIP | Testar no simulador FR255; se necessário, usar `fillCircle` com cor de fundo para simular outline |
| 5 | `timerCenterY` para large (227px) pode não estar centrado verticalmente em devices 390px vs 454px | Calcular centro baseado em `dc.getHeight()/2` em vez de valor fixo; usar offset relativo |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/views/TimerView.mc` | **NOVO** — View P3, orquestra componentes, recebe estado hardcoded |
| `source/delegates/TimerDelegate.mc` | **NOVO** — Input: onBack=popView, onSelect=noop |
| `source/ui/components/TimerRing.mc` | **NOVO** — Desenha anel circular (fundo border + progresso colorido) |
| `source/ui/components/TimerDisplay.mc` | **NOVO** — Renderiza MM:SS centralizado |
| `source/ui/components/SessionPills.mc` | **NOVO** — Desenha pills ou texto "X/Y" |
| `source/ui/components/PhaseLabel.mc` | **NOVO** — Label uppercase da fase |
| `source/delegates/HomeDelegate.mc` | **MODIFICAR** — `onSelect` → pushView TimerView com dados hardcoded |
| `source/ui/layout/Dimensions.mc` | **MODIFICAR** — Adicionar funções ring/timer/pills |
| `resources/strings/strings.xml` | **MODIFICAR** — Adicionar `phase_focus`, `phase_break`, `phase_long_break` |

---

## 6. Arquitetura do fluxo

```
HomeDelegate.onSelect()
    │
    ├── Seleciona estado hardcoded (idx % 3)
    │   ├── :running_work       → ring=BRAND,   label="FOCUS"
    │   ├── :running_short_break → ring=TEXT_MUTED, label="BREAK"
    │   └── :running_long_break  → ring=ACCENT,  label="LONG BREAK"
    │
    └── Ui.pushView(TimerView(...), TimerDelegate(), SLIDE_LEFT)

TimerView.onUpdate(dc)
    │
    ├── dc.clear(BG)
    ├── Calcular posições (bucket + Dimensions)
    │
    ├── PhaseLabel.draw(dc, centerX, labelY, phaseText, phaseColor)
    │
    ├── TimerRing.draw(dc, centerX, centerY, radius, stroke, progress, phaseColor)
    │   ├── drawArc 360° → Colors.BORDER (fundo)
    │   └── drawArc progress → phaseColor (preenchido)
    │
    ├── TimerDisplay.draw(dc, centerX, centerY, remainingSeconds, font)
    │   └── Format "MM:SS" → drawText centered
    │
    └── SessionPills.draw(dc, centerX, pillsY, totalCycles, completedCycles)
        ├── if total <= 4: draw circles
        │   ├── completed → fillCircle(BRAND)
        │   ├── current   → fillCircle(ACCENT)
        │   └── future    → drawCircle(BORDER)
        └── if total > 4: drawText "completed/total"

TimerDelegate.onBack()
    └── Ui.popView(SLIDE_RIGHT)
```

---

## 7. Referências para o plan.md

- `references/architecture.md` §3 (View vs Delegate vs Components)
- `references/design_system.md` §5.1–5.3, §5.5, §6.2
- `spec/spec.md` §2.P3, §3 (C1–C4)
- `references/garmin_platform.md` §2.6 (BehaviorDelegate)
- Task file: `tasks/01-prototipos-visuais/02-tela-timer-rodando.md`
- Código existente: `source/ui/layout/Dimensions.mc`, `source/delegates/HomeDelegate.mc`

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação (D1–D4).
- [x] Riscos identificados com mitigação (5 riscos).
- [x] Arquivos listados com responsabilidade clara (6 novos + 3 modificados).
- [x] Fluxo de dados documentado (seção 6).
- [x] Strings e cores mapeadas (seção 2.5).
- [x] Nenhuma ambiguidade que impeça gerar plan.md.