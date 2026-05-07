# PRD — Task 01-05: Tela Presets (refinamento)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Refinar a HomeView (P1) para usar dados reais de presets em vez de strings hardcoded. Criar o tipo `Preset` com formatacao, atualizar `PresetCard` para renderizar variantes (builtin vs custom), adicionar strings localizaveis (`unit_cycles`, `preset_custom_label`), e garantir que os 5 dots reflitam corretamente os 4 presets + Settings.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que serve |
|---|---|
| [source/views/HomeView.mc](source/views/HomeView.mc) | Estrutura de navegacao (selectedIndex, navigateUp/Down, onUpdate). Sera refatorado para usar `Preset[]` em vez de arrays de strings. |
| [source/ui/components/PresetCard.mc](source/ui/components/PresetCard.mc) | Ja renderiza card com label/sublabel/borda. Precisa adaptar para receber `Preset` e tratar variante custom. |
| [source/ui/components/DotsIndicator.mc](source/ui/components/DotsIndicator.mc) | Ja funciona com 5 dots. O ultimo (Settings) precisa visual distinto (outline vs filled). |
| [source/ui/components/Wordmark.mc](source/ui/components/Wordmark.mc) | Nenhuma mudanca necessaria. |
| [source/ui/layout/Colors.mc](source/ui/layout/Colors.mc) | Palette completa. Sem mudancas. |
| [source/ui/layout/Dimensions.mc](source/ui/layout/Dimensions.mc) | Card dimensions ja definidas. Sem mudancas. |
| [source/delegates/HomeDelegate.mc](source/delegates/HomeDelegate.mc) | Navegacao funciona. Nenhuma mudanca necessaria para esta task (demo mode permanece inalterado). |

### 2.2 Assets disponiveis

- Fontes nativas: `FONT_NUMBER_MEDIUM` para numeros de preset, `FONT_TINY`/`FONT_XTINY` para "cycles"/"CUSTOM".
- Palette de cores ja definida em `Colors.mc`.
- Nenhum icone extra necessario (descartamos icone "edit" em favor de texto "CUSTOM").

### 2.3 Approach de implementacao

**Decisao: criar `source/model/Preset.mc` como struct + helpers de formatacao, e refatorar HomeView para consumir dados tipados.**

Justificativa:
- A task 01 usou strings hardcoded como scaffold rapido. Agora precisamos de dados reais para formatar corretamente.
- `Preset.mc` no `model/` segue a arquitetura canonica (§2).
- O PresetCard recebe o objeto Preset diretamente, evitando formatacao espalhada na View.
- Para Custom, o card mostra "CUSTOM" em `FONT_XTINY` + `ACCENT` acima dos numeros, distinguindo visualmente.
- Settings nao e um Preset — permanece como caso especial na HomeView (indice 4).

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Assinatura |
|---|---|---|
| `WatchUi.loadResource(id)` | Carregar strings localizadas | `loadResource(id as Symbol) as Object` |
| `Lang.format(pattern, args)` | Formatar "25 / 5", "$1$ $2$" | `format(format as String, args as Array) as String` |
| `Graphics.FONT_NUMBER_MEDIUM` | Numeros do preset (linha principal) | Constante de fonte |
| `Graphics.FONT_TINY` | Sublabel "4 cycles" | Constante de fonte |
| `Graphics.FONT_XTINY` | Label "CUSTOM" no topo do card custom | Constante de fonte |
| `Graphics.getFontHeight(font)` | Calcular posicionamento vertical | `getFontHeight(font as FontType) as Number` |

### 2.5 Cores/dimensoes/strings necessarias

**Strings a adicionar:**

| Key | EN | PT |
|---|---|---|
| `unit_cycles` | cycles | ciclos |
| `preset_custom_label` | CUSTOM | PERSONALIZADO |
| `settings_label` | Settings | (ja existe) |

**Cores utilizadas (ja existem):**

| Token | Uso neste contexto |
|---|---|
| `Colors.TEXT_PRIMARY` | Numeros do preset (linha 1) |
| `Colors.TEXT_MUTED` | Sublabel "4 cycles" (linha 2) |
| `Colors.ACCENT` | Label "CUSTOM" no card custom |
| `Colors.BRAND` | Borda do card selecionado |
| `Colors.BORDER` | Borda do card nao-selecionado, dots inativos, outline dot Settings |

**Fontes por bucket (preset card):**

| Bucket | Linha 1 (numeros) | Linha 2 (cycles) | Label custom |
|---|---|---|---|
| Small | `FONT_MEDIUM` | `FONT_XTINY` | `FONT_XTINY` |
| Medium | `FONT_NUMBER_MEDIUM` | `FONT_TINY` | `FONT_XTINY` |
| Large | `FONT_NUMBER_MEDIUM` | `FONT_TINY` | `FONT_XTINY` |

---

## 3. Decisoes a tomar

### D1: Fonte da linha principal do preset

**Opcoes:**
- A) `FONT_NUMBER_MEDIUM` — monospacada, otimizada para numeros. Visual mais clean.
- B) `FONT_LARGE` — proporcional, mais texto-like.

**Recomendacao: A** — a task especifica `FONT_NUMBER_MEDIUM` explicitamente nos criterios de aceitacao. Numeros ficam alinhados e com identidade forte.

**Nota para small bucket:** `FONT_NUMBER_MEDIUM` pode ser grande demais no FR255S (218px). Fallback para `FONT_MEDIUM` no bucket small.

### D2: DotsIndicator — visual distinto para Settings

**Opcoes:**
- A) Settings dot como outline (circulo vazio em vez de preenchido).
- B) Settings dot menor que os demais.
- C) Separador visual (espaco maior) antes do dot Settings.

**Recomendacao: A** — outline e o padrao UI mais reconhecivel para "item diferente". Implementacao simples: `dc.drawCircle` em vez de `dc.fillCircle` quando `index == total - 1 && index != activeIndex`.

### D3: PresetCard.draw — manter modulo ou converter para classe?

**Opcoes:**
- A) Manter como `module PresetCard` com funcao `draw(dc, centerX, centerY, preset, isSelected, ...)`.
- B) Converter para `class PresetCard` com estado interno.

**Recomendacao: A** — componentes sao stateless por definicao na arquitetura (§3 Components). Modulo e correto. Apenas mudar a assinatura para receber `Preset` em vez de strings.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | `FONT_NUMBER_MEDIUM` pode nao caber no card small (218px) | Usar `FONT_MEDIUM` como fallback no bucket `:small`. Validar no simulador FR255S. |
| 2 | `WatchUi.loadResource` em `Preset.formatSecondary()` aloca a cada chamada | Chamar uma unica vez em `HomeView.initialize()` e passar como parametro, ou cache na classe Preset. |
| 3 | Strings PT nao existem (`strings_pt.xml` ausente) | Criar arquivo `resources-por/strings/strings.xml` com traduzidas. Connect IQ usa diretorio `resources-<lang>/`. |
| 4 | Preset custom mostra valores default hardcoded (25/5/4) — nao ha persistencia | Aceitavel para esta task (persistencia vem em 02-08). Documentar no codigo que valores sao placeholder. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/model/Preset.mc` (NOVO) | Classe Preset (workMin, breakMin, cycles, isCustom) + formatacao. Modulo Presets com factory `builtinList()`. |
| `source/views/HomeView.mc` (MODIFICAR) | Substituir arrays de strings por `Array<Preset>`. Usar `Preset.formatPrimary()` e `Preset.formatSecondary()` para alimentar o card. |
| `source/ui/components/PresetCard.mc` (MODIFICAR) | Nova assinatura: receber `Preset` (ou seus campos formatados) + flag `isCustom`. Renderizar label "CUSTOM" acima dos numeros quando custom. |
| `source/ui/components/DotsIndicator.mc` (MODIFICAR) | Dot do ultimo item (Settings) desenhado como outline em vez de filled. |
| `resources/strings/strings.xml` (MODIFICAR) | Adicionar `unit_cycles`, `preset_custom_label`. |
| `resources-por/strings/strings.xml` (NOVO) | Versao PT de todas as strings (incluindo as novas). |

---

## 6. Arquitetura do fluxo

```
HomeView.initialize()
  │
  ├── Presets.builtinList() → Array<Preset> [25/5/4, 30/5/4, 50/10/4, custom:25/5/4]
  │
  └── _cyclesLabel = WatchUi.loadResource(Rez.Strings.unit_cycles)
      _customLabel = WatchUi.loadResource(Rez.Strings.preset_custom_label)

HomeView.onUpdate(dc)
  │
  ├── Wordmark.draw(...)
  │
  ├── if (_selectedIndex < 4)
  │     preset = _presets[_selectedIndex]
  │     PresetCard.draw(dc, ..., preset.formatPrimary(), preset.formatSecondary(_cyclesLabel), preset.isCustom, ...)
  │   else (index == 4 → Settings)
  │     PresetCard.draw(dc, ..., "Settings", "", false, ...)
  │
  └── DotsIndicator.draw(dc, ..., 5, _selectedIndex, ..., settingsIndex=4)

PresetCard.draw(dc, ..., isCustom)
  │
  ├── Borda (brand se selected, border senao)
  ├── if (isCustom) → draw "CUSTOM" label (FONT_XTINY, ACCENT) no topo interno do card
  ├── Linha 1: numeros "25 / 5" (FONT_NUMBER_MEDIUM, textPrimary)
  └── Linha 2: "4 cycles" (FONT_TINY, textMuted)

DotsIndicator.draw(dc, ..., settingsIndex)
  │
  └── for cada dot:
        if (i == activeIndex) → fillCircle ACCENT
        else if (i == settingsIndex) → drawCircle BORDER (outline)
        else → fillCircle BORDER
```

---

## 7. Referencias para o plan.md

- `references/architecture.md` §2 (pastas), §3 (separacao de responsabilidades — Components stateless), §4 (regras de codificacao — strings via Rez.Strings).
- `references/design_system.md` §3.2 (fontes por bucket), §5 (componentes reutilizaveis).
- `spec/spec.md` §2.P1 (conteudo da Home), §3.C7 (Preset Card), §6 (regras de negocio — limites Custom 5-90/1-30/1-10).
- Codigo existente: `HomeView.mc`, `PresetCard.mc`, `DotsIndicator.mc`, `Colors.mc`, `Dimensions.mc`.

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeca gerar plan.md.