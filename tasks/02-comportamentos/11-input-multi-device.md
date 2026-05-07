# Task 02-11: Input Multi-Device + Sleep Prevention

## Objetivo

Garantir que **B14** (Input multi-device) e **B15** (Sleep prevention) estão funcionando corretamente em todos os devices alvo. Inclui:
- Validar que botões (FR255) e touch (FR265, FR965, Venu 3) funcionam para todas as ações.
- Confirmar mapeamento de inputs no `BehaviorDelegate`.
- Adicionar `Attention.backlight(true)` em transições de fase para garantir visibilidade.
- Testar em simulador para todos buckets, pelo menos um device físico.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B14** Input multi-device — `spec/spec.md` §4.B14
- **B15** Sleep prevention durante sessão — `spec/spec.md` §4.B15

## Dependências

- Todas as tasks de protótipo (Bloco 01) e funcionais (`02-01` a `02-10`).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings em todos devices listados em `references/garmin_platform.md` §1.
- [ ] `--typecheck=Strict` passa.
- [ ] `monkey.jungle` corretamente declara `excludeAnnotations` para `:hasTouch`/`:noTouch` se necessário.

### Manual — por device class

#### MIP no-touch (FR255, FR255S, FR955, Fenix 7)

- [ ] Up/Down: navega.
- [ ] Enter: confirm/select/play-pause.
- [ ] Back: volta/cancel.
- [ ] Long-press Up (Menu): abre Settings em Home.
- [ ] Em P3: backlight acende em transição de fase (ver visualmente no simulador → log).

#### AMOLED touch (FR265, FR965, Venu 3, Venu 3S, Vivoactive 5, Fenix 8)

- [ ] Tap centro: confirm.
- [ ] Swipe right: back.
- [ ] Swipe up/down: navega listas (Home, Settings, History).
- [ ] Tap longo: menu (em devices que suportam).
- [ ] Botões físicos também funcionam (mesmo que touch funcione).
- [ ] Em AMOLED, screen permanece ativo durante sessão sem dim agressivo.

#### Edge cases

- [ ] DND ativo: vibração não dispara, mas timer continua.
- [ ] Bateria baixa: app continua funcionando (testar simulador com low battery setting).

## Arquivos esperados

### Novos

- (provável) `source/delegates/<View>Delegate.mc` ajustes — não novos arquivos.

### Modificados

- Todos os Delegates: revisar `onSelect`, `onBack`, `onMenu`, `onSwipe`, `onPreviousPage`, `onNextPage`.
- `source/services/AttentionService.mc` — assegurar `_flashBacklight()` é chamado em transições.
- `monkey.jungle` — assegurar todos os devices estão listados; revisar annotations.

## Referências obrigatórias

- `references/architecture.md` §5 (multi-device strategy).
- `references/garmin_platform.md` §1 (devices), §3 (capability detection), §6 (sleep).
- `spec/spec.md` §4.B14, §4.B15.

## Especificação técnica

### BehaviorDelegate semantic mapping

| Method | FR (button) | AMOLED (touch) | Comportamento |
|---|---|---|---|
| `onSelect()` | Enter | Tap centro | Confirm / Play-Pause |
| `onBack()` | Back | Swipe right | Cancel / Voltar |
| `onMenu()` | Menu (long-press up) | Long-press centro | Abrir menu (P8) |
| `onPreviousPage()` | Up (botão) | Swipe up | Item anterior |
| `onNextPage()` | Down (botão) | Swipe down | Próximo item |

`BehaviorDelegate` já abstrai isso — basta sobrescrever. Validar que cada Delegate implementa corretamente.

### Touch-specific extras

Em devices `:hasTouch`, podemos adicionar `onSwipe` para gestos não-padrão:

```monkeyc
class TimerDelegate extends Ui.BehaviorDelegate {
    function onSwipe(swipeEvent) as Boolean {
        var dir = swipeEvent.getDirection();
        if (dir == Ui.SWIPE_DOWN) {
            // Pull-down para abrir Settings? Decisão UX.
            return false;
        }
        return false;
    }
}
```

**Decisão V1:** não adicionar gestos extras. Touch usa só os mappings semânticos do BehaviorDelegate.

### Sleep prevention

Connect IQ não tem API "screenStaysOn(true)". Estratégia:
- App em foreground = device mantém screen ativa (gestures levantar pulso, etc., mantêm).
- Em transições de fase, chamar `Attention.backlight(true)` se `backlightOnAlert` setting está on.

**Já implementado em `02-03-vibracao-inicio-fim`.** Esta task valida que está funcionando em devices reais.

### Annotations para multi-device

`monkey.jungle` exemplo (já está em garmin_platform.md, validar):

```
project.manifest = manifest.xml
base.sourcePath = source

# Common excludes
common_excludes = test

fr255.excludeAnnotations = $(common_excludes);amoled;hasTouch;hasSpeaker
fr255s.excludeAnnotations = $(common_excludes);amoled;hasTouch;hasSpeaker
fr255m.excludeAnnotations = $(common_excludes);amoled;hasTouch
fr265.excludeAnnotations = $(common_excludes);mip;noTouch
fr265s.excludeAnnotations = $(common_excludes);mip;noTouch
fr955.excludeAnnotations = $(common_excludes);amoled;hasSpeaker  # FR955 é MIP mas TEM touch — verificar
fr965.excludeAnnotations = $(common_excludes);mip;noTouch;hasSpeaker
fenix7.excludeAnnotations = $(common_excludes);amoled;hasTouch;hasSpeaker
fenix847mm.excludeAnnotations = $(common_excludes);mip;noTouch
venu3.excludeAnnotations = $(common_excludes);mip;noTouch
vivoactive5.excludeAnnotations = $(common_excludes);mip;noTouch;hasSpeaker
# ... outros
```

**Validar IDs reais nos device packages instalados.**

### Compilação multi-device

Build script para testar todos:

```bash
#!/bin/bash
DEVICES=(fr255 fr255s fr265 fr265s fr955 fr965 fenix7 venu3 vivoactive5)
for d in "${DEVICES[@]}"; do
    echo "Building for $d..."
    monkeyc -d "$d" -f monkey.jungle -o "build/toma_$d.prg" -y "$KEY" -w
    if [ $? -ne 0 ]; then
        echo "FAILED on $d"
        exit 1
    fi
done
echo "All builds OK"
```

Salvar em `scripts/build-all.sh`.

## Out of scope desta task

- Gestures customizados (V2).
- Always-on watch face mode (não aplica a app full).
- Tilt-to-wake customization (V2).
