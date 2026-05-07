# Task 02-12: Localização PT/EN + Polish Final

## Objetivo

Finalizar tradução PT, validar reatividade ao setting "Language", revisar todas as strings (sem hardcoded), e fazer o polish final antes de empacotar para a Connect IQ Store.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B13** Internacionalização PT/EN — `spec/spec.md` §4.B13
- Polish e prep de release V1.

## Dependências

- **Todas** as tasks anteriores (Bloco 01 + `02-01` a `02-11`).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings em todos devices, `--typecheck=Strict` passa.
- [ ] **Linter custom**: nenhum string hardcoded em arquivos `source/views/`, `source/delegates/`, `source/ui/`. (Implementar via grep simples no script de build se possível.)
- [ ] Todas as strings declaradas em `strings.xml` (en) também existem em `strings_pt.xml`.
- [ ] Build release `.iq` multi-device produzido com sucesso.

### Manual

- [ ] Setting Language = "Auto" + device em inglês → app em inglês.
- [ ] Setting Language = "Auto" + device em português → app em português.
- [ ] Setting Language = "English" override device em PT → app em inglês.
- [ ] Setting Language = "Português" override device em EN → app em português.
- [ ] Mudança de language em runtime: ao voltar para Home, strings refletem (pode requerer reabrir certas views).
- [ ] **Visual review** completo:
  - Home: paleta, fontes, layout.
  - Custom Builder: edição funciona em ambos idiomas.
  - Timer Running: phase labels traduzidos.
  - Phase Transition: textos grandes traduzidos.
  - Cycle Complete: contagem + botões.
  - History: data formatada conforme locale, header.
  - Settings: todos os items + sub-menus.
- [ ] **Visual review nos 3 buckets** (small/medium/large) e em ambos display types (MIP/AMOLED).
- [ ] Memory profiling: heap < 512 KB no FR255S (target mais apertado).
- [ ] Crash test: bater Back rapidamente em todas as views, alternar settings rapidamente, kill+reopen → sem crashes.

## Arquivos esperados

### Novos

- `scripts/check-strings.sh` — script que faz `grep` por strings literais em `source/views/` e `source/delegates/` e falha se encontra.
- `scripts/build-release.sh` — gera `.iq` multi-device.
- `README.md` (na raiz) — basic project README com link para references e tasks.

### Modificados

- Possivelmente vários arquivos com strings hardcoded esquecidas — varredura final.
- `resources/strings/strings_pt.xml` — completar todas as strings que possam estar faltando.
- `manifest.xml` — confirmar `<iq:language>eng</iq:language>` e `<iq:language>por</iq:language>`.
- `source/utils/TimeFormatter.mc` — formato de data locale-aware (May vs Mai).

## Referências obrigatórias

- `references/design_system.md` §7 (glossário PT/EN).
- `spec/spec.md` §4.B13.

## Especificação técnica

### Como Connect IQ resolve idioma

Manifest declara línguas:
```xml
<iq:languages>
    <iq:language>eng</iq:language>
    <iq:language>por</iq:language>
</iq:languages>
```

Strings em:
- `resources/strings/strings.xml` (default = inglês)
- `resources-por/strings/strings.xml` ou `resources-pt/strings/strings.xml` (português — verificar exact path convention do Connect IQ)

Connect IQ resolve automaticamente baseado em `System.getDeviceSettings().systemLanguage`.

### Override manual via Setting

Se setting `language != "auto"`, precisamos forçar resolução. Connect IQ **não** tem API direta para isso. Estratégia:

1. Manter um único strings.xml.
2. Usar `Lang.format` com fallback manual.

OU:

1. Manter strings em ambos, e resolver via `loadResource` direto:

```monkeyc
function getString(key as Symbol) as String {
    var lang = _settingsRepo.getLanguage();
    if (lang == "auto") {
        return Ui.loadResource(key) as String;  // Connect IQ resolve
    }
    // Override: load do recurso específico do idioma
    // (NÃO há API para isso — Connect IQ não permite forçar locale)
    // Workaround: dois arquivos resources e bilinguageMap manual
    return Ui.loadResource(key) as String;
}
```

**Decisão dura:** Connect IQ **não permite override manual** de locale. Setting "Language" terá de ser informativa: "Auto" sempre, com sub-label mostrando qual está ativo.

**Mudança no V1:**
- Remover opções "English" / "Português" do setting Language.
- Manter apenas "Auto" (read-only ou escondido).
- Documentar limitação no About / Help.

OU, mais elegante:
- Implementar nossa própria camada de strings via `getString(key)` que decide entre dois dicionários PT/EN baseado em setting.
- Não usar `Rez.Strings` direto nas views — todo lookup via wrapper.

**Recomendação para V1:** **opção wrapper**. Mais trabalho (~1-2h), mas dá controle total e é manutenível.

```monkeyc
module Strings {
    private var _en as Dictionary = {
        :app_name => "Toma",
        :phase_focus => "FOCUS",
        :phase_break => "BREAK",
        // ... todas as strings
    };

    private var _pt as Dictionary = {
        :app_name => "Toma",
        :phase_focus => "FOCO",
        :phase_break => "PAUSA",
        // ...
    };

    function get(key as Symbol) as String {
        var lang = _resolveLang();
        var dict = (lang == "pt") ? _pt : _en;
        return dict[key];
    }

    private function _resolveLang() as String {
        var setting = _settingsRepo.getLanguage();
        if (setting != "auto") { return setting; }
        var sysLang = Sys.getDeviceSettings().systemLanguage;
        if (sysLang.equals("por") || sysLang.equals("pt")) { return "pt"; }
        return "en";
    }
}
```

Views chamam `Strings.get(:phase_focus)` em vez de `Ui.loadResource(Rez.Strings.phase_focus)`.

**Trade-off:**
- Pro: controle total, override funciona, format strings simples.
- Contra: strings em código (não em XML), sem auto-localization para futuros idiomas (mas V1 só PT/EN, não importa).
- Contra: menor compatibilidade com ferramentas Garmin de tradução.

**Decisão final:** ir com wrapper. Migrar para Rez.Strings na V2 se precisar mais idiomas.

### Linter de strings hardcoded

`scripts/check-strings.sh`:

```bash
#!/bin/bash
# Falha se encontrar string literal em source/views/ ou source/delegates/

if grep -rn '"[A-Z][a-z][^"]*"' source/views source/delegates source/ui --include='*.mc' \
   | grep -v 'using ' \
   | grep -v 'method(' \
   | head -1; then
    echo "ERROR: hardcoded strings found above. Use Strings.get(:key) instead."
    exit 1
fi
echo "No hardcoded strings — OK"
```

Não é perfeito (vai dar false positives e false negatives), mas pega os casos mais óbvios.

### Build release multi-device

`scripts/build-release.sh`:

```bash
#!/bin/bash
set -e
mkdir -p build
monkeyc -e -f monkey.jungle -o build/toma.iq -y "$HOME/.connect-iq/developer_key.der" -r
echo "Release build at build/toma.iq"
ls -lh build/toma.iq
```

`-e` = export para `.iq` (multi-device package, pronto pra Store).

### README.md na raiz

```markdown
# Toma

Pomodoro for Garmin. Built with Monkey C and Connect IQ.

> Pomodoro. Sem ornamento. Para quem escreve código.

## Quick start

See `tasks/00-setup/README.md` for environment setup.

## Architecture

- `references/architecture.md` — code structure and conventions.
- `references/design_system.md` — visual design language.
- `references/garmin_platform.md` — Connect IQ APIs used.
- `references/workflow.md` — SDD workflow.
- `references/benchmark.md` — competitive landscape.

## Spec

- `spec/spec.md` — full product spec (pages, components, behaviors).

## Tasks

- `tasks/00-setup/` — environment.
- `tasks/01-prototipos-visuais/` — UI mockups (8 tasks).
- `tasks/02-comportamentos/` — logic and integrations (12 tasks).

## License

TBD.
```

## Out of scope desta task

- Idiomas além de PT/EN (V2).
- Per-device language differences (V2).
- Crowdsourced translations (V2+).

---

## Após esta task: V1 está pronta para a Store

Checklist final:

- [ ] Todas as 21 tasks (1 setup + 8 protótipos + 12 comportamentos) concluídas.
- [ ] Build release `.iq` produzido sem warnings.
- [ ] Testado em FR255 físico + simulador para todos devices alvo.
- [ ] Memory profiling: < 512 KB heap.
- [ ] Sem crashes em fluxos golden e edge cases.
- [ ] Strings 100% traduzidas.
- [ ] Assets para Store: ícone 500×500, hero image, screenshots × 5.
- [ ] Descrição da Store escrita em PT e EN.
- [ ] Submeter `.iq` em [apps.garmin.com/developer](https://apps.garmin.com/developer).

Após aprovação Garmin (~5 dias), V1 está live na Connect IQ Store. 🎉
