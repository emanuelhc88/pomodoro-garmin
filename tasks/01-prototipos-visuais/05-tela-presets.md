# Task 01-05: Tela Presets (refinamento)

## Objetivo

Refinar a **P1 (Home / Preset Picker)** para suportar todos os 4 presets reais com renderização correta do conteúdo de cada um:
- 25 / 5 · 4 ciclos
- 30 / 5 · 4 ciclos
- 50 / 10 · 4 ciclos
- Custom (mostrando os valores atuais salvos, ou "Configure" se nunca foi editado)

Mais o item Settings já implementado na task 01.

Esta task é separada da 01-tela-home porque foca em **dados de preset** corretamente formatados, não no layout em si.

## Tipo

- [x] Protótipo Visual

## Cobre

- **P1** (refinamento) — `spec/spec.md` §2.P1
- **C7** Preset Card (variantes para os 4 presets)

## Dependências

- `tasks/01-prototipos-visuais/01-tela-home.md`.

## Critério de aceitação

### Automated

- [ ] Compila e roda nos 3 buckets.
- [ ] `--typecheck=Strict` passa.

### Manual

- [ ] 4 presets builtin renderizam com formato correto:
  - "25 / 5" (linha 1, FONT_NUMBER_MEDIUM)
  - "4 cycles" (linha 2, FONT_TINY, textMuted)
- [ ] Preset Custom mostra valores atuais (default 25/5/4 — ainda hardcoded, persistência vem em `02-08`).
- [ ] Indicador visual diferente para Custom (ex: pequeno ícone "✏" ou texto "Custom" no topo do card).
- [ ] Strings traduzem: "cycles" → "ciclos" em PT.
- [ ] Dots indicator: 5 dots (4 presets + Settings) — settings dot pode ser visualmente distinto (ex: outline em vez de filled).

## Arquivos esperados

### Novos

- `source/model/Preset.mc` — tipo `Preset { workMin, breakMin, cycles, isCustom, label }`. **Apenas o struct + helper de formatação**, sem lógica de timer ainda.

### Modificados

- `source/views/HomeView.mc` — usar lista de Presets em vez de strings hardcoded.
- `source/ui/components/PresetCard.mc` — receber `Preset` em vez de strings, renderizar formatos diferentes para builtin vs custom.
- `resources/strings/strings.xml` + `strings_pt.xml` — adicionar `unit_cycles` ("cycles" / "ciclos"), `preset_custom_label` ("Custom" / "Personalizado").

## Referências obrigatórias

- `references/architecture.md` §2 (estrutura `source/model/`).
- `references/design_system.md` §5 (componentes).
- `spec/spec.md` §2.P1, §6 (regras de negócio — limites Custom).

## Notas de design

### Preset.mc

```monkeyc
class Preset {
    public var workMin as Number;
    public var breakMin as Number;
    public var cycles as Number;
    public var isCustom as Boolean;

    function initialize(workMin, breakMin, cycles, isCustom) {
        self.workMin = workMin;
        self.breakMin = breakMin;
        self.cycles = cycles;
        self.isCustom = isCustom;
    }

    function formatPrimary() as String {
        return Lang.format("$1$ / $2$", [workMin, breakMin]);
    }

    function formatSecondary() as String {
        var label = WatchUi.loadResource(Rez.Strings.unit_cycles) as String;
        return Lang.format("$1$ $2$", [cycles, label]);
    }
}

module Presets {
    function builtinList() as Array<Preset> {
        return [
            new Preset(25, 5, 4, false),
            new Preset(30, 5, 4, false),
            new Preset(50, 10, 4, false),
            new Preset(25, 5, 4, true)  // valores default do Custom
        ];
    }
}
```

### Preset Custom — visual diferenciado

Sugestão: pequeno texto "CUSTOM" / "PERSONALIZADO" no topo do card (FONT_XTINY, cor accent), acima dos números. Os números abaixo permanecem no mesmo formato.

### Settings card

Já existe da task 01. Apenas verificar que continua funcionando após mudança da estrutura de dados.

## Out of scope desta task

- Persistência do Custom (`02-08-persistencia-settings`).
- Editor do Custom (próxima task `01-06`).
- Salvar `lastSelectedPreset` (`02-08`).
