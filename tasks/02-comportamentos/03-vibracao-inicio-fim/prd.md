# PRD — Task 02-03: Vibration & Sound (AttentionService)

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Implementar `AttentionService` — wrapper sobre `Toybox.Attention` que fornece alertas (vibracao, som e backlight) em resposta a eventos do `PomodoroModel`. A service sera registrada como observer no `TomaApp.onModelEvent` e usara `SettingsState` para respeitar toggles do usuario e DND do device.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que fornece |
|---|---|
| `source/model/PomodoroModel.mc` | Observer pattern com `addObserver(callback)` + `_emit(event)`. Ja emite `ON_START`, `ON_PHASE_CHANGE`, `ON_WORK_PHASE_COMPLETE`, `ON_COMPLETE`. |
| `source/model/PomodoroEvent.mc` | Enum com todos os eventos necessarios (ON_START, ON_PHASE_CHANGE, ON_COMPLETE). |
| `source/model/PomodoroState.mc` | Enum de estados: `RUNNING_WORK`, `RUNNING_SHORT_BREAK`, `RUNNING_LONG_BREAK`, etc. |
| `source/model/SettingsState.mc` | Modulo com vars mutaveis: `soundEnabled`, `vibrationEnabled`, `backlightOnAlert`. Ja usado por SettingsMenu/Delegate. |
| `source/TomaApp.mc` | Ja possui `onModelEvent(event)` que reage a `ON_COMPLETE`. Ponto de extensao natural para wiring do AttentionService. |
| `source/services/TimerService.mc` | Referencia de como services sao estruturados no projeto. |

### 2.2 Assets disponiveis

Nenhum asset grafico necessario para esta task. Nao ha fontes, icones ou imagens envolvidas — apenas APIs de hardware.

### 2.3 Approach de implementacao

**Decisao:** Criar `AttentionService` como classe stateless no `source/services/`. Wiring via `TomaApp.onModelEvent` — ao receber eventos, o app chama metodos publicos do service. O service consulta `SettingsState` (modulo global) e `System.getDeviceSettings().doNotDisturb` antes de executar.

**Justificativa:**
- `SettingsState` ja funciona como store global in-memory (sem SettingsRepository persistente ainda — task 02-08).
- Criar um SettingsRepository agora seria scope creep. A task explicitamente diz "usar valores hardcoded por ora" se 02-08 nao rodou.
- O observer pattern no Model ja emite todos os eventos necessarios — nao precisamos criar novos.

**Alternativa rejeitada:** Registrar AttentionService diretamente como observer do Model. Isso violaria o principio de "services sao stateless e nao ouvem eventos" (architecture.md §3). O App e o hub de wiring.

### 2.4 APIs Connect IQ utilizadas

| API | Metodo | Assinatura | Uso |
|---|---|---|---|
| `Toybox.Attention` | `vibrate` | `vibrate(profile as Array<VibeProfile>) as Void` | Padrao de vibracao por evento |
| `Toybox.Attention` | `playTone` | `playTone(toneType as Number) as Void` | `TONE_LOUD_BEEP` no fim de fase |
| `Toybox.Attention` | `backlight` | `backlight(on as Boolean) as Void` | Flash backlight em transicoes |
| `Toybox.Attention` | `VibeProfile` | `new VibeProfile(dutyCycle as Number, duration as Number)` | dutyCycle: 0-100, duration: ms |
| `Toybox.System` | `getDeviceSettings()` | retorna `DeviceSettings` com `.doNotDisturb as Boolean` | Check DND |

**Capability checks obrigatorios:**
- `Attention has :vibrate` antes de vibrar
- `Attention has :playTone` antes de tocar som
- `Attention has :backlight` antes de acionar backlight

**Limites:**
- Max 8 `VibeProfile` por chamada `vibrate()` (nosso maximo e 5 — ok).
- `playTone` so funciona em devices com speaker (FR255 Music, Fenix 8, Venu 3).
- `backlight(true)` e no-op em AMOLED (sempre on em modo ativo).
- Padroes de duty cycle podem ser ignorados em FR — device interpreta como forca maxima.

### 2.5 Cores/dimensoes/strings necessarias

Nenhuma — esta task e puramente logica (sem UI). Strings de log usam literais (permitido por architecture.md §4 para debug logs).

---

## 3. Decisoes a tomar

### D1. Perfil diferente para "entering long break" vs "entering short break"?

**Opcoes:**
1. Mesmo perfil (2 pulsos medios) para short e long break — simplifica.
2. Perfil mais marcante para long break (ex: 2 pulsos + mais longos).

**Recomendacao:** Opcao 1. A task explicitamente recomenda "mesmo padrao de end-of-work tanto para short quanto long break" para V1. A diferenciacao sera visual (label "LONG BREAK") e via cycle-complete (apos long break).

### D2. Como lidar com DND ativo + setting de vibracao habilitado?

**Opcoes:**
1. Respeitar DND — suprimir tudo (vibracao + som).
2. Permitir override via setting (usuario liga alerta mesmo com DND).

**Recomendacao:** Opcao 1. A task declara "respeitar DND e cortesia basica". Se usuario quer alerta com DND, deve desativar DND no device.

### D3. backlight suprimido por DND?

**Opcoes:**
1. Sim — DND suprime vibracao, som E backlight.
2. Nao — backlight e visual, nao incomoda terceiros.

**Recomendacao:** Opcao 2. Backlight nao faz barulho, nao incomoda terceiros. A task menciona DND para "vibracao e som", nao para backlight. Backlight depende apenas do toggle `backlightOnAlert`.

### D4. Onde instanciar o AttentionService?

**Opcoes:**
1. No `initialize()` do `TomaApp` — vive enquanto o app vive.
2. Sob demanda (lazy) — criado no primeiro evento relevante.

**Recomendacao:** Opcao 1. O service e leve (stateless, sem timers), e o padrao do projeto (TimerService ja e criado no initialize). Simplicidade.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | Simulador nao vibra/toca — impossivel testar automaticamente | Usar `System.println` em debug para log. Teste manual no FR255 fisico. Acceptance criteria ja documenta isso. |
| 2 | `doNotDisturb` pode nao existir em todos devices/firmwares | Usar `has` check: `if (settings has :doNotDisturb && settings.doNotDisturb)`. |
| 3 | SettingsState e in-memory (nao persiste entre kills) | Aceitavel para V1. Task 02-08 migrara para Properties persistentes. Os defaults (vibration=true, sound=false, backlight=true) sao razoaveis. |
| 4 | Permissao `Attention` nao esta no manifest | Adicionar `<iq:uses-permission id="Attention"/>` ao manifest.xml. |
| 5 | `onModelEvent` no TomaApp precisa detectar qual fase entramos (short vs long break vs work) para decidir alerta | Inspecionar `_model.getState()` APOS a emissao do evento — o Model ja transicionou o state antes de emitir `ON_PHASE_CHANGE`. |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `source/services/AttentionService.mc` (NOVO) | Wrapper sobre Toybox.Attention. Metodos: `alertStart`, `alertEndOfWork`, `alertEndOfBreak`, `alertCycleComplete`. Consulta SettingsState e DND. |
| `source/TomaApp.mc` (MODIFICAR) | Instanciar `AttentionService` no `initialize()`. Expandir `onModelEvent` para chamar metodos apropriados do service. |
| `manifest.xml` (MODIFICAR) | Adicionar `<iq:uses-permission id="Attention"/>`. |
| `tests/AttentionServiceTest.mc` (NOVO) | Testes unitarios com mock do SettingsState verificando que os metodos corretos sao chamados nos eventos certos. |

---

## 6. Arquitetura do fluxo

```
PomodoroModel
    |
    | _emit(ON_START / ON_PHASE_CHANGE / ON_COMPLETE)
    v
TomaApp.onModelEvent(event)
    |
    |-- event == ON_START --> attentionService.alertStart()
    |
    |-- event == ON_PHASE_CHANGE
    |       |-- model.getState() == RUNNING_SHORT_BREAK --> attentionService.alertEndOfWork()
    |       |-- model.getState() == RUNNING_LONG_BREAK  --> attentionService.alertEndOfWork()
    |       |-- model.getState() == RUNNING_WORK        --> attentionService.alertEndOfBreak()
    |       |-- model.getState() == COMPLETED           --> (handled by ON_COMPLETE)
    |
    |-- event == ON_COMPLETE --> attentionService.alertCycleComplete()
    v
AttentionService
    |
    |-- check SettingsState.vibrationEnabled
    |-- check SettingsState.soundEnabled
    |-- check SettingsState.backlightOnAlert
    |-- check System.getDeviceSettings().doNotDisturb
    |-- check `Attention has :vibrate` / `:playTone` / `:backlight`
    |
    v
Toybox.Attention.vibrate(profile) / playTone(tone) / backlight(true)
```

---

## 7. Referencias para o plan.md

| Documento | Secao |
|---|---|
| `references/garmin_platform.md` | §2.2 (Attention API), §3 (capability detection), §8 (permissions) |
| `references/architecture.md` | §3 (Services = wrappers finos, stateless), §4 (naming, tipos) |
| `spec/spec.md` | §4.B7 (vibracao), §4.B8 (som) |
| `source/TomaApp.mc` | Ponto de wiring (onModelEvent existente) |
| `source/model/PomodoroEvent.mc` | Enum de eventos |
| `source/model/PomodoroState.mc` | Enum de estados |
| `source/model/SettingsState.mc` | Toggles in-memory |

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (N/A — task sem UI).
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
