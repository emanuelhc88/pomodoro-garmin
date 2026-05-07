# Task 01-01: Tela Home / Preset Picker

## Objetivo

Implementar a **P1 (Home / Preset Picker)** como protótipo visual estático. Tela mostra os 5 itens (4 presets + Settings) em formato de "card paginado" navegável por Up/Down (FR) ou swipe (touch). Sem lógica de timer, sem persistência ainda — só renderização e navegação visual.

Como esta é a **primeira** task do projeto, ela também cobre o **scaffold mínimo** (manifest, jungle, AppBase, .gitignore, launch.json).

## Tipo

- [x] Protótipo Visual
- [ ] Comportamento (lógica)
- [x] Setup / Config (scaffold mínimo)

## Cobre

- **P1** (Home / Preset Picker) — `spec/spec.md` §2.P1
- **C6** Wordmark, **C7** Preset Card, **C8** Dots Indicator — `spec/spec.md` §3
- **B14** Input multi-device (parcial — só nav up/down/select) — `spec/spec.md` §4.B14

## Dependências

- Bloco 00 setup completo (`tasks/00-setup/README.md`).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings em `monkeyc -d fr255` e `-d fr265`.
- [ ] App roda no simulador FR255 (medium MIP) sem crash.
- [ ] App roda no simulador FR265 (large AMOLED) sem crash.
- [ ] App roda no simulador FR255S (small) sem crash.
- [ ] `monkeyc --typecheck=Strict` passa.

### Manual

- [ ] Tela inicial mostra wordmark "toma" no topo.
- [ ] Centro mostra preset selecionado (formato `25 / 5 · 4 cycles` ou similar).
- [ ] Dots indicator mostra 5 dots, com o ativo destacado.
- [ ] Up/Down navega entre os 5 itens (4 presets + Settings).
- [ ] Em FR265 (touch), swipe up/down também navega.
- [ ] Visual segue paleta Toma: fundo `#0C0C0C`, brand `#E8432D` no card ativo, texto warm white.
- [ ] Layout responsivo nos 3 buckets (validar visualmente: small/medium/large).
- [ ] Phase label "FOCUS" não aparece (anel idle não é mostrado nesta tela; só o card).

## Arquivos esperados (a refinar na Spec Tática durante FASE 2.3)

### Novos

- `manifest.xml` (na raiz)
- `monkey.jungle` (na raiz)
- `.gitignore`
- `.vscode/launch.json`
- `.vscode/tasks.json`
- `source/TomaApp.mc`
- `source/views/HomeView.mc`
- `source/delegates/HomeDelegate.mc`
- `source/ui/components/Wordmark.mc`
- `source/ui/components/PresetCard.mc`
- `source/ui/components/DotsIndicator.mc`
- `source/ui/layout/Bucket.mc`
- `source/ui/layout/FontFor.mc`
- `resources/drawables/colors.xml`
- `resources/drawables/dimensions.xml`
- `resources/drawables/launcher_icon.png` (gerar a partir de `manual-de-marca/logo/toma_icon.svg`)
- `resources/drawables/drawables.xml`
- `resources/strings/strings.xml` (en — default)
- `resources/strings/strings_pt.xml`
- `resources-small/drawables/dimensions.xml`
- `resources-large/drawables/dimensions.xml`

### Modificados

- (Nenhum — projeto novo.)

## Referências obrigatórias

- `references/architecture.md` §2 (estrutura de pastas), §3 (separação de responsabilidades), §5 (multi-device).
- `references/design_system.md` §2 (paleta), §3 (tipografia), §4 (layouts/buckets), §5.4 e §5.5 (componentes Wordmark e dots — derivar dos princípios), §6.2 mockup Home.
- `references/garmin_platform.md` §1 (devices suportados), §2.6 (BehaviorDelegate).
- `spec/spec.md` §2.P1, §3.

## Notas de design

### Layout sugerido (medium 260×260)

```
                    toma                ← wordmark, top, FONT_TINY
       ╭──────────────────────╮
       │                      │
       │       25 / 5         │  ← preset numbers grandes
       │      · 4 cycles      │
       │                      │
       ╰──────────────────────╯
                                       (espaço)
            ●  ◯  ◯  ◯  ◯              ← 5 dots (preset 1 ativo)
```

Para o item "Settings" (último):
```
       ╭──────────────────────╮
       │                      │
       │      Settings        │  ← texto, FONT_LARGE
       │         ⚙            │  ← (decidir: ícone ou só texto?)
       │                      │
       ╰──────────────────────╯
```

### Comportamento da seleção

- Default: dot ativo é `lastSelectedPreset` lido de Properties. Como ainda não temos Properties (vem na task 02-08), usar índice 0.
- Wraparound: ao passar do último, volta ao primeiro (e vice-versa).

### Preset Card visual

- Border 0.5-1px cor `border` (`#2A2A2A`).
- Sem background (transparente sobre `bg`).
- Em estado "selected", border vira `brand` (`#E8432D`).
- Conteúdo central: dois fontes empilhadas — número grande + texto pequeno.

### Para Settings (último card)

Decidir nesta task: ícone só? texto só? ambos? Recomendação: texto "Settings" em `FONT_MEDIUM` + ícone gear (drawable simples) ao lado.

## Out of scope desta task

- Persistência de seleção (vai pra task `02-08-persistencia-settings`).
- Navegação real para Timer (P3) — Enter pode dar log, mas não precisa pushView ainda. Ou: pode pushView para uma `PlaceholderView` que apenas mostra "TODO: Timer P3".
- Navegação real para Settings — idem.
- Custom Builder — idem.
- Carregar idioma do Properties — usa só `strings.xml` (en) por ora; PT em `strings_pt.xml` mas Connect IQ resolve automaticamente pelo locale do device.
