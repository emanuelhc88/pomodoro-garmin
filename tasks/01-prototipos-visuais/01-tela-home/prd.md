# PRD — Task 01-01: Tela Home / Preset Picker

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na próxima sessão.

---

## 1. Resumo

Implementar P1 (Home / Preset Picker) como protótipo visual com navegação funcional (Up/Down + wraparound) e o scaffold mínimo do projeto (manifest, jungle, AppBase, .gitignore, launch.json). Sem lógica de timer, sem persistência, sem navegação real para P3/P8.

---

## 2. O que descobri

### 2.1 Código existente para reutilizar

Nenhum — projeto ainda não tem `source/`. Esta é a primeira task.

### 2.2 Assets disponíveis

- `manual-de-marca/logo/toma_icon.svg` — ícone do app (tomate vermelho + talo verde)
- `manual-de-marca/logo/toma_icon_dark_bg.svg` — variante em fundo escuro

### 2.3 Approach de desenho

Connect IQ permite dois modos para Views:
1. **XML layouts** (`setLayout(Rez.Layouts.home)`) — estático, bom para menus.
2. **Desenho programático** no `onUpdate(dc)` — full control, necessário para custom drawing.

**Decisão: desenho programático.** Justificativa:
- O Preset Card tem borda dinâmica (muda cor com seleção).
- O Dots Indicator muda estado por item.
- Layout requer posicionamento relativo ao bucket.
- XML layouts do Connect IQ são limitados (sem expressões, sem condicionais).

### 2.4 Navegação entre itens

5 itens no picker: 4 presets + Settings. Dados hardcoded (sem Properties nesta task).

| Índice | Label principal | Sublabel |
|---|---|---|
| 0 | `25 / 5` | `4 cycles` |
| 1 | `30 / 5` | `4 cycles` |
| 2 | `50 / 10` | `4 cycles` |
| 3 | `Custom` | `25 / 5 · 4` (default) |
| 4 | `Settings` | (ícone gear ou apenas texto) |

### 2.5 BehaviorDelegate para navegação

```monkeyc
onPreviousPage() → navegar Up (índice - 1, wraparound)
onNextPage()     → navegar Down (índice + 1, wraparound)
onSelect()       → log "Selected preset N" (sem pushView real ainda)
onMenu()         → log "Menu pressed" (sem pushView real ainda)
```

`onPreviousPage` e `onNextPage` abstraem automaticamente:
- Up/Down buttons em FR (devices sem touch).
- Swipe Up/Down em devices touch.

### 2.6 API de desenho relevante

```monkeyc
dc.setColor(fg, bg)
dc.clear()
dc.drawText(x, y, font, text, justification)
dc.drawRoundedRectangle(x, y, w, h, radius)
dc.fillCircle(x, y, radius)
dc.getWidth() / dc.getHeight()
Graphics.getFontHeight(font)
```

Justificação de texto: `Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER`.

### 2.7 Buckets e dimensionamento

| Bucket | Screen | Dispositivos V1 |
|---|---|---|
| `:small` | ≤218px | FR255S |
| `:medium` | 220-290px | FR255, Fenix 7 |
| `:large` | ≥320px | FR265, FR965, Venu 3, Vivoactive 5 |

O helper `Bucket.detect()` usa `System.getDeviceSettings().screenWidth`.

### 2.8 Cores necessárias (colors.xml)

| Token | Hex | Uso nesta tela |
|---|---|---|
| `bg` | `#0C0C0C` → `0x0C0C0C` | Fundo |
| `brand` | `#E8432D` → `0xE8432D` | Borda do card selecionado |
| `textPrimary` | `#F5F0EB` → `0xF5F0EB` | Texto principal (preset numbers) |
| `textMuted` | `#888888` → `0x888888` | Sublabel, wordmark |
| `border` | `#2A2A2A` → `0x2A2A2A` | Borda do card não-selecionado, dots inativas |
| `accent` | `#FF6B47` → `0xFF6B47` | Dot ativa |

### 2.9 Strings necessárias

EN (default):
- `app_name` = "Toma"
- `preset_cycles` = "%d cycles"
- `settings_label` = "Settings"

PT:
- `app_name` = "Toma"
- `preset_cycles` = "%d ciclos"
- `settings_label` = "Configurações"

### 2.10 Fontes por bucket nesta tela

| Elemento | Small | Medium/Large |
|---|---|---|
| Wordmark "toma" | `FONT_XTINY` | `FONT_TINY` |
| Preset numbers ("25 / 5") | `FONT_LARGE` | `FONT_LARGE` |
| Sublabel ("4 cycles") | `FONT_SMALL` | `FONT_SMALL` |
| Settings label | `FONT_MEDIUM` | `FONT_MEDIUM` |

---

## 3. Decisões a tomar

### D1: Settings card — ícone ou texto?

**Opções:**
- (a) Apenas texto "Settings" em `FONT_MEDIUM`.
- (b) Texto "Settings" + ícone gear (drawable PNG/bitmap).
- (c) Ícone gear grande centralizado + texto pequeno abaixo.

**Recomendação: (a) Apenas texto.** Justificativa:
- Ícone gear requer criar drawable bitmap ou font glyph custom — overhead desnecessário para V1.
- Texto sozinho é claro e consistente com o tom direto da marca Toma.
- Pode ser revisitado em task futura com baixo custo.

### D2: Dimensões do Preset Card

**Recomendação para medium (260×260):**
- Card: 180×80, rounded rect com radius 8px.
- Centrado horizontal, centrado vertical (levemente acima do centro para acomodar dots).
- Border: 2px (1px é quase invisível em MIP).

**Para small (218×218):** proporcionalmente menor (150×66).
**Para large (390+):** proporcionalmente maior (260×110).

### D3: Dots Indicator dimensões

- Dot radius: 4px (medium), 3px (small), 5px (large).
- Spacing entre dots: 10px (medium).
- Dot ativa: filled com `accent`.
- Dot inativa: outline 1px `border` ou filled com `border`.

**Recomendação:** filled (mais visível em MIP).
- Ativa: `accent` (`0xFF6B47`).
- Inativa: `border` (`0x2A2A2A`).

### D4: monkey.jungle — quantos devices no build inicial?

**Recomendação:** começar com 3 devices para validar os 3 buckets:
- `fr255` (medium, MIP, sem touch)
- `fr255s` (small, MIP, sem touch)
- `fr265` (large, AMOLED, com touch)

Adicionar o restante numa task futura de setup incremental (baixo risco, alto ruído no PR inicial).

### D5: Wordmark "toma" — drawText ou bitmap?

**Recomendação: drawText.** A fonte nativa em `FONT_TINY` + lowercase é legível e condiz com a marca. Font custom não está no escopo V1 (decisão em `design_system.md §3.1`).

---

## 4. Riscos / Unknowns

| # | Risco | Mitigação |
|---|---|---|
| R1 | `FONT_TINY` pode renderizar "toma" de forma ilegível em small bucket (218px) | Testar no simulador FR255S. Fallback: subir para `FONT_SMALL` |
| R2 | Cor `border` (`0x2A2A2A`) pode ser indistinguível de `bg` (`0x0C0C0C`) em MIP após dithering de 64 cores | Validar no simulador FR255. Se necessário, subir border para `0x333333` em `resources-mip/` override |
| R3 | Dots em `fillCircle` com radius 3-4px podem ficar quadradas em MIP | Aceitar — MIP de 260px renderiza razoavelmente. Se ficar ruim, usar `drawCircle` outline |
| R4 | IDs de devices no jungle podem diferir do documentado | Verificar em `~/Library/Application Support/Garmin/ConnectIQ/Sdks/*/devices/` durante setup |
| R5 | Primeiro build pode ter warnings por tipos não declarados | Usar `:typecheck(Strict)` desde o início e corrigir iterativamente |

---

## 5. Lista de arquivos a criar/modificar

### Novos (scaffold + feature)

| Arquivo | Responsabilidade |
|---|---|
| `manifest.xml` | Metadata do app, devices, permissions, languages |
| `monkey.jungle` | Build multi-device, sourcePaths, excludeAnnotations |
| `.gitignore` | Ignorar binários, keys, IDE artifacts |
| `.vscode/launch.json` | Debug configs para FR255, FR255S, FR265 |
| `.vscode/tasks.json` | Build tasks |
| `source/TomaApp.mc` | AppBase: lifecycle, retorna HomeView |
| `source/views/HomeView.mc` | P1: render do Preset Picker (wordmark, card, dots) |
| `source/delegates/HomeDelegate.mc` | Input: Up/Down/Select/Menu |
| `source/ui/components/Wordmark.mc` | Desenha "toma" lowercase |
| `source/ui/components/PresetCard.mc` | Desenha card com borda + conteúdo |
| `source/ui/components/DotsIndicator.mc` | Desenha N dots com ativo destacado |
| `source/ui/layout/Bucket.mc` | Helper: detect bucket por screenWidth |
| `resources/drawables/colors.xml` | Paleta Toma (6 cores) |
| `resources/drawables/drawables.xml` | Declarações de drawables |
| `resources/drawables/launcher_icon.png` | Ícone do app (rasterizado do SVG) |
| `resources/strings/strings.xml` | Strings EN (default) |
| `resources/strings/strings_pt.xml` | Strings PT |
| `resources-small/drawables/dimensions.xml` | Override dimensões small (218px) |
| `resources/drawables/dimensions.xml` | Dimensões default (medium 260px) |
| `resources-large/drawables/dimensions.xml` | Override dimensões large (390+px) |

### Modificados

Nenhum — projeto novo.

---

## 6. Arquitetura do fluxo (desta tela)

```
TomaApp.getInitialView()
    → [HomeView, HomeDelegate]

HomeDelegate:
    onPreviousPage() → decrement selectedIndex (wraparound) → requestUpdate()
    onNextPage()     → increment selectedIndex (wraparound) → requestUpdate()
    onSelect()       → log (sem navegação real)
    onMenu()         → log (sem navegação real)

HomeView.onUpdate(dc):
    1. Clear screen (bg)
    2. Wordmark.draw(dc, ...) → "toma" topo
    3. PresetCard.draw(dc, preset[selectedIndex], isSelected=true)
    4. DotsIndicator.draw(dc, total=5, active=selectedIndex)
```

**Estado:** `selectedIndex` (Number, 0-4) vive no HomeDelegate e é passado ao HomeView via referência.

Alternativa mais limpa: HomeView mantém `selectedIndex` internamente, e HomeDelegate tem referência ao HomeView para chamar `view.setSelectedIndex(n)`. Mas isso viola "Delegate não muta View" — melhor: **estado vive num module ou classe leve que ambos acessam**.

**Decisão final:** estado `selectedIndex` vive no HomeView mesmo (é estado de UI, não de domínio). HomeDelegate mantém referência ao view e chama `view.navigateUp()` / `view.navigateDown()`, que alteram o índice e chamam `requestUpdate()`. Isso é consistente com o padrão Connect IQ onde Views mantêm estado visual.

---

## 7. Referências para o plan.md

Na próxima sessão (FASE 2.3), ler:
- Este PRD (`prd.md`) — completo.
- `references/design_system.md` §2 (paleta), §4 (buckets), §5.4-5.5 (button/phase label — para estilo).
- `references/architecture.md` §2 (pastas), §4 (regras de codificação).
- `references/garmin_platform.md` §1 (devices), §2.6 (BehaviorDelegate).

---

## 8. Checklist pré-plan

- [x] Todas as decisões têm recomendação.
- [x] Riscos identificados com mitigação.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas.
- [x] Nenhuma ambiguidade que impeça gerar plan.md.
