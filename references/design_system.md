# Toma — Design System (Garmin Adaptation)

> Adaptação rigorosa do [manual-de-marca/toma_brand_manual.md](../manual-de-marca/toma_brand_manual.md) para as restrições do Garmin Connect IQ.

A marca Toma foi desenhada para web (Linear/Raycast/Notion-style). Connect IQ tem restrições duras: paletas reduzidas em MIP (64 cores), fontes nativas obrigatórias, displays circulares pequenos. Este documento traduz cada decisão da marca para o que é tecnicamente possível no relógio, sem perder a essência.

---

## 1. Princípios de adaptação

1. **Dark first é não-negociável.** Mesmo nos AMOLED grandes (FR965, Venu 3), fundo `#0C0C0C`. Light mode não existe nesta V1.
2. **Minimalismo é vantagem em MIP.** A restrição de 64 cores favorece o estilo Toma (sem gradientes, sem sombras). Aceite a restrição.
3. **Hierarquia por tamanho, não por cor.** Em MIP, sutilezas de cor (`#888` vs `#666`) podem virar a mesma cor após dithering. Use tamanho de fonte e posição para hierarquia.
4. **Anel do timer é o herói visual.** Em todas as telas com timer, o anel circular `Toma Red` é o primeiro elemento. Tudo orbita ele.

---

## 2. Paleta — Toma → Garmin

### 2.1 Tabela de mapeamento

| Token Toma | Hex | Uso no app | Constante Connect IQ |
|---|---|---|---|
| `--color-bg` | `#0C0C0C` | Fundo de toda tela | `Rez.Colors.bg` |
| `--color-surface` | `#161616` | (Não aplicável — não temos cards no relógio) | — |
| `--color-elevated` | `#1F1F1F` | Background do menu de settings | `Rez.Colors.surface` |
| `--color-brand` | `#E8432D` | Anel idle do timer, label de fase Work, botão primário | `Rez.Colors.brand` |
| `--color-accent` | `#FF6B47` | Anel running do timer, hover/focus visual | `Rez.Colors.accent` |
| `--color-text-primary` | `#F5F0EB` | Display do timer, labels primárias | `Rez.Colors.textPrimary` |
| `--color-text-muted` | `#888888` | Labels secundárias ("Session 1") | `Rez.Colors.textMuted` |
| `--color-border` | `#2A2A2A` | Divisores em menus, pills inativas | `Rez.Colors.border` |

### 2.2 Cores derivadas (estados)

| Estado | Anel | Label fase | Display |
|---|---|---|---|
| Idle | `border` (`#2A2A2A`) | (oculto) | `textPrimary` |
| Running — Work | `brand` (`#E8432D`) | `brand` | `textPrimary` |
| Running — Short Break | `textMuted` (`#888888`) | `textMuted` | `textPrimary` |
| Running — Long Break | `accent` (`#FF6B47`) | `accent` | `textPrimary` |
| Paused | Anel ainda preenchido com cor da fase, mas com **opacidade simulada via cor mais escura** (`brand` → `border`) | `textMuted` (label "Paused") | `textMuted` |
| Completed | `accent` | `accent` | `textPrimary` |

### 2.3 Atenção MIP (FR255, FR255S, FR955, Fenix 7)

Display MIP destes devices é **64 cores indexadas**. Isso significa que valores hex exatos são aproximados pelo firmware ao tom mais próximo da palette do device.

**Estratégia:**
- Definir cores em `resources/drawables/colors.xml` como hex exato. Connect IQ faz o mapping automaticamente.
- **Validar visualmente no simulador FR255** antes de fechar o design system. Tons que ficam idênticos após mapping (ex: `#888` e `#999` viram a mesma cor) precisam ser ajustados.
- Resultado esperado dos pares Toma após mapping MIP (a confirmar no simulador):
  - `#E8432D` → fica vivo, mantém identidade ✅
  - `#FF6B47` → próximo de `#FF6633`, ainda distinto do brand ✅
  - `#F5F0EB` → vira algo próximo de `#FFFFCC` ou branco neutro — testar
  - `#888888` → vira cinza médio, OK ✅
  - `#2A2A2A` → vira cinza escuro, próximo do bg `#0C0C0C` — testar contraste

**Regra:** se após teste algum par perder distinção, criar arquivo `resources-mip/drawables/colors.xml` com valores ajustados específicos para devices MIP.

### 2.4 AMOLED (FR265, FR965, Epix Gen 2, Venu 3, Vivoactive 5, Fenix 8)

- Cores hex passam direto. Sem ajustes.
- **Burn-in mitigation:** evitar elementos estáticos por períodos longos com cores muito brilhantes em pixels fixos. Como o timer muda a cada segundo, baixo risco. Mas o ring "Idle" (parado) não deve ficar em accent — usar `border` (escuro).

---

## 3. Tipografia

### 3.1 Restrição de plataforma

Connect IQ aceita fontes custom em `.fnt` (formato bitmap proprietário Garmin), mas:
- Conversão de TTF → FNT é trabalhosa e cada peso precisa de arquivo separado.
- Fontes custom consomem heap precioso.
- Fontes nativas Garmin são bem desenhadas e otimizadas por device.

**Decisão V1: usar fontes nativas Garmin.** Custom fonts ficam para V2 (se houver demanda).

### 3.2 Tabela de mapeamento

| Papel Toma | Fonte Toma original | Fonte Garmin equivalente | Uso |
|---|---|---|---|
| Display — Timer | JetBrains Mono 42-48px regular | `Graphics.FONT_NUMBER_THAI_HOT` (medium devices) ou `FONT_NUMBER_HOT` | Countdown MM:SS |
| Display — Number large | JetBrains Mono | `FONT_NUMBER_MEDIUM` | Contagem de sessões na Cycle Complete |
| Headings | Inter 18-22px medium | `Graphics.FONT_LARGE` | Título de menus, "Cycle complete" |
| Labels / botões | Inter 13-14px medium | `Graphics.FONT_MEDIUM` | Botões, labels de fase |
| Corpo / descrições | Inter 14-16px regular | `Graphics.FONT_SMALL` | Texto explicativo (Settings descriptions) |
| Metadados / hints | Inter 11-12px regular | `Graphics.FONT_TINY` ou `FONT_XTINY` | "Session 1 of 4", hints de input |

**Justificativa:**
- Connect IQ `FONT_NUMBER_*` é monoespaçada e otimizada para tempos/números — equivalente funcional do JetBrains Mono.
- `FONT_LARGE/MEDIUM/SMALL/TINY` são sans-serif do device — não Inter, mas seguem o mesmo princípio "geométrico, neutro".

### 3.3 Tamanhos por bucket

Garmin escala automaticamente as font constants por device, mas você deve **escolher a constante apropriada** ao bucket:

| Bucket | Timer | Heading | Label | Hint |
|---|---|---|---|---|
| Small (218×218) | `FONT_NUMBER_MEDIUM` | `FONT_MEDIUM` | `FONT_SMALL` | `FONT_XTINY` |
| Medium (260×260) | `FONT_NUMBER_THAI_HOT` | `FONT_LARGE` | `FONT_MEDIUM` | `FONT_TINY` |
| Large (390-454×454) | `FONT_NUMBER_THAI_HOT` | `FONT_LARGE` | `FONT_MEDIUM` | `FONT_TINY` |

Helper: `FontFor.timer(bucket)`, `FontFor.heading(bucket)`, etc., em `source/ui/layout/FontFor.mc`.

---

## 4. Layouts responsivos — Buckets de tela

### 4.1 Definição de buckets

| Bucket | Range de width | Devices alvo |
|---|---|---|
| `:small` | `<= 218 px` | FR255S |
| `:medium` | `220-280 px` | FR255, Fenix 7 |
| `:large` | `>= 320 px` | FR265, FR265S, FR955 (454), FR965, Venu 3, Vivoactive 5, Fenix 8, Epix Gen 2 |

**Nota:** FR955 tem 454×454 mas é MIP. FR965 tem 454×454 e é AMOLED. Bucket é o mesmo (`:large`), mas a annotation `:mip`/`:amoled` muda alguns detalhes (ex: opacidade simulada vs real).

### 4.2 Helper

```monkeyc
module Bucket {
    function detect() as Symbol {
        var w = System.getDeviceSettings().screenWidth;
        if (w <= 220) { return :small; }
        if (w <= 290) { return :medium; }
        return :large;
    }
}
```

### 4.3 Dimensions por bucket

`resources/drawables/dimensions.xml` (default = medium):

```xml
<resources>
    <dimension id="ringRadius">100</dimension>
    <dimension id="ringStroke">8</dimension>
    <dimension id="timerCenterY">130</dimension>
    <dimension id="phaseLabelOffsetY">-60</dimension>
    <dimension id="pillsOffsetY">90</dimension>
    <dimension id="pillSize">8</dimension>
    <dimension id="pillSpacing">4</dimension>
</resources>
```

Override em `resources-small/drawables/dimensions.xml`:

```xml
<resources>
    <dimension id="ringRadius">85</dimension>
    <dimension id="ringStroke">6</dimension>
    <dimension id="timerCenterY">109</dimension>
    <dimension id="phaseLabelOffsetY">-48</dimension>
    <dimension id="pillsOffsetY">75</dimension>
    <dimension id="pillSize">6</dimension>
    <dimension id="pillSpacing">3</dimension>
</resources>
```

Override em `resources-large/drawables/dimensions.xml`:

```xml
<resources>
    <dimension id="ringRadius">175</dimension>
    <dimension id="ringStroke">12</dimension>
    <dimension id="timerCenterY">227</dimension>
    <dimension id="phaseLabelOffsetY">-100</dimension>
    <dimension id="pillsOffsetY">160</dimension>
    <dimension id="pillSize">10</dimension>
    <dimension id="pillSpacing">6</dimension>
</resources>
```

---

## 5. Componentes visuais reutilizáveis

### 5.1 TimerRing

**Função:** desenhar anel circular de progresso.

**API:**
```monkeyc
class TimerRing {
    function initialize(centerX, centerY, radius, stroke);
    function draw(dc, progress as Float, color as Number);
    // progress: 0.0 a 1.0
}
```

**Render:**
- Arco partindo do topo (12h), sentido horário, completando conforme `progress`.
- Stroke `Rez.Dimensions.ringStroke`.
- Cor passada por argumento (depende do estado — ver tabela 2.2).

### 5.2 TimerDisplay

**Função:** renderizar `MM:SS` centralizado.

**API:**
```monkeyc
class TimerDisplay {
    function initialize(centerX, centerY, font);
    function draw(dc, secondsRemaining as Number, color as Number);
}
```

Formato: `25:00`, `04:59`, `00:00`. Sempre 2 dígitos por lado.

### 5.3 SessionPills

**Função:** mostrar 4 pills indicando ciclos completos no preset.

**Estados de cada pill:**
- Inativa: outline 1px `border`.
- Ativa (current): preenchida `accent`.
- Completa: preenchida `brand`.

**API:**
```monkeyc
class SessionPills {
    function initialize(centerX, y, total as Number);
    function draw(dc, current as Number, completed as Number);
    // ex: total=4, completed=2, current=3 → [ ● ● ◯ ○ ]
}
```

Pills são desenhadas horizontalmente, espaçamento `pillSpacing`. Se `total > 4` (preset custom com mais ciclos), mostrar `2/8` em texto pequeno em vez de pills.

### 5.4 PrimaryButton (raro, só tela Cycle Complete)

**Função:** botão pixel-art rectangular, fundo `brand`, texto `textPrimary`.

Usado pouco — Connect IQ prefere navegação por botão físico. Aparece só onde precisa de CTA visual claro (ex: "Start again" após cycle complete).

### 5.5 PhaseLabel

**Função:** texto curto da fase ("FOCUS", "BREAK", "LONG BREAK").

**Detalhes:**
- Sempre uppercase no relógio (visibilidade) — exceção ao manual Toma original (que pede lowercase).
- Cor segue tabela 2.2.
- Posição: acima do TimerDisplay, offset `phaseLabelOffsetY`.

**Justificativa para uppercase:** o manual Toma pede lowercase em wordmark, mas em telas pequenas de relógio, "FOCUS" lê-se melhor que "focus". Tom minimalista é preservado pela ausência de outros adornos.

---

## 6. Estados visuais por tela

### 6.1 Estados gerais

```
┌─────────────────────────────────────────────┐
│  Idle (HomeView mostrando, sem timer)       │  Anel: border
├─────────────────────────────────────────────┤
│  Running — Work                             │  Anel: brand
├─────────────────────────────────────────────┤
│  Running — Short Break                      │  Anel: textMuted
├─────────────────────────────────────────────┤
│  Running — Long Break                       │  Anel: accent
├─────────────────────────────────────────────┤
│  Paused (timer congelado)                   │  Anel: cor da fase, dim
├─────────────────────────────────────────────┤
│  Phase Transition (3s breve)                │  Tela full com label gigante da próxima fase
├─────────────────────────────────────────────┤
│  Cycle Complete                             │  Anel: accent, full circle, número de sessões
└─────────────────────────────────────────────┘
```

### 6.2 Mockups ASCII (medium bucket — 260×260)

**Home (Preset Picker):**
```
  ┌───────────────────────┐
  │       toma            │  ← wordmark pequeno topo
  │                       │
  │     ┌─────────┐       │
  │     │ 25 / 5  │  ←    │  ← preset selecionado
  │     │  × 4    │       │
  │     └─────────┘       │
  │                       │
  │   ◌ ● ◌ ◌             │  ← indicador de qual preset
  │                       │
  │   ▼ Custom            │  ← último item: ir para builder
  └───────────────────────┘
```

**Timer Running — Work:**
```
  ┌───────────────────────┐
  │        FOCUS          │  ← phase label (cor brand)
  │      ●━━━━━━━━●       │
  │     ●           ●     │
  │    ●    25:00   ●     │  ← MM:SS centralizado
  │     ●           ●     │
  │      ●━━━━━━━━●       │
  │       ● ● ○ ○         │  ← session pills
  └───────────────────────┘
```

**Paused:**
```
  ┌───────────────────────┐
  │        FOCUS          │  (dim)
  │      ●━━━━━━━━●       │  (anel dim)
  │     ●           ●     │
  │    ●    14:23   ●     │  (texto muted)
  │     ●           ●     │
  │      ●━━━━━━━━●       │
  │        PAUSED         │  ← label adicional, textMuted
  └───────────────────────┘
```

**Cycle Complete:**
```
  ┌───────────────────────┐
  │     CYCLE COMPLETE    │  ← heading, accent
  │                       │
  │         4 / 4         │  ← número grande
  │                       │
  │    Today: 8 sessions  │  ← contador diário
  │                       │
  │     [START AGAIN]     │  ← PrimaryButton
  └───────────────────────┘
```

---

## 7. Strings — Tom de voz

Aplicar o tom **direto, sem floreio** do manual Toma. Sempre imperativo, sem celebração, sem emoji, sem exclamação.

### 7.1 Glossário EN ↔ PT

| Key | EN | PT |
|---|---|---|
| `app_name` | Toma | Toma |
| `home_title` | Pomodoro | Pomodoro |
| `preset_25_5` | 25 / 5 · 4 cycles | 25 / 5 · 4 ciclos |
| `preset_30_5` | 30 / 5 · 4 cycles | 30 / 5 · 4 ciclos |
| `preset_50_10` | 50 / 10 · 4 cycles | 50 / 10 · 4 ciclos |
| `preset_custom` | Custom | Personalizado |
| `phase_focus` | FOCUS | FOCO |
| `phase_break` | BREAK | PAUSA |
| `phase_long_break` | LONG BREAK | PAUSA LONGA |
| `state_paused` | PAUSED | PAUSADO |
| `cycle_complete_title` | CYCLE COMPLETE | CICLO COMPLETO |
| `today_sessions` | Today: %d sessions | Hoje: %d sessões |
| `start_again` | Start again | Recomeçar |
| `done` | Done | Pronto |
| `settings_sound` | Sound | Som |
| `settings_vibration` | Vibration | Vibração |
| `settings_backlight` | Backlight on alert | Iluminação no alerta |
| `settings_record_activity` | Record as activity | Gravar como atividade |
| `settings_language` | Language | Idioma |
| `settings_about` | About | Sobre |
| `confirm_stop_title` | Stop session? | Parar sessão? |
| `confirm_stop_yes` | Stop | Parar |
| `confirm_stop_no` | Continue | Continuar |
| `recovery_title` | Resume session? | Retomar sessão? |
| `recovery_resume` | Resume | Retomar |
| `recovery_discard` | Discard | Descartar |

### 7.2 Regras

- Sempre maiúsculas para labels de fase (`FOCUS`, `BREAK`).
- Nunca emoji (manual Toma proíbe expressamente).
- Nunca "Great job!", "Awesome!", "Welcome back!". Apenas informação.
- Mensagens curtas (3-4 palavras quando possível).

---

## 8. Ícone do app (launcher)

### 8.1 Asset original

`manual-de-marca/logo/toma_icon.svg`:
- Talo verde (`#2ECC71`).
- Corpo vermelho (`#E8432D`), círculo simples.
- Sem texto, sem sombra.

### 8.2 Adaptação Connect IQ

Connect IQ exige PNG de tamanhos específicos por device. Tamanhos comuns:
- 60×60 (FR255 launcher)
- 80×80 (large devices)

**Estratégia:** rasterizar o SVG nos tamanhos requisitados, fundo transparente.

**Para MIP devices (64 cores):**
- O verde do talo (`#2ECC71`) e o vermelho (`#E8432D`) ficam distintos após mapping. ✅
- Validar no simulador FR255.

### 8.3 Hero image (Connect IQ Store)

Para a página da Store, criar:
- **500×500** com logo centralizado em `#0C0C0C`.
- **Screenshot showcase** (montar 3 telas: Home, Timer, Cycle Complete) com legendas em Inter.

---

## 9. Checklist de consistência (antes de finalizar uma View)

- [ ] Fundo é `Rez.Colors.bg` (`#0C0C0C`)
- [ ] Texto principal é `Rez.Colors.textPrimary` (`#F5F0EB`) — nunca branco puro
- [ ] Display do timer usa `FONT_NUMBER_*`
- [ ] Labels usam `FONT_MEDIUM` ou `FONT_SMALL`
- [ ] Nenhuma cor hex hardcoded no código (`source/`)
- [ ] Nenhuma string hardcoded no código (`source/`)
- [ ] Nenhuma dimensão hardcoded no código (`source/`)
- [ ] Anel do timer tem cor adequada ao estado (ver tabela 2.2)
- [ ] Phase label em uppercase
- [ ] Sem emoji em strings
- [ ] Tom de voz direto (3-4 palavras quando possível)
- [ ] Testado visualmente nos 3 buckets (small/medium/large)
- [ ] Validado em ao menos um device MIP e um AMOLED no simulador
