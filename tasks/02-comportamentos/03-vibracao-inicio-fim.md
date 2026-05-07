# Task 02-03: Vibração e Som (alertas)

## Objetivo

Implementar **AttentionService** — wrapper sobre `Toybox.Attention` para vibração, som (devices com speaker) e backlight. Conectar nos eventos do PomodoroModel: start, end-of-work, end-of-break, cycle-complete.

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B7** Vibração de alerta — `spec/spec.md` §4.B7
- **B8** Som de alerta — `spec/spec.md` §4.B8

## Dependências

- `tasks/02-comportamentos/01-state-machine-pomodoro.md` (eventos do Model existem).
- `tasks/02-comportamentos/02-timer-loop.md` (TimerService roda).

## Critério de aceitação

### Automated

- [ ] Compila sem warnings.
- [ ] `--typecheck=Strict` passa.
- [ ] Testes (mock AttentionService) verificam que callback é chamado nos eventos certos.

### Manual

- [ ] No simulador, vibração não acontece (limitação documentada), mas log mostra "vibrate(profile)" nos pontos esperados.
- [ ] **No relógio físico FR255**: ao iniciar sessão, sente 1 pulso curto.
- [ ] **No relógio físico**: ao terminar work-phase (vai pra break), sente 2 pulsos médios.
- [ ] **No relógio físico**: ao terminar break-phase (volta pra work), sente 1 pulso longo.
- [ ] **No relógio físico**: ao completar ciclo (após long break), sente 3 pulsos longos.
- [ ] Toggle "Vibration" em Settings desabilita todos os alertas vibratórios.
- [ ] Toggle "Sound" em Settings habilita beep (em devices com speaker).
- [ ] Toggle "Backlight on alert" liga backlight nos eventos de transição.

## Arquivos esperados

### Novos

- `source/services/AttentionService.mc`.

### Modificados

- `source/TomaApp.mc` — instanciar AttentionService, registrar como observer do Model.
- `source/services/AttentionService.mc` (novo) — handler de eventos Model que aciona vibrações apropriadas.
- `source/repositories/SettingsRepository.mc` (criado em `02-08` ou aqui — ver dependência) — usar repository para ler toggles. **Se `02-08` ainda não rodou**, usar valores hardcoded por ora e migrar depois.

## Referências obrigatórias

- `references/garmin_platform.md` §2.2 (Attention API), §3 (capability detection).
- `spec/spec.md` §4.B7, §4.B8.

## Especificação técnica

### AttentionService API

```monkeyc
using Toybox.Attention;

class AttentionService {
    private var _settingsRepo as SettingsRepository?;

    function initialize(settingsRepo as SettingsRepository?) {
        _settingsRepo = settingsRepo;
    }

    // Public — chamados pelo handler que escuta o Model.
    function alertStart() as Void {
        _vibrate([new Attention.VibeProfile(75, 200)]);
    }

    function alertEndOfWork() as Void {
        _vibrate([
            new Attention.VibeProfile(100, 400),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 400)
        ]);
        _playTone();
        _flashBacklight();
    }

    function alertEndOfBreak() as Void {
        _vibrate([new Attention.VibeProfile(100, 600)]);
        _playTone();
        _flashBacklight();
    }

    function alertCycleComplete() as Void {
        _vibrate([
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(100, 500)
        ]);
        _playTone();
        _flashBacklight();
    }

    // Private helpers
    private function _vibrate(profile as Array) as Void {
        if (!_isVibrationEnabled()) { return; }
        if (!(Attention has :vibrate)) { return; }
        if (_isDoNotDisturb()) { return; }
        Attention.vibrate(profile);
    }

    private function _playTone() as Void {
        if (!_isSoundEnabled()) { return; }
        if (!(Attention has :playTone)) { return; }
        if (_isDoNotDisturb()) { return; }
        Attention.playTone(Attention.TONE_LOUD_BEEP);
    }

    private function _flashBacklight() as Void {
        if (!_isBacklightOnAlertEnabled()) { return; }
        if (!(Attention has :backlight)) { return; }
        Attention.backlight(true);
    }

    private function _isVibrationEnabled() as Boolean {
        return _settingsRepo == null ? true : _settingsRepo.getVibrationEnabled();
    }
    // ... outros toggles
}
```

### Wiring no TomaApp

```monkeyc
class TomaApp extends App.AppBase {
    function onStart() {
        // ... outros inits
        _attention = new AttentionService(_settingsRepo);
        _model.addObserver(method(:_onModelEvent));
    }

    function _onModelEvent(eventType as Symbol) as Void {
        if (eventType == :onStart) {
            _attention.alertStart();
        } else if (eventType == :onPhaseChange) {
            var newState = _model.getState();
            if (newState == :running_short_break || newState == :running_long_break) {
                _attention.alertEndOfWork();
            } else if (newState == :running_work) {
                _attention.alertEndOfBreak();
            }
        } else if (eventType == :onComplete) {
            _attention.alertCycleComplete();
        }
    }
}
```

**Atenção:** `onPhaseChange` para long break também conta como "endOfWork" (estamos saindo de work). Mas vibração para long-break poderia ser diferente — decidir se queremos um perfil específico para "entering long break" (mais marcante).

**Recomendação V1:** mesmo padrão de end-of-work tanto para short quanto long break. Diferenciar visualmente (label "LONG BREAK") e via cycle-complete (após long break).

### DND (Do Not Disturb)

`System.getDeviceSettings().doNotDisturb` retorna boolean. Se true, suprimir vibração e som.

**Decisão UX:** mesmo com DND, deixar o usuário override via setting? Não — respeitar DND é cortesia básica. Se usuário quer alerta mesmo com DND, desliga DND.

## Out of scope desta task

- Vibração customizável por evento via Settings (V2).
- Padrões diferentes por preset (V2).
- Som customizável (V2).
