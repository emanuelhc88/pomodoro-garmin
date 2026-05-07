# PRD — Task 01-06: Tela Custom Builder

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Implementar a pagina P2 (Custom Builder): tela com 3 linhas editaveis (WORK, BREAK, CYCLES) que permite navegar entre linhas, entrar em modo edicao, ajustar valores com Up/Down, e confirmar/cancelar. Inclui dois novos componentes reutilizaveis (SpecLine, Hints) e a logica completa de navegacao/edicao local — sem persistencia.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que serve |
|---|---|
| [source/model/Preset.mc](source/model/Preset.mc) | Classe `Preset` com campos `workMin`, `breakMin`, `cycles`, `isCustom`. Sera estendida com constantes de limites/step. |
| [source/delegates/HomeDelegate.mc](source/delegates/HomeDelegate.mc) | Ponto de integracao: `onSelect` para o preset Custom (indice 3) deve pushView para CustomBuilderView em vez de TimerView. |
| [source/ui/layout/Colors.mc](source/ui/layout/Colors.mc) | Paleta completa: `ACCENT` (highlight), `TEXT_PRIMARY` (valor), `TEXT_MUTED` (labels inativos), `BG` (fundo). |
| [source/ui/layout/Dimensions.mc](source/ui/layout/Dimensions.mc) | Pattern de funcoes responsivas por bucket. Novas dimensoes serao adicionadas aqui. |
| [source/ui/layout/Bucket.mc](source/ui/layout/Bucket.mc) | `Bucket.detect()` retorna `:small`, `:medium`, `:large`. |
| [source/ui/components/PrimaryButton.mc](source/ui/components/PrimaryButton.mc) | Referencia de pattern — modulo com `draw()` estatico recebendo dc + params. SpecLine e Hints seguem o mesmo padrao. |
| [source/ui/components/Wordmark.mc](source/ui/components/Wordmark.mc) | Pattern de componente minimal — fonte por bucket, cor estatica. |

### 2.2 Assets disponiveis

- Fontes nativas: `FONT_MEDIUM` para labels, `FONT_NUMBER_MEDIUM` para valores numericos, `FONT_TINY`/`FONT_XTINY` para hints e titulo.
- Paleta completa em `Colors.mc` — nenhuma cor nova necessaria.
- Nenhum icone/imagem necessario para esta tela.

### 2.3 Approach de implementacao

**Decisao: View com state machine local (NAVIGATING / EDITING) + Delegate que mapeia inputs para mutacoes de estado na View.**

Justificativa:
- A task e hibrida (visual + comportamento local). A View mantem estado de UI (`_selectedLine`, `_editing`, `_workMin`, `_breakMin`, `_cycles`) porque nao ha Model envolvido ainda.
- O Delegate interpreta Up/Down/Enter/Back contextualmente (modo navigating vs editing) e chama metodos na View.
- Componentes `SpecLine` e `Hints` sao modulos stateless (como PrimaryButton) — recebem dc + params e desenham.
- Para a integracao com Home, o preset Custom (indice 3) faz pushView para CustomBuilderView. Os demais mantem o comportamento demo atual.
- Persistencia fica para task 02-08 — nesta task, os valores iniciam em defaults (25/5/4) e sao perdidos ao sair.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `WatchUi.BehaviorDelegate` | Delegate para inputs | `onSelect()`, `onPreviousPage()`, `onNextPage()`, `onBack()` retornam `Boolean` |
| `WatchUi.pushView(view, delegate, transition)` | Navegacao Home → CustomBuilder | `pushView(view as View, delegate as BehaviorDelegate, transition as Symbol) as Void` |
| `WatchUi.popView(transition)` | Voltar para Home | `popView(transition as Symbol) as Void` |
| `WatchUi.requestUpdate()` | Forcar re-render apos mudanca de estado | `requestUpdate() as Void` |
| `Graphics.Dc.drawText(x, y, font, text, justify)` | Renderizar labels/valores/hints | Padrao Dc |
| `Graphics.Dc.fillRectangle(x, y, w, h)` | Highlight da linha selecionada (background accent) | Padrao Dc |
| `WatchUi.loadResource(id)` | Carregar strings | `loadResource(id as Symbol) as Object` |
| `Lang.format(pattern, args)` | Formatar "25 min" | `format(format as String, args as Array) as String` |

### 2.5 Cores/dimensoes/strings necessarias

**Cores (ja existem em Colors.mc):**

| Token | Uso nesta tela |
|---|---|
| `ACCENT` (0xFF6B47) | Linha selecionada em modo navigating |
| `BRAND` (0xE8432D) | Linha em modo editing (indica edicao ativa) |
| `TEXT_PRIMARY` (0xF5F0EB) | Valor da linha selecionada |
| `TEXT_MUTED` (0x888888) | Labels de linhas inativas, titulo, hints |
| `BG` (0x0C0C0C) | Fundo |
| `BORDER` (0x2A2A2A) | Highlight bar background (sutil) |

**Dimensoes (novas, em Dimensions.mc):**

| Funcao | Small | Medium | Large | Uso |
|---|---|---|---|---|
| `customTitleY` | — (oculto) | 25 | 40 | Y do titulo "Custom" |
| `customLineHeight` | 38 | 48 | 70 | Altura de cada linha (SpecLine) |
| `customLine1Y` | 40 | 60 | 90 | Y da primeira linha (WORK) |
| `customLineSpacing` | 4 | 8 | 12 | Espaco entre linhas |
| `customHintsY` | 170 | 210 | 360 | Y das hints no rodape |
| `customLabelX` | 20 | 30 | 50 | X do label (alinhado esquerda) |
| `customValueX` | 198 | 230 | 370 | X do valor (alinhado direita) |

**Strings (novas):**

| Key | EN | PT |
|---|---|---|
| `custom_builder_title` | Custom | Personalizado |
| `custom_label_work` | WORK | FOCO |
| `custom_label_break` | BREAK | PAUSA |
| `custom_label_cycles` | CYCLES | CICLOS |
| `unit_min` | min | min |
| `hints_nav` | SELECT to edit | SELECT p/ editar |
| `hints_edit` | SELECT to confirm | SELECT p/ confirmar |

**Nota sobre hints:** strings curtas (3-4 palavras) para caber no small bucket. Up/Down e implicito pelo contexto fisico dos botoes.

---

## 3. Decisoes a tomar

### D1. Highlight visual da linha em edicao

| Opcao | Descricao | Recomendacao |
|---|---|---|
| A) Cor diferente (BRAND vs ACCENT) | Navigating = ACCENT, Editing = BRAND. Facil, sem piscada. | **Recomendado** |
| B) Piscar (blink) a linha | Usa timer auxiliar para alternar visibilidade. Mais complexo, consome Timer extra. | Rejeitado |
| C) Underline no valor | Sublinhado abaixo do numero. Sutil em small bucket. | Rejeitado |

**Justificativa:** Opcao A usa cores ja existentes, distingue claramente os 2 modos sem complexidade de timer. ACCENT = "voce esta aqui", BRAND = "voce esta editando".

### D2. Indicador de seta no valor em edicao

| Opcao | Descricao | Recomendacao |
|---|---|---|
| A) Setas textuais (triangulos Unicode) | Renderizar "▲ 25 ▼" em modo edit. Universal, funciona em qualquer font. | **Recomendado** |
| B) Sem setas (apenas cor) | Mais limpo, mas menos affordance de que up/down funciona. | Alternativa viavel |

**Justificativa:** Setas textuais reforçam affordance de edicao sem necessidade de assets extras. Em small bucket, pode-se omitir as setas e usar apenas a cor como indicador.

### D3. Comportamento do Back em modo NAVIGATING

| Opcao | Descricao | Recomendacao |
|---|---|---|
| A) popView direto (volta para Home) | Valores editados sao perdidos (sem persistencia nesta task). | **Recomendado** |
| B) Confirmacao antes de sair | Excesso para esta task (sem persistencia, nao ha "perda" real). | Rejeitado |

**Justificativa:** Sem persistencia nesta task, nao ha risco de perder dados. Simplicidade.

### D4. Layout no small bucket (218x218)

| Opcao | Descricao | Recomendacao |
|---|---|---|
| A) Ocultar titulo, hint em 1 linha | Ganha ~40px de espaço vertical. Linhas ficam mais proximas do centro. | **Recomendado** |
| B) Mostrar tudo com fontes menores | Pode ficar ilegivel em FONT_XTINY. | Rejeitado |

**Justificativa:** O titulo "Custom" e redundante (usuario acabou de sair da Home onde estava em "Custom"). Ocultar em small maximiza espaco util.

### D5. Touch (devices AMOLED com touch)

| Opcao | Descricao | Recomendacao |
|---|---|---|
| A) Tap na linha = seleciona + edita | Simplifica: 1 tap entra direto em edit. | **Recomendado** |
| B) Tap seleciona, segundo tap edita | Dois passos para touch. Mais seguro contra toque acidental. | Alternativa |

**Justificativa:** Touch deve ser mais direto. Se o usuario toca na linha, a intencao e editar. Back cancela se foi acidental. Implementacao: sobrescrever `onTap` no Delegate so em devices `:hasTouch` (via annotation ou runtime check).

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | Layout vertical nao cabe em 218x218 com 3 linhas + hints | Ocultar titulo no small; reduzir lineHeight; testar no simulador FR255S |
| 2 | `onTap` pode nao fornecer coordenadas Y suficientemente precisas para detectar qual linha foi tocada | Usar regioes com margem generosa (lineHeight inteira como zona de toque) |
| 3 | Monkey C nao tem enum nativo — representar estado NAVIGATING/EDITING | Usar Boolean `_editing` — simples e suficiente para 2 estados |
| 4 | Triangulos Unicode podem nao renderizar em todas as fontes Garmin nativas | Testar no simulador; fallback: usar "-" e "+" como texto alternativo, ou omitir setas |
| 5 | Integracao com HomeDelegate pode quebrar demo mode existente | Condicionar: so indice 3 (Custom) vai para CustomBuilder; demais mantem demo |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/views/CustomBuilderView.mc` | **NOVO.** View P2: onUpdate renderiza titulo + 3 SpecLines + Hints. Mantem estado local (_selectedLine, _editing, _workMin, _breakMin, _cycles). |
| `source/delegates/CustomBuilderDelegate.mc` | **NOVO.** Delegate P2: mapeia onPreviousPage/onNextPage/onSelect/onBack para acoes na View conforme modo (navigating vs editing). |
| `source/ui/components/SpecLine.mc` | **NOVO.** Modulo stateless: desenha uma linha "LABEL    valor unidade" com highlight se selecionada, cor BRAND se em edicao. |
| `source/ui/components/Hints.mc` | **NOVO.** Modulo stateless: desenha texto de hint no rodape, centralizado, FONT_TINY/XTINY, cor TEXT_MUTED. |
| `source/model/Preset.mc` | **MODIFICADO.** Adicionar constantes de limites e step (WORK_MIN/MAX/STEP, BREAK_MIN/MAX/STEP, CYCLES_MIN/MAX/STEP). |
| `source/delegates/HomeDelegate.mc` | **MODIFICADO.** Condicionar onSelect: se indice == 3 (Custom), pushView CustomBuilderView; demais mantem demo. |
| `source/ui/layout/Dimensions.mc` | **MODIFICADO.** Adicionar funcoes customTitleY, customLineHeight, customLine1Y, customLineSpacing, customHintsY, customLabelX, customValueX. |
| `resources/strings/strings.xml` | **MODIFICADO.** Adicionar 7 strings EN (custom_builder_title, custom_label_work, custom_label_break, custom_label_cycles, unit_min, hints_nav, hints_edit). |
| `resources-por/strings/strings.xml` | **MODIFICADO.** Adicionar 7 strings PT correspondentes. |

---

## 6. Arquitetura do fluxo

```
┌────────────┐    onSelect (idx==3)     ┌─────────────────────────┐
│  HomeView  │ ─────────────────────────>│   CustomBuilderView     │
│  (P1)      │    pushView(SLIDE_LEFT)   │   + CustomBuilderDelegate│
└────────────┘                           └─────────────────────────┘
                                                    │
                                         ┌──────────┴──────────┐
                                         │                     │
                                    [NAVIGATING]          [EDITING]
                                         │                     │
                                   Up/Down:                Up/Down:
                                   mover _selectedLine     ajustar valor
                                         │                     │
                                   Enter:                 Enter:
                                   → EDITING               → NAVIGATING
                                         │                     │
                                   Back:                  Back:
                                   popView (volta P1)      cancelar (restaura valor)
                                                          → NAVIGATING
```

**Fluxo de dados na View:**

```
CustomBuilderView
├── _selectedLine: Number (0, 1, 2)
├── _editing: Boolean
├── _workMin: Number (valor em edicao)
├── _breakMin: Number (valor em edicao)
├── _cycles: Number (valor em edicao)
└── _editStartValue: Number (backup para cancelar)

onUpdate(dc):
├── dc.clear(BG)
├── (titulo "Custom" se bucket != :small)
├── SpecLine.draw(dc, "WORK", _workMin, "min", selected==0, editing&&selected==0, ...)
├── SpecLine.draw(dc, "BREAK", _breakMin, "min", selected==1, editing&&selected==1, ...)
├── SpecLine.draw(dc, "CYCLES", _cycles, "", selected==2, editing&&selected==2, ...)
└── Hints.draw(dc, _editing ? hintsEdit : hintsNav, ...)
```

**Delegate interpreta inputs:**

```
CustomBuilderDelegate
├── onPreviousPage():
│   ├── if editing: incrementar valor (com clamp)
│   └── else: mover selecao pra cima
├── onNextPage():
│   ├── if editing: decrementar valor (com clamp)
│   └── else: mover selecao pra baixo
├── onSelect():
│   ├── if editing: confirmar (sair de edit)
│   └── else: entrar em edit (salvar backup)
└── onBack():
    ├── if editing: cancelar (restaurar backup, sair de edit)
    └── else: popView
```

---

## 7. Referencias para o plan.md

O plan.md deve ler:
- Este PRD (06-tela-personalizado/prd.md)
- `references/architecture.md` §3 (View vs Delegate)
- `references/design_system.md` §5 (componentes), §3.2 (fontes por bucket)
- `spec/spec.md` §2.P2 (pagina Custom Builder)
- `spec/spec.md` §6 item 2 (limites do custom preset)
- `source/model/Preset.mc` (estado atual antes de modificar)
- `source/delegates/HomeDelegate.mc` (ponto de integracao)
- `source/ui/layout/Dimensions.mc` (pattern existente)
- `source/ui/components/PrimaryButton.mc` (referencia de pattern para modulos)

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
