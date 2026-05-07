# Task 02-10: FIT Activity Recording

## Objetivo

Implementar **B11** — gravar cada sessão completa como **FIT Activity** ("Focus") visível no Garmin Connect. Este é o **diferencial competitivo principal** do Toma vs outros apps Pomodoro existentes (nenhum faz isso).

## Tipo

- [x] Comportamento (lógica)

## Cobre

- **B11** Gravar como FIT Activity — `spec/spec.md` §4.B11

## Dependências

- `tasks/02-comportamentos/02-timer-loop.md`.
- `tasks/02-comportamentos/04-pausa-resume-stop.md`.
- `tasks/02-comportamentos/08-persistencia-settings.md` (toggle "Record as activity").

## Critério de aceitação

### Automated

- [ ] Compila sem warnings, `--typecheck=Strict` passa.
- [ ] Permission `FitContributor` no `manifest.xml` (se usarmos custom fields).
- [ ] Teste de wiring: `ActivityService.start/stop/discard` é chamado nos eventos certos do Model.

### Manual

- [ ] Settings → "Record as activity" ON (default).
- [ ] Iniciar e completar sessão (preset rápido 1/1/2 para teste).
- [ ] No simulador: arquivo FIT aparece em `~/Library/Application Support/Garmin/ConnectIQ/Activities/`.
- [ ] **No relógio físico FR255**: completar sessão → ao sincronizar com Garmin Connect (mobile ou web), aparece nova activity "Focus" no histórico.
- [ ] Activity tem: data, duração, HR (se device gravar), calorias (estimadas).
- [ ] Sessão stopada (não completada): NÃO vira activity (discarded).
- [ ] Settings → "Record as activity" OFF: sessão completa não gera activity.

## Arquivos esperados

### Novos

- `source/services/ActivityService.mc`.
- `tests/ActivityServiceTest.mc` (smoke test — Toybox.ActivityRecording é difícil de mockar; foco em testar branch logic).

### Modificados

- `manifest.xml` — adicionar `<iq:uses-permission id="FitContributor"/>` se usarmos custom fields. **Decidir nesta task.** V1: provavelmente não.
- `source/TomaApp.mc` — instanciar ActivityService; handler de eventos do Model.
- `source/repositories/SettingsRepository.mc` — usado para checar `recordAsActivity`.

## Referências obrigatórias

- `references/garmin_platform.md` §2.7 (ActivityRecording API), §8 (permissions).
- `spec/spec.md` §4.B11.

## Especificação técnica

### ActivityService API

```monkeyc
using Toybox.ActivityRecording;

class ActivityService {
    private var _session as ActivityRecording.Session?;
    private var _settingsRepo as SettingsRepository;

    function initialize(settingsRepo as SettingsRepository) {
        _settingsRepo = settingsRepo;
    }

    function start() as Void {
        if (!_isEnabled()) { return; }
        if (_session != null) { return; } // Já tem session ativa

        if (Toybox has :ActivityRecording &&
            (Toybox.ActivityRecording has :createSession)) {
            try {
                _session = ActivityRecording.createSession({
                    :name => "Focus",
                    :sport => ActivityRecording.SPORT_GENERIC,
                    :subSport => ActivityRecording.SUB_SPORT_GENERIC
                });
                _session.start();
            } catch (e) {
                // log e seguir; não quebrar a sessão Pomodoro
                System.println("ActivityService.start failed: " + e.getErrorMessage());
                _session = null;
            }
        }
    }

    function pause() as Void {
        // Não há "pause" na Session — para pausar registro, chamar stop sem save
        // não é o que queremos. Mantém running, e na save inclui pauses como tempo total.
        // Decisão: deixar running mesmo durante pause Pomodoro.
    }

    function resume() as Void {
        // No-op por consistência com pause()
    }

    function stop() as Void {
        if (_session == null) { return; }
        try {
            _session.stop();
            _session.save();
        } catch (e) {
            System.println("ActivityService.stop failed: " + e.getErrorMessage());
        }
        _session = null;
    }

    function discard() as Void {
        if (_session == null) { return; }
        try {
            _session.stop();
            _session.discard();
        } catch (e) {
            System.println("ActivityService.discard failed: " + e.getErrorMessage());
        }
        _session = null;
    }

    private function _isEnabled() as Boolean {
        return _settingsRepo.getRecordAsActivity();
    }
}
```

### Wiring em TomaApp

```monkeyc
function _onModelEvent(eventType as Symbol) {
    if (eventType == :onStart) {
        _activityService.start();
    } else if (eventType == :onComplete) {
        _activityService.stop();
    } else if (eventType == :onStop) {
        _activityService.discard();
    }
    // pause/resume: não notificar ActivityService (decisão acima)
}
```

### Decisão: Pause durante sessão Pomodoro

Ao pausar a sessão Pomodoro:
- Opção A: ActivityRecording continua gravando (HR, tempo). Tempo "pausado" entra na duração da activity.
- Opção B: Pause/resume na ActivityRecording também (se API suportar).
- Opção C: Save + restart de session (perde dados).

**Recomendação V1:** Opção A. Simples, e tempo de pausa contar é razoável (usuário ainda está em "modo focus context"). Documentar no README do app.

### Sport custom

`ActivityRecording.SPORT_GENERIC` aparece no Garmin Connect como "Other". Algumas SDKs versions têm `SPORT_FOCUS` ou `SUB_SPORT_FOCUS`? **Validar no SDK do setup.** Se existir, usar; senão, GENERIC com `:name => "Focus"` ainda funciona.

### Permission

`<iq:uses-permission id="FitContributor"/>` só é necessária se gravarmos custom fields no FIT. V1: **não gravamos**, então permission não é necessária. Basta `Attention` (já adicionada).

### Limitações

- Algumas Activity Sessions podem conflitar se o usuário já está rodando outra activity (ex: corrida). Connect IQ pode rejeitar `createSession`. Capturar exception e logar — não interromper Pomodoro.
- Em alguns devices low-end, ActivityRecording pode não estar disponível. `Toybox has :ActivityRecording` capture detection.

## Out of scope desta task

- Custom FIT fields (V1.x).
- Sport `SPORT_FOCUS` se não disponível no SDK atual.
- Configurar GPS (não queremos).
