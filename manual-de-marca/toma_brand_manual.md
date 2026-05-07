# Toma — Manual de Marca
**Versão 1.0**

> Pomodoro. Sem ornamento. Para quem escreve código.

---

## 1. Conceito

**Toma** é um app de Pomodoro com hacker mindset — uma ferramenta de dev para dev. A experiência é dark mode minimalista, inspirada em Linear, Raycast e Notion. Sem mascotes, sem gamificação colorida, sem notificações animadas. Só o timer, o foco e o código.

**Nome:** Toma é um truncamento direto de *tomato*. Bilíngue — funciona em português e inglês. Sonoridade curta, assertiva, fácil de lembrar. Não precisa de explicação.

**Posicionamento:** Ferramenta de produtividade para desenvolvedores que preferem ferramentas parecidas com o ambiente onde trabalham — escuro, preciso, sem ruído.

---

## 2. Paleta de Cores

| Token | Nome | Hex | Uso |
|---|---|---|---|
| `--color-bg` | Deep Black | `#0C0C0C` | Fundo principal |
| `--color-surface` | Surface | `#161616` | Cards, modais |
| `--color-elevated` | Elevated | `#1F1F1F` | Elementos sobrepostos |
| `--color-brand` | Toma Red | `#E8432D` | Cor de marca, CTAs, anel do timer |
| `--color-accent` | Ember | `#FF6B47` | Estado ativo do timer, hover |
| `--color-text-primary` | Warm White | `#F5F0EB` | Texto principal |
| `--color-text-muted` | Muted | `#888888` | Texto secundário, labels |
| `--color-border` | Border | `#2A2A2A` | Bordas e divisores |

### Regras de uso

- **Toma Red** (`#E8432D`) é a única cor de marca. Use para o anel do timer, botões primários e destaques.
- **Ember** (`#FF6B47`) só aparece em estados ativos — timer rodando, hover em CTAs. Nunca como cor de fundo estática.
- **Warm White** (`#F5F0EB`) é o texto — nunca branco puro (`#FFFFFF`), que gera contraste agressivo demais em dark mode.
- O fundo principal é `#0C0C0C` e não preto puro — preto absoluto cansa os olhos e destoa do padrão de ferramentas de dev.
- Nunca use gradientes ou sombras com glow. Superfícies planas, bordas finas.

---

## 3. Tipografia

### Display — Timer
**JetBrains Mono**
- Uso: countdown do timer, números de sessão, qualquer exibição de tempo
- Peso: Regular (400)
- Licença: Open Font License — gratuita para uso comercial
- Download: [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/)

```
Exemplo: 25:00 — Session 1
```

> Criada por JetBrains especificamente para desenvolvedores. Formas simples e sem detalhes desnecessários, mais nítida em tamanhos pequenos. Reforça o hacker mindset da marca.

### Interface — UI
**Inter**
- Uso: labels, botões, descrições, mensagens do sistema, toda a interface
- Pesos: Regular (400) para corpo, Medium (500) para ênfase. Nunca Bold (700).
- Licença: Open Font License — gratuita para uso comercial
- Download: [rsms.me/inter](https://rsms.me/inter/)

```
Exemplo: Focus session · Skip · Start
```

> Usada por Linear, Vercel e Figma. Padrão de ouro para interfaces dark mode minimalistas.

### Hierarquia tipográfica

| Elemento | Fonte | Tamanho | Peso |
|---|---|---|---|
| Timer display | JetBrains Mono | 42–48px | 400 |
| Headings | Inter | 18–22px | 500 |
| Labels / botões | Inter | 13–14px | 500 |
| Corpo / descrições | Inter | 14–16px | 400 |
| Metadados / hints | Inter | 11–12px | 400 |

---

## 4. Logo

### Conceito
Ícone minimalista: um círculo **Toma Red** representando o corpo do tomate + um talo verde simples. Sem textura, sem sombra, sem gradiente. O wordmark usa **Inter lowercase** — nunca caixa alta.

### Estrutura
```
[ ● ] toma
  ^
  Círculo Toma Red (#E8432D)
  Talo verde (#2ECC71 sobre fundo escuro / #1A6B3C sobre fundo claro)
  Wordmark Inter Medium lowercase, kerning -0.02em
```

### Versões
- **Dark background** — ícone Toma Red + talo verde, wordmark Warm White (`#F5F0EB`)
- **Light background** — ícone Toma Red + talo verde escuro, wordmark Deep Black (`#0C0C0C`)
- **Ícone isolado** — apenas o círculo vermelho + talo, sem wordmark (uso em favicons, ícones de app)

### Proibido
- Não altere as cores do logo
- Não use o wordmark em caixa alta (TOMA)
- Não adicione sombras, gradientes ou efeitos ao ícone
- Não use o logo em fundos com baixo contraste
- Não distorça as proporções

---

## 5. Tom de Voz

A voz do Toma é **direta, técnica e sem floreio**. Pense em um desenvolvedor escrevendo um README: informação crua, sem marketing speak, sem emojis de tomate.

### Sim
- _"25 minutes. No meetings. No noise."_
- _"Session complete. 4 blocks = 1 full cycle."_
- _"Break. 5 min."_
- _"You stopped. Start again when ready."_

### Não
- _"Welcome back! Ready to boost your productivity today? 🍅"_
- _"Great job! You're on fire! Keep it up!"_
- _"Oops! Looks like something went wrong 😅"_
- Emojis de tomate em qualquer contexto

### Princípios
1. **Imperativo, não motivacional.** O app não torce por você — ele registra.
2. **Informação antes de encorajamento.** Dados primeiro, celebração nunca.
3. **Sem antropomorfização.** O app não tem personalidade jovial. É uma ferramenta.
4. **Minimalismo verbal.** Se pode dizer em 3 palavras, não use 10.

---

## 6. UI — Princípios de Interface

- **Dark first.** O design nasce em dark mode. Light mode é derivado, não o contrário.
- **Superfícies planas.** Sem gradientes, sem drop shadows, sem glow. Elevação via cor de fundo (`#161616` → `#1F1F1F`).
- **Bordas de 0.5px.** Nunca bordas de 1px ou 2px em elementos de UI — muito pesado para o estilo.
- **Border-radius: 8px** para componentes, **12px** para cards. Nunca radius excessivo.
- **Espaçamento:** múltiplos de 4px (4, 8, 12, 16, 24, 32).
- **Um único foco visual por tela.** No estado de foco, só o timer existe. Sem sidebar, sem notificações, sem distrações.

---

## 7. Tokens CSS — Referência Rápida

```css
:root {
  /* Cores */
  --color-bg:           #0C0C0C;
  --color-surface:      #161616;
  --color-elevated:     #1F1F1F;
  --color-border:       #2A2A2A;
  --color-brand:        #E8432D;
  --color-accent:       #FF6B47;
  --color-text-primary: #F5F0EB;
  --color-text-muted:   #888888;

  /* Tipografia */
  --font-display: 'JetBrains Mono', monospace;
  --font-ui:      'Inter', sans-serif;

  /* Espaçamento */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;

  /* Border radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

---

## 8. Checklist de Consistência

Antes de publicar qualquer tela ou asset do Toma, verifique:

- [ ] Fundo usa `#0C0C0C` (não preto puro `#000000`)
- [ ] Texto usa Warm White `#F5F0EB` (não branco puro `#FFFFFF`)
- [ ] Timer display usa JetBrains Mono
- [ ] Interface usa Inter, máximo peso 500
- [ ] Nenhum gradiente ou sombra decorativa
- [ ] Bordas de 0.5px–1px no máximo
- [ ] Tom de voz direto, sem emojis, sem exclamações entusiasmadas
- [ ] Logo wordmark em lowercase

---

*Toma — Manual de Marca v1.0*
