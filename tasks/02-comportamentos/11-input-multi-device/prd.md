# PRD — Task 02-11: Input Multi-Device + Sleep Prevention

> Gerado na FASE 2.1 (Pesquisa). Base para o plan.md na proxima sessao.

---

## 1. Resumo

Validar e completar o suporte multi-device do Toma: expandir `manifest.xml` para todos os 15 devices alvo, configurar `monkey.jungle` com `excludeAnnotations` corretas por device class (`:mip`/`:amoled`/`:hasTouch`/`:noTouch`/`:hasSpeaker`), revisar todos os Delegates para garantir cobertura completa de `BehaviorDelegate` methods, confirmar que `AttentionService._flashBacklight()` dispara em transicoes de fase, e criar script `scripts/build-all.sh` para validacao de compilacao cross-device.

---

## 2. O que descobri

### 2.1 Codigo existente para reutilizar

| Arquivo | O que ja faz | Status |
|---|---|---|
| `source/delegates/HomeDelegate.mc` | `onSelect`, `onPreviousPage`, `onNextPage`, `onMenu` | Completo |
| `source/delegates/TimerDelegate.mc` | `onSelect` (pause/resume), `onBack` (confirm stop) | Falta `onMenu` |
| `source/delegates/PhaseTransitionDelegate.mc` | `onSelect`, `onBack`, `onKey` (dismiss) | Completo |
| `source/delegates/CycleCompleteDelegate.mc` | `onSelect`, `onBack`, `onPreviousPage`, `onNextPage` | Completo |
| `source/delegates/CustomBuilderDelegate.mc` | `onSelect`, `onBack`, `onPreviousPage`, `onNextPage` | Completo |
| `source/delegates/HistoryDelegate.mc` | `onNextPage`, `onPreviousPage`, `onBack` | Completo |
| `source/delegates/ConfirmStopDelegate.mc` | `onSelect`, `onBack`, `onPreviousPage`, `onNextPage` | Completo |
| `source/delegates/RecoveryDelegate.mc` | `onSelect`, `onBack`, `onPreviousPage`, `onNextPage` | Completo |
| `source/delegates/AboutDelegate.mc` | `onBack` | Completo |
| `source/delegates/SettingsMenuDelegate.mc` | `onSelect` (Menu2InputDelegate) | N/A (Menu2 cuida de nav) |
| `source/delegates/LanguageMenuDelegate.mc` | `onSelect` | N/A |
| `source/services/AttentionService.mc` | `_flashBacklight()` ja chamado em todas as 4 alert methods | Completo |
| `source/TomaApp.mc:onModelEvent` | Chama `_attentionService.alertXxx()` em ON_START, ON_PHASE_CHANGE, ON_COMPLETE | Completo |

### 2.2 Assets disponiveis

Nenhum asset adicional necessario. Esta task e puramente de config/build/validacao.

### 2.3 Approach de implementacao

1. **Manifest expansion**: Adicionar todos os 15 devices alvo ao `manifest.xml` `<iq:products>` (atualmente so tem fr255, fr255s, fr265).
2. **Jungle config**: Configurar `monkey.jungle` com `excludeAnnotations` por device class conforme `garmin_platform.md` §1.
3. **Delegate audit**: Unica lacuna encontrada: `TimerDelegate` nao implementa `onMenu` — adicionar para permitir acesso rapido a Settings durante sessao (consistente com Home que ja tem).
4. **Build script**: Criar `scripts/build-all.sh` para compilar em todos devices e validar que nao ha erros.
5. **DND check**: `AttentionService._isDoNotDisturb()` ja suprime vibracoes quando DND ativo — timer continua normalmente.

**Decisao principal:** Nao usar annotations `:hasTouch`/`:noTouch` para separar delegates em V1. O `BehaviorDelegate` ja abstrai botoes vs touch automaticamente. A separacao por annotation so seria necessaria se tivessemos gestos touch extras (decisao V1: nao adicionar). As annotations servem para excluir codigo que so faz sentido visual/funcional em um tipo de display.

### 2.4 APIs Connect IQ utilizadas

| API | Uso | Ja implementado? |
|---|---|---|
| `Toybox.WatchUi.BehaviorDelegate` | Input abstraction (onSelect, onBack, onMenu, onPreviousPage, onNextPage) | Sim, em todos delegates |
| `Toybox.Attention.backlight(true)` | Flash backlight em transicoes | Sim, via `AttentionService._flashBacklight()` |
| `Toybox.System.getDeviceSettings().doNotDisturb` | DND check para suprimir vibra/som | Sim, via `_isDoNotDisturb()` |

Nenhuma API nova necessaria.

### 2.5 Cores/dimensoes/strings necessarias

Nenhuma alteracao visual. Task e de infraestrutura (build config + validacao).

---

## 3. Decisoes a tomar

### D1. Quais devices incluir no manifest.xml?

**Opcoes:**
- A) Todos os 15 listados em `garmin_platform.md` §1.
- B) Apenas os confirmados com device package instalado localmente.

**Recomendacao:** B — incluir somente os que temos device package (confirmados via SDK). Devices faltantes: `fr255sm` nao encontrado (talvez `fr255sm` nao exista como ID separado — verificar na compilacao). Devices extras com package disponivel: `fenix7pro`, `epix2`.

**Devices confirmados instalados:**
fr255, fr255s, fr255m, fr265, fr265s, fr955, fr965, fenix7, fenix7pro, fenix843mm, fenix847mm, epix2, venu3, venu3s, vivoactive5

**Total: 15 devices** (substitui fr255sm por fenix7pro e epix2 que estao instalados).

### D2. TimerDelegate.onMenu — abrir Settings?

**Opcoes:**
- A) Abrir Settings (consistente com Home).
- B) Nao implementar (Menu nao disponivel durante timer).

**Recomendacao:** A — Implementar. Spec B14 define Menu como acao disponivel em todas as paginas. O comportamento e identico: pushView do SettingsMenu.

### D3. FR955 — MIP com touch: como classificar?

**Opcoes:**
- A) Classe `:mip` `:hasTouch` (excluir `:amoled` e `:noTouch`).
- B) Tratar como MIP no-touch para simplificar.

**Recomendacao:** A — FR955 TEM touch, nao devemos excluir codigo touch. Como usamos `BehaviorDelegate` (que abstrai), na pratica nao ha impacto funcional, mas a annotation correta e `:mip` `:hasTouch` para futura diferenciacao visual (AMOLED render vs MIP render).

### D4. Annotations realmente necessarias no V1?

**Opcoes:**
- A) Declarar todas annotations (`:mip`, `:amoled`, `:hasTouch`, `:noTouch`, `:hasSpeaker`, `:small`) no jungle.
- B) Declarar apenas as relevantes para codigo que ja usa (`test` para excluir testes do build).

**Recomendacao:** A — Declarar todas. Mesmo que V1 nao tenha codigo annotado com `:mip`/`:amoled` ainda, o setup correto evita trabalho futuro e esta task e justamente para preparar isso. Porem, nao criaremos arquivos annotados nesta task (nao ha necessidade funcional). As annotations ficam "prontas" para uso.

---

## 4. Riscos / Unknowns

| # | Risco | Mitigacao |
|---|---|---|
| 1 | Jungle ID `fr255sm` pode nao existir no SDK | Verificar na compilacao; omitir se nao compilar |
| 2 | Fenix 8 IDs incertos (`fenix843mm`/`fenix847mm`) | Packages confirmados instalados com esses nomes |
| 3 | `excludeAnnotations` com annotations nao usadas pode causar warnings | Annotations so afetam compilacao se existir codigo com `:annotation`; sem codigo annotado, nao ha impacto |
| 4 | Compilacao pode falhar por falta de resources para resolucoes novas (454px, 390px) | Garmin escala resources automaticamente; testar no build |
| 5 | `typecheck=Strict` pode expor erros pre-existentes em novo device | Corrigir qualquer erro reportado — esta task inclui esse trabalho |

---

## 5. Lista de arquivos a criar/modificar

| Arquivo | Responsabilidade |
|---|---|
| `manifest.xml` | Expandir `<iq:products>` para 15 devices |
| `monkey.jungle` | Adicionar `excludeAnnotations` por device class |
| `source/delegates/TimerDelegate.mc` | Adicionar `onMenu()` para abrir Settings |
| `scripts/build-all.sh` | Script de build cross-device para validacao |

---

## 6. Arquitetura do fluxo

```
monkey.jungle
├── base.sourcePath = source
├── base.excludeAnnotations = test
│
├── fr255.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker
├── fr255s.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker
├── fr255m.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch
├── fr265.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
├── fr265s.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
├── fr955.excludeAnnotations = $(base.excludeAnnotations);amoled;hasSpeaker
├── fr965.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
├── fenix7.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker
├── fenix7pro.excludeAnnotations = $(base.excludeAnnotations);amoled;hasTouch;hasSpeaker
├── fenix843mm.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
├── fenix847mm.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
├── epix2.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker
├── venu3.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
├── venu3s.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch
└── vivoactive5.excludeAnnotations = $(base.excludeAnnotations);mip;noTouch;hasSpeaker

BehaviorDelegate flow (all delegates):
┌──────────────────────┐
│  Hardware Input      │
│  (button / touch)    │
└──────────┬───────────┘
           │ Connect IQ runtime maps to semantic event
           ▼
┌──────────────────────┐
│  BehaviorDelegate    │
│  onSelect()          │  ← Enter / Tap center
│  onBack()            │  ← Back / Swipe right
│  onMenu()            │  ← Long-press Up / Long-press center
│  onPreviousPage()    │  ← Up / Swipe up
│  onNextPage()        │  ← Down / Swipe down
└──────────┬───────────┘
           │ Delegate calls Model/pushView/popView
           ▼
┌──────────────────────┐
│  App Logic           │
│  (Model/Services)    │
└──────────────────────┘

Sleep prevention flow (already implemented):
Phase Transition → TomaApp.onModelEvent(ON_PHASE_CHANGE)
                 → attentionService.alertEndOfWork() / alertEndOfBreak()
                 → _flashBacklight() → Attention.backlight(true)
                 (only if backlightOnAlert setting == true)
```

---

## 7. Referencias para o plan.md

- `references/garmin_platform.md` §1 (devices + jungle IDs) — para completar manifest.
- `references/garmin_platform.md` §2.6 (BehaviorDelegate) — confirmar metodos.
- `references/garmin_platform.md` §6 (sleep/background) — confirmar que nao ha nada extra a fazer.
- `references/architecture.md` §5 (multi-device strategy) — annotations pattern.
- `spec/spec.md` §4.B14 (input mapping) + §4.B15 (sleep prevention).
- Task file: `tasks/02-comportamentos/11-input-multi-device.md`.

---

## 8. Checklist pre-plan

- [x] Todas as decisoes tem recomendacao.
- [x] Riscos identificados com mitigacao.
- [x] Arquivos listados com responsabilidade clara.
- [x] Fluxo de dados documentado.
- [x] Strings e cores mapeadas (N/A — task sem UI).
- [x] Nenhuma ambiguidade que impeca gerar plan.md.
