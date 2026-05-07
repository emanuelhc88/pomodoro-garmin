# Toma — Garmin Platform Reference

> Cheatsheet técnico do Connect IQ aplicado ao Toma. Consultar em toda task que toca APIs Garmin.

Este documento é o destilado da documentação oficial Garmin focado **só no que o Toma usa**. Não é tutorial. É referência para a IA não alucinar nomes de API, parâmetros ou comportamento de devices.

---

## 1. Devices suportados (V1)

Connect IQ System 7+ apenas. `minSdkVersion="4.1.0"` no manifest.

| Device | Jungle ID | Display | Resolução | Touch | Vibração | Speaker | Class |
|---|---|---|---|---|---|---|---|
| Forerunner 255 | `fr255` | MIP | 260×260 | ❌ | ✅ | ❌ | `:mip` `:noTouch` |
| Forerunner 255S | `fr255s` | MIP | 218×218 | ❌ | ✅ | ❌ | `:mip` `:noTouch` `:small` |
| Forerunner 255 Music | `fr255m` | MIP | 260×260 | ❌ | ✅ | ✅ | `:mip` `:noTouch` `:hasSpeaker` |
| Forerunner 255S Music | `fr255sm` | MIP | 218×218 | ❌ | ✅ | ✅ | `:mip` `:noTouch` `:small` `:hasSpeaker` |
| Forerunner 265 | `fr265` | AMOLED | 416×416 | ✅ | ✅ | ❌ | `:amoled` `:hasTouch` |
| Forerunner 265S | `fr265s` | AMOLED | 360×360 | ✅ | ✅ | ❌ | `:amoled` `:hasTouch` `:small` |
| Forerunner 955 | `fr955` | MIP | 260×260 | ✅ | ✅ | ❌ | `:mip` `:hasTouch` |
| Forerunner 965 | `fr965` | AMOLED | 454×454 | ✅ | ✅ | ❌ | `:amoled` `:hasTouch` |
| Fenix 7 | `fenix7` | MIP | 260×260 | ❌ | ✅ | ❌ | `:mip` `:noTouch` |
| Fenix 7 Pro | `fenix7pro` | MIP | 260×260 | ❌ | ✅ | ❌ | `:mip` `:noTouch` |
| Fenix 8 (47mm AMOLED) | `fenix843mm` (verificar) | AMOLED | 454×454 | ✅ | ✅ | ✅ | `:amoled` `:hasTouch` `:hasSpeaker` |
| Fenix 8 (43mm AMOLED) | `fenix847mm` (verificar) | AMOLED | 390×390 | ✅ | ✅ | ✅ | `:amoled` `:hasTouch` `:hasSpeaker` |
| Epix Gen 2 | `epix2` | AMOLED | 416×416 | ✅ | ✅ | ❌ | `:amoled` `:hasTouch` |
| Venu 3 | `venu3` | AMOLED | 454×454 | ✅ | ✅ | ✅ | `:amoled` `:hasTouch` `:hasSpeaker` |
| Venu 3S | `venu3s` | AMOLED | 390×390 | ✅ | ✅ | ✅ | `:amoled` `:hasTouch` `:small` `:hasSpeaker` |
| Vivoactive 5 | `vivoactive5` | AMOLED | 390×390 | ✅ | ✅ | ❌ | `:amoled` `:hasTouch` |

**Validação:** Os jungle IDs exatos devem ser confirmados na primeira task de setup, lendo `~/Library/Application Support/Garmin/ConnectIQ/Sdks/<sdk>/devices/`. Os IDs de Fenix 8 acima são suposição; corrigir no setup.

---

## 2. APIs Connect IQ usadas no Toma

### 2.1 `Toybox.Timer.Timer`

Loop do countdown. **O coração do timer.**

```monkeyc
using Toybox.Timer;

class TimerService {
    private var _timer as Timer.Timer;

    function initialize() {
        _timer = new Timer.Timer();
    }

    function startTicking(callback as Method, intervalMs as Number) as Void {
        _timer.start(callback, intervalMs, true); // true = periodic
    }

    function stop() as Void {
        _timer.stop();
    }
}
```

**Detalhes:**
- `intervalMs = 1000` para 1 tick por segundo. Suficiente — não precisa de 100ms.
- Callback **não pode** alocar muita memória (executa em thread de timer).
- `start(callback, period, true)` é periódico; `false` é one-shot.
- Apenas **um Timer ativo** por contexto recomendado. Em apps mais complexos pode haver múltiplos, mas o Toma usa só um (loop do tick). Para Phase Transition (3s), criar Timer one-shot separado.

**Atenção:** `Timer.Timer` é killed quando o app vai para background. O callback **não é chamado** durante background. Estratégia documentada no item 6 (Sleep / background).

### 2.2 `Toybox.Attention`

Vibração e som.

```monkeyc
using Toybox.Attention;

class AttentionService {
    function vibrateStart() as Void {
        if (Attention has :vibrate) {
            var profile = [new Attention.VibeProfile(75, 200)]; // 1 pulso curto
            Attention.vibrate(profile);
        }
    }

    function vibrateEndOfWork() as Void {
        if (Attention has :vibrate) {
            // 2 pulsos médios
            var profile = [
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 400)
            ];
            Attention.vibrate(profile);
        }
    }

    function vibrateCycleComplete() as Void {
        if (Attention has :vibrate) {
            // 3 pulsos longos — final do ciclo é "definitivo"
            var profile = [
                new Attention.VibeProfile(100, 500),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 500),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 500)
            ];
            Attention.vibrate(profile);
        }
    }

    function playToneEnd() as Void {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
    }

    function flashBacklight() as Void {
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
    }
}
```

**Limitações documentadas:**
- Forerunner devices (FR255 incluso): vibração funciona, mas **padrões de duty cycle podem ser ignorados** — o relógio pode interpretar todos os pulsos como força máxima. Validar no device físico.
- `playTone` requer `:hasSpeaker` — só Venu, Fenix 8, FR255 Music, etc.
- `backlight(true)` força backlight on por alguns segundos. Em AMOLED é no-op (sempre on em modo ativo).
- Máximo de **8 VibeProfile** por chamada `vibrate()`.

**Profiles do Toma (definidos em `AttentionService`):**

| Evento | Profile |
|---|---|
| Start de sessão | 1 pulso 75% × 200ms |
| End of work → break | 2 pulsos 100% × 400ms (gap 200ms) |
| End of break → work | 1 pulso 100% × 600ms |
| Cycle complete (4× work-break feito) | 3 pulsos 100% × 500ms (gap 200ms entre) |

### 2.3 `Toybox.Application.Properties`

Settings persistentes. Sobrevivem ao kill da app.

```monkeyc
using Toybox.Application as App;

class SettingsRepository {
    function getSoundEnabled() as Boolean {
        var v = App.Properties.getValue("soundEnabled");
        return v == null ? false : v as Boolean;
    }

    function setSoundEnabled(value as Boolean) as Void {
        App.Properties.setValue("soundEnabled", value);
    }
}
```

**Keys do Toma:**
- `soundEnabled` (Boolean, default false — silêncio respeita o tom da marca)
- `vibrationEnabled` (Boolean, default true)
- `backlightOnAlert` (Boolean, default true)
- `recordAsActivity` (Boolean, default true)
- `language` (String, default "auto" — usa system locale)
- `customWorkMin` (Number, default 25, range 5-90)
- `customBreakMin` (Number, default 5, range 1-30)
- `customCycles` (Number, default 4, range 1-10)
- `lastSelectedPreset` (Number, default 0 — índice no array de presets)

**Limites:**
- ~1-2 MB total de Properties (varia por device).
- Sem objetos complexos — apenas Number, Float, Long, Double, String, Boolean, Char.

### 2.4 `Toybox.Application.Storage`

Para histórico (estrutura mais flexível que Properties — aceita Dictionary e Array).

```monkeyc
using Toybox.Application as App;

class HistoryRepository {
    function loadAll() as Array<Dictionary> {
        var v = App.Storage.getValue("sessionHistory");
        return v == null ? [] : v as Array;
    }

    function append(session as Session) as Void {
        var all = loadAll();
        all.add(session.toDict());
        // Mantém apenas as últimas 50
        while (all.size() > 50) {
            all = all.slice(1, null);
        }
        App.Storage.setValue("sessionHistory", all);
    }
}
```

**Diferença Properties vs Storage:**
- `Properties` = configurações editáveis pelo usuário (também via Garmin Connect mobile).
- `Storage` = dados internos da app (histórico, estado de recovery). Não aparecem na UI de settings.

### 2.5 `Toybox.WatchUi.Menu2` + `Menu2InputDelegate`

Settings menu estruturado.

```monkeyc
using Toybox.WatchUi as Ui;

class SettingsMenu extends Ui.Menu2 {
    function initialize() {
        Ui.Menu2.initialize({:title => Ui.loadResource(Rez.Strings.settings_title)});
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_sound),
            null,
            "soundEnabled",
            settingsRepo.getSoundEnabled(),
            null
        ));
        addItem(new Ui.ToggleMenuItem(
            Ui.loadResource(Rez.Strings.settings_vibration),
            null,
            "vibrationEnabled",
            settingsRepo.getVibrationEnabled(),
            null
        ));
        // etc.
    }
}

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
    function onSelect(item as Ui.MenuItem) as Void {
        if (item instanceof Ui.ToggleMenuItem) {
            var key = item.getId() as String;
            var value = item.isEnabled();
            settingsRepo.setBoolean(key, value);
        }
    }
}
```

**ToggleMenuItem** já desenha checkbox automaticamente — não precisa custom.

### 2.6 `Toybox.WatchUi.BehaviorDelegate`

Mapeia inputs em alto nível (não eventos crus).

```monkeyc
using Toybox.WatchUi as Ui;

class TimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        Ui.BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        // Botão Enter (FR) ou tap central (touch)
        model.togglePauseResume();
        Ui.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        // Botão Back (FR) ou swipe right (touch)
        // Sai da tela do timer (com confirmação)
        Ui.pushView(new ConfirmStopView(), new ConfirmStopDelegate(), Ui.SLIDE_LEFT);
        return true;
    }

    function onMenu() as Boolean {
        // Botão Menu (long press up — em devices que têm)
        Ui.pushView(new SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }

    function onSwipe(swipeEvent as Ui.SwipeEvent) as Boolean {
        // Só roda em :hasTouch devices
        return false;
    }
}
```

**`BehaviorDelegate` vs `InputDelegate`:**
- `BehaviorDelegate` é mais alto nível — abstrai botão vs touch (`onSelect`, `onBack`, `onMenu`).
- `InputDelegate` é cru — `onKey(WatchUi.KEY_ENTER)`, `onTap`.
- Toma usa **BehaviorDelegate** sempre que possível.

### 2.7 `Toybox.ActivityRecording`

Para gravar sessão como FIT activity (diferencial competitivo).

```monkeyc
using Toybox.ActivityRecording;

class ActivityService {
    private var _session as ActivityRecording.Session?;

    function start() as Void {
        if (Toybox has :ActivityRecording &&
            ActivityRecording has :createSession) {
            _session = ActivityRecording.createSession({
                :name => "Focus",
                :sport => ActivityRecording.SPORT_GENERIC,
                :subSport => ActivityRecording.SUB_SPORT_GENERIC
            });
            _session.start();
        }
    }

    function stop() as Void {
        if (_session != null) {
            _session.stop();
            _session.save(); // grava no FIT
            _session = null;
        }
    }

    function discard() as Void {
        if (_session != null) {
            _session.stop();
            _session.discard();
            _session = null;
        }
    }
}
```

**Comportamento:**
- Activity aparece no Garmin Connect como "Focus" (sport generic).
- Inclui automaticamente HR, calorias, duração — o que o device mediu durante a sessão.
- **Sport custom** ("Pomodoro") só está disponível em SDK 4.2+. Validar; se não, usar `SPORT_GENERIC` mesmo.
- Se `:recordAsActivity` setting está off, ActivityService não é chamado.

### 2.8 `Toybox.System.getDeviceSettings`

Para detecção de capabilities runtime (locale, screen, etc.).

```monkeyc
using Toybox.System as Sys;

var settings = Sys.getDeviceSettings();
var locale = settings.systemLanguage; // "eng", "por"
var screenWidth = settings.screenWidth;
var screenHeight = settings.screenHeight;
var doNotDisturb = settings.doNotDisturb; // boolean
```

**Uso no Toma:**
- `screenWidth` para escolher bucket.
- `systemLanguage` para escolher PT vs EN se setting `language == "auto"`.
- `doNotDisturb` para suprimir vibração/som se DND ativo (decisão UX).

---

## 3. Capability detection — padrão obrigatório

**Regra:** toda chamada a feature opcional usa `has` antes.

```monkeyc
// CORRETO
if (Attention has :vibrate) {
    Attention.vibrate(profile);
}

// CORRETO
if (Toybox has :ActivityRecording &&
    ActivityRecording has :createSession) {
    // ...
}

// ERRADO — vai crashar em devices sem speaker
Attention.playTone(Attention.TONE_LOUD_BEEP);
```

Centralize cada feature em um Service que faz a checagem **uma vez**. Views/Delegates não checam; só chamam o Service.

---

## 4. Build & deploy

### 4.1 Setup do SDK

1. Baixar SDK Manager: <https://developer.garmin.com/connect-iq/sdk/>
2. Instalar e abrir.
3. Aceitar EULA.
4. Baixar SDK mais recente que suporte System 7 (4.2.x ou superior).
5. Baixar device packages: FR255, FR255S, FR265, FR265S, FR955, FR965, Fenix 7, Fenix 8 (todos os SKUs), Epix2, Venu 3, Venu 3S, Vivoactive 5.

### 4.2 Developer key

```bash
# Via VS Code: Cmd+Shift+P → "Monkey C: Generate a Developer Key"
# Salvar em ~/.connect-iq/developer_key.der

# Via OpenSSL (manual):
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
    -in developer_key.pem -out developer_key.der -nocrypt
chmod 600 ~/.connect-iq/developer_key.der
```

**CRÍTICO:** backup imediato da chave. Sem ela, não conseguimos publicar updates do app na Store.

### 4.3 Build via VS Code (recomendado)

`.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run on Forerunner 255",
      "type": "monkeyc",
      "request": "launch",
      "deviceId": "fr255",
      "program": "${workspaceFolder}/source/TomaApp.mc"
    }
  ]
}
```

`F5` para rodar. Simulador abre, app instala, debug attached.

### 4.4 Build via CLI

```bash
SDKPATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-7.2.0-2024-08-26-abc123" # ajustar
KEYPATH="$HOME/.connect-iq/developer_key.der"

# Debug build para FR255
"$SDKPATH/bin/monkeyc" \
    -d fr255 \
    -f monkey.jungle \
    -o build/toma_fr255.prg \
    -y "$KEYPATH" \
    -w

# Release build (multi-device, .iq para Store)
"$SDKPATH/bin/monkeyc" \
    -e \
    -f monkey.jungle \
    -o build/toma.iq \
    -y "$KEYPATH" \
    -r
```

Flag importante:
- `-w`: warnings.
- `-r`: release/optimized.
- `-e`: build .iq (multi-device package para Store).
- `-d <device>`: build single-device .prg (debug/sideload).

### 4.5 Side-load no relógio físico

1. Conectar relógio via USB.
2. Mac: monta em `/Volumes/GARMIN`.
3. Copiar `.prg`:
   ```bash
   cp build/toma_fr255.prg /Volumes/GARMIN/GARMIN/APPS/
   ```
4. Ejetar:
   ```bash
   diskutil eject /Volumes/GARMIN
   ```
5. Relógio pode pedir reboot. Após, app aparece no menu de apps.

**Nota 2024-2025:** alguns firmware recentes restringem side-load. Se o app não aparece, validar que está em `/GARMIN/APPS/` e não `/Garmin/` (case-sensitive em alguns macOS configs).

### 4.6 Simulador

```bash
# Após compilar, rodar:
"$SDKPATH/bin/connectiq" &  # abre simulator standalone
"$SDKPATH/bin/monkeydo" build/toma_fr255.prg fr255
```

Ou usar VS Code (F5) que faz tudo.

**Limitações simulador:**
- Vibração: não vibra, só loga.
- Som: não toca.
- HR: simulado, valor estático.
- ActivityRecording: salva FIT em `~/Library/Application Support/Garmin/ConnectIQ/Activities/`.

---

## 5. Memory budget

### 5.1 Limites por device

Garmin não publica oficialmente, mas via comunidade:

| Tier | Heap aprox | Devices |
|---|---|---|
| Tight | ~256 KB - 512 KB | FR255S (display pequeno + memória apertada) |
| Standard | ~1 MB | FR255, FR255 Music, Fenix 7 |
| Roomy | ~2 MB+ | FR265, FR965, Venu 3, Fenix 8, Epix Gen 2 |

### 5.2 Alvo do Toma

**< 512 KB de heap** em runtime (medido pelo simulator: View → Memory). Garante que rode em todos.

### 5.3 Boas práticas

- Não criar `Array` ou `Dictionary` dentro de `onUpdate`.
- Pré-criar buffers em `onLayout`.
- Strings via `Rez.Strings` ficam em ROM, não heap.
- Cuidado com **closures** — capturam o escopo, custam.
- Profiling: `View → Profiler` no simulator.

---

## 6. Sleep, background, recovery

### 6.1 Como Connect IQ trata apps em background

- App full (não widget) **continua rodando** se usuário pressiona Back e vai para watch face? **Não** — Connect IQ kill o app na maioria dos devices.
- Algumas exceções via permissão `Background` permitem temporary background tasks, mas **complica e não é confiável** para timer Pomodoro.

### 6.2 Estratégia Toma — "tudo no foreground"

Decisão V1: app é foreground-only. Se usuário sair, sessão é congelada/perdida.

**Mitigação via recovery:**
- Persistir estado do timer a cada tick (com throttle de 5s) em `Storage`.
- No `onStart` da app, checar se há sessão "incomplete" no Storage.
- Se sim, mostrar diálogo "Resume session?" com tempo restante calculado pela diferença.

```monkeyc
class RecoveryService {
    function checkOnStart() as RecoveryState? {
        var saved = App.Storage.getValue("activeSession");
        if (saved == null) { return null; }
        var savedAt = saved["savedAt"] as Number;
        var elapsed = Time.now().value() - savedAt;
        var remainingAtSave = saved["remaining"] as Number;
        var newRemaining = remainingAtSave - elapsed;
        if (newRemaining <= 0) { return null; }
        return new RecoveryState(saved, newRemaining);
    }
}
```

### 6.3 Sleep prevention

- `Attention.backlight(true)` força backlight, mas só por segundos.
- Não há API para "manter screen on por 25min".
- Para Pomodoro funcionar, usuário precisa estar com app em foreground.
- Default UX: usuário inicia, deixa relógio acordado (gesture/movement).
- Em devices AMOLED, manter timer renderizando significa redraws — Connect IQ pode reduzir refresh rate em low-power.

**Decisão:** confiar no comportamento padrão do device. Não tentar "hack" sleep prevention.

---

## 7. FIT field naming (para activities)

Quando gravar sessão como activity (B11), além dos campos automáticos (HR, time, calories), opcionalmente gravar campos custom via `FitContributor`:

```monkeyc
using Toybox.FitContributor;

class ActivityService {
    private var _completedSessionsField as FitContributor.Field?;

    function start() as Void {
        // ... criar session
        _completedSessionsField = _session.createField(
            "completed_pomodoros",
            0, // field_id
            FitContributor.DATA_TYPE_UINT8,
            { :mesgType => FitContributor.MESG_TYPE_SESSION,
              :units => "count" }
        );
    }

    function setCompletedSessions(count as Number) as Void {
        if (_completedSessionsField != null) {
            _completedSessionsField.setData(count);
        }
    }
}
```

**Decisão V1:** apenas a activity básica, **sem** campos custom (mais simples, menos coisa pra dar errado). Custom fields ficam para V1.1 se houver demanda.

---

## 8. Permissions no manifest.xml

```xml
<iq:permissions>
    <iq:uses-permission id="Attention"/>      <!-- vibração, beep, backlight -->
    <iq:uses-permission id="FitContributor"/> <!-- só se usar custom fields no FIT -->
</iq:permissions>
```

**Não pedimos:**
- `Background` (não usamos background tasks).
- `Communications` (sem network).
- `Positioning` (sem GPS).
- `Sensor` (HR vem automático na activity).
- `PersistedContent` (não criamos waypoints).

---

## 9. Versão do SDK e runtime

- **SDK alvo:** 7.x ou superior (latest no momento do setup).
- **`minSdkVersion="4.1.0"`** (System 7).
- **`apiVersion="3.2"`** no manifest.
- Connect IQ 5+ (System 7) suporta tudo o que precisamos.

---

## 10. Links oficiais (consulta autorizada)

Quando a IA precisar buscar info nova durante FASE 2, prefira estas fontes:

- <https://developer.garmin.com/connect-iq/> (home)
- <https://developer.garmin.com/connect-iq/api-docs/> (toda API Toybox)
- <https://developer.garmin.com/connect-iq/core-topics/> (guides oficiais)
- <https://developer.garmin.com/connect-iq/compatible-devices/> (lista de devices)
- <https://developer.garmin.com/connect-iq/reference-guides/jungle-reference/> (sintaxe da jungle)
- <https://forums.garmin.com/developer/connect-iq/> (forum oficial)

**Não consultar:**
- Tutoriais antigos (>2022) sem revalidar — APIs mudam.
- Stack Overflow para Connect IQ — base muito pequena, respostas frequentemente desatualizadas.

---

## 11. Erros conhecidos / pegadinhas

- **`Application.Properties.getValue` retorna `null` na primeira execução.** Sempre defaultar.
- **`Timer.Timer.start` com intervalo < 100ms é instável.** Para 1Hz (1000ms) é seguro.
- **Layouts XML não suportam expressões.** Tudo precisa ser literal ou referência a `Rez.Dimensions`.
- **Cores em XML são `0xRRGGBB`** (sem `#`). Em Monkey C, `Graphics.COLOR_*` ou número hex direto.
- **`requestUpdate()` é debounced.** Múltiplas chamadas no mesmo frame coalescem em uma.
- **`onUpdate` é chamado em ordem `Layer` → `child`.** Children desenham por cima.
- **`pushView` muda a current view, mas onHide do current só é chamado depois.** Não confiar em ordem síncrona.
