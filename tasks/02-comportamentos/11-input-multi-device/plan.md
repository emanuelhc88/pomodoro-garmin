# Plan — Task 02-11: Input Multi-Device + Sleep Prevention

> Spec Tática gerada na FASE 2.3. Executar com `/execute` na próxima sessão.

---

## 1. Resumo

Expandir `manifest.xml` para 15 devices, configurar `monkey.jungle` com `excludeAnnotations` corretas por device class, adicionar `onMenu()` ao `TimerDelegate` para abrir Settings durante sessão, e criar `scripts/build-all.sh` para validação de compilação cross-device.

## 2. Cenários

### Caminho feliz
1. Build compila sem erros para todos os 15 devices.
2. Em qualquer device, long-press Menu durante timer abre Settings.
3. Após ajustar setting, volta ao timer sem perder estado.
4. Backlight acende em transição de fase (já implementado — validar que funciona nos devices novos).

### Edge cases
- Device com touch + botões (FR955, FR965, Fenix 8): ambos os inputs funcionam simultaneamente (BehaviorDelegate cuida disso).
- `onMenu` retorna `true` para impedir propagação do evento.
- Se `SettingsMenu` é aberto durante timer pausado ou rodando, ao voltar o estado é preservado (timer continua/continua pausado).

### Erros
- Device ID inválido no manifest → build falha → script `build-all.sh` reporta qual device falhou.
- Compilação com `excludeAnnotations` de annotation não usada → nenhum impacto (Connect IQ ignora annotations sem código associado).

---

## 3. Arquivos a CRIAR

| # | Path | Responsabilidade |
|---|---|---|
| 1 | `scripts/build-all.sh` | Script bash que compila o app para cada um dos 15 devices e reporta sucesso/falha |

---

## 4. Arquivos a MODIFICAR

| # | Path | O que muda |
|---|---|---|
| 1 | `manifest.xml` | Expandir `<iq:products>` de 3 para 15 devices |
| 2 | `monkey.jungle` | Adicionar `excludeAnnotations` por device class |
| 3 | `source/delegates/TimerDelegate.mc` | Adicionar `onMenu()` que abre SettingsMenu |

### 4.1 `manifest.xml`

**Antes:**
```xml
<iq:products>
    <iq:product id="fr255"/>
    <iq:product id="fr255s"/>
    <iq:product id="fr265"/>
</iq:products>
```

**Depois:**
```xml
<iq:products>
    <iq:product id="fr255"/>
    <iq:product id="fr255s"/>
    <iq:product id="fr255m"/>
    <iq:product id="fr265"/>
    <iq:product id="fr265s"/>
    <iq:product id="fr955"/>
    <iq:product id="fr965"/>
    <iq:product id="fenix7"/>
    <iq:product id="fenix7pro"/>
    <iq:product id="fenix843mm"/>
    <iq:product id="fenix847mm"/>
    <iq:product id="epix2"/>
    <iq:product id="venu3"/>
    <iq:product id="venu3s"/>
    <iq:product id="vivoactive5"/>
</iq:products>
```

### 4.2 `monkey.jungle`

**Antes:**
```
project.manifest = manifest.xml

base.sourcePath = source;tests
base.resourcePath = resources;resources-por
```

**Depois:**
```
project.manifest = manifest.xml

base.sourcePath = source;tests
base.resourcePath = resources;resources-por
base.excludeAnnotations = test

# MIP no-touch no-speaker
fr255.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker
fr255s.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker

# MIP no-touch has-speaker
fr255m.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch

# MIP no-touch no-speaker
fenix7.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker
fenix7pro.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker

# MIP has-touch no-speaker
fr955.excludeAnnotations = $(base.excludeAnnotations);amoled;noTouch;hasSpeaker

# AMOLED has-touch no-speaker
fr265.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
fr265s.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
fr965.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
epix2.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
vivoactive5.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker

# AMOLED has-touch has-speaker
fenix843mm.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
fenix847mm.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
venu3.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
venu3s.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
```

**Justificativa da classificação (baseada em `garmin_platform.md` §1):**

| Device | Display | Touch | Speaker | Excludes |
|---|---|---|---|---|
| fr255 | MIP | ❌ | ❌ | amoled;hasTouch;hasSpeaker |
| fr255s | MIP | ❌ | ❌ | amoled;hasTouch;hasSpeaker |
| fr255m | MIP | ❌ | ✅ | amoled;hasTouch |
| fenix7 | MIP | ❌ | ❌ | amoled;hasTouch;hasSpeaker |
| fenix7pro | MIP | ❌ | ❌ | amoled;hasTouch;hasSpeaker |
| fr955 | MIP | ✅ | ❌ | amoled;noTouch;hasSpeaker |
| fr265 | AMOLED | ✅ | ❌ | mip;noTouch;hasSpeaker |
| fr265s | AMOLED | ✅ | ❌ | mip;noTouch;hasSpeaker |
| fr965 | AMOLED | ✅ | ❌ | mip;noTouch;hasSpeaker |
| epix2 | AMOLED | ✅ | ❌ | mip;noTouch;hasSpeaker |
| vivoactive5 | AMOLED | ✅ | ❌ | mip;noTouch;hasSpeaker |
| fenix843mm | AMOLED | ✅ | ✅ | mip;noTouch |
| fenix847mm | AMOLED | ✅ | ✅ | mip;noTouch |
| venu3 | AMOLED | ✅ | ✅ | mip;noTouch |
| venu3s | AMOLED | ✅ | ✅ | mip;noTouch |

### 4.3 `source/delegates/TimerDelegate.mc`

**Antes:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        var view = new ConfirmStopView();
        Ui.pushView(view, new ConfirmStopDelegate(view), Ui.SLIDE_UP);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        if (app.getModel().isPaused()) {
            app.resumeSession();
        } else {
            app.pauseSession();
        }
        return true;
    }
}
```

**Depois:**
```monkeyc
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        var view = new ConfirmStopView();
        Ui.pushView(view, new ConfirmStopDelegate(view), Ui.SLIDE_UP);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var app = App.getApp() as TomaApp;
        if (app.getModel().isPaused()) {
            app.resumeSession();
        } else {
            app.pauseSession();
        }
        return true;
    }

    function onMenu() as Lang.Boolean {
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}
```

---

## 5. Storage/Properties

Não aplicável. Esta task não adiciona keys de persistência.

---

## 6. Checklist de execução

- [x] 1. Criar diretório `scripts/` (se não existir)
- [x] 2. Modificar `manifest.xml` — expandir `<iq:products>` para 15 devices
- [x] 3. Modificar `monkey.jungle` — adicionar `base.excludeAnnotations` e linhas por device
- [x] 4. Modificar `source/delegates/TimerDelegate.mc` — adicionar método `onMenu()`
- [x] 5. Criar `scripts/build-all.sh` com script de compilação cross-device
- [x] 6. Tornar `scripts/build-all.sh` executável (`chmod +x`)
- [x] 7. Executar `scripts/build-all.sh` e corrigir eventuais erros de compilação
- [ ] 8. Testar no simulador: fr255 (MIP no-touch), fr265 (AMOLED touch), fr955 (MIP touch)

---

## 7. Critérios de aceite

### Automated
- [x] `monkeyc -d fr255` compila sem erros
- [x] `monkeyc -d fr255s` compila sem erros
- [x] `monkeyc -d fr255m` compila sem erros
- [x] `monkeyc -d fr265` compila sem erros
- [x] `monkeyc -d fr265s` compila sem erros
- [x] `monkeyc -d fr955` compila sem erros
- [x] `monkeyc -d fr965` compila sem erros
- [x] `monkeyc -d fenix7` compila sem erros
- [x] `monkeyc -d fenix7pro` compila sem erros
- [x] `monkeyc -d fenix843mm` compila sem erros
- [x] `monkeyc -d fenix847mm` compila sem erros
- [x] `monkeyc -d epix2` compila sem erros
- [x] `monkeyc -d venu3` compila sem erros
- [x] `monkeyc -d venu3s` compila sem erros
- [x] `monkeyc -d vivoactive5` compila sem erros

### Manual (simulador)
- [ ] FR255: Enter pausa/resume timer, Back abre ConfirmStop, Menu (long-press Up) abre Settings
- [ ] FR265: Tap centro pausa/resume, Swipe right abre ConfirmStop, Long-press abre Settings
- [ ] FR955: Ambos botões e touch funcionam (MIP com touch)
- [ ] Settings aberto durante timer: ao voltar, timer continua no estado correto
- [ ] Backlight acende em transição de fase (visível no log do simulador)

---

## 8. Out of scope
- Gestures customizados além dos mapeamentos do BehaviorDelegate (V2)
- Código com annotations `:mip`/`:amoled`/`:hasTouch`/`:noTouch` (este plan só configura as annotations no jungle — código annotado virá em tasks futuras de diferenciação visual)
- Always-on display mode
- Tilt-to-wake customization
- `fr255sm` (device package não instalado — incluir quando disponível)
