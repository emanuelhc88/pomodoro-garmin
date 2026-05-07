# Toma — Architecture

> Documento de fundação. **Toda tarefa deve ler isto antes de tocar código.**

Define a estrutura técnica do projeto Connect IQ: organização de pastas, separação de responsabilidades, regras de codificação e estratégia multi-device. As decisões aqui são **canônicas** — qualquer divergência exige justificativa explícita na Spec Tática da tarefa.

---

## 1. Tipo de projeto Connect IQ

**Decisão: App (full application).**

Justificativa:
- Requer **tela full** com countdown grande, anel de progresso e múltiplos estados visuais.
- Requer **input completo** (botões em FR, touch + botões em AMOLED).
- Requer **execução longa** (até 90min de work + breaks). Widgets têm timeout (~10s) e Data Fields só rodam dentro de outras activities.
- Requer **gravação como activity FIT** própria — só `App` pode iniciar `ActivityRecording.createSession`.

Tipos rejeitados:
- ❌ Watch face: sem interação adequada, restrição de ciclos de render.
- ❌ Widget: timeout impede sessões de 25min+.
- ❌ Data Field: não pode iniciar uma activity própria, fica preso em activities existentes.

---

## 2. Estrutura de pastas

```
pomodoro-garmin/
├── manifest.xml                    # Metadata, devices suportados, permissões
├── monkey.jungle                   # Build config multi-device
├── developer_key.der               # NÃO commitar (gitignore)
├── source/
│   ├── TomaApp.mc                  # AppBase: lifecycle, entry point
│   ├── views/
│   │   ├── HomeView.mc             # P1
│   │   ├── CustomBuilderView.mc    # P2
│   │   ├── TimerView.mc            # P3 + P4 (paused é overlay)
│   │   ├── PhaseTransitionView.mc  # P5
│   │   ├── CycleCompleteView.mc    # P6
│   │   ├── HistoryView.mc          # P7
│   │   └── SettingsView.mc         # P8 (Menu2-based)
│   ├── delegates/
│   │   ├── HomeDelegate.mc
│   │   ├── CustomBuilderDelegate.mc
│   │   ├── TimerDelegate.mc
│   │   ├── PhaseTransitionDelegate.mc
│   │   ├── CycleCompleteDelegate.mc
│   │   ├── HistoryDelegate.mc
│   │   └── SettingsDelegate.mc
│   ├── model/
│   │   ├── PomodoroModel.mc        # State machine + estado in-memory
│   │   ├── PomodoroState.mc        # Enum + transições válidas
│   │   ├── Preset.mc               # Tipo: work/break/cycles
│   │   └── Session.mc              # Tipo: registro de sessão concluída
│   ├── services/
│   │   ├── TimerService.mc         # Wrapper Toybox.Timer
│   │   ├── AttentionService.mc     # Wrapper Toybox.Attention (vibrate, tone, backlight)
│   │   ├── ActivityService.mc      # Wrapper Toybox.ActivityRecording (FIT)
│   │   └── StorageService.mc       # Wrapper Properties + Storage
│   ├── repositories/
│   │   ├── SettingsRepository.mc   # Read/write settings
│   │   ├── PresetRepository.mc     # Read/write preset customizado
│   │   └── HistoryRepository.mc    # Read/write últimas N sessões
│   ├── ui/
│   │   ├── components/
│   │   │   ├── TimerRing.mc        # Anel circular de progresso
│   │   │   ├── TimerDisplay.mc     # MM:SS centralizado
│   │   │   ├── SessionPills.mc     # 4 pills indicando ciclos
│   │   │   ├── PrimaryButton.mc    # Botão estilo Toma
│   │   │   └── PhaseLabel.mc       # Label "Focus" / "Break" / "Long break"
│   │   └── layout/
│   │       └── Bucket.mc           # Helper: detectar bucket de tela (small/medium/large)
│   └── utils/
│       ├── TimeFormatter.mc        # Format MM:SS, hh:mm, etc.
│       └── DateUtils.mc            # Reset diário, comparar datas
├── resources/
│   ├── drawables/
│   │   ├── drawables.xml
│   │   ├── colors.xml              # Toda paleta Toma adaptada
│   │   ├── launcher_icon.png       # Ícone exportado (vários tamanhos)
│   │   └── …
│   ├── fonts/                      # Custom fonts via .fnt (se viável; senão remover)
│   ├── layouts/
│   │   ├── home.xml
│   │   ├── timer.xml
│   │   └── …
│   ├── strings/
│   │   ├── strings.xml             # Strings padrão (en)
│   │   ├── strings_pt.xml          # Tradução PT
│   │   └── …
│   └── settings/
│       ├── properties.xml          # Defaults dos toggles
│       └── settings.xml            # UI de settings via Garmin Connect mobile
├── resources-large/                # Overrides para devices large (390-454px)
│   └── layouts/
├── resources-small/                # Overrides para devices small (218px)
│   └── layouts/
└── tests/
    ├── PomodoroModelTest.mc
    ├── DateUtilsTest.mc
    └── …
```

Regras:
- **Cada View tem 1 Delegate par.** Mesmo nome (ex: `HomeView` ↔ `HomeDelegate`).
- **Diretório `tests/`** roda via `monkeyc --unit-test`. Testes são opcionais para Views/Delegates (UI), obrigatórios para `model/` e `utils/`.
- **`resources-{bucket}/`** são overrides automáticos via `monkey.jungle`. O resolver do Connect IQ aplica o mais específico que casa com o device.

---

## 3. Separação de responsabilidades

### `App` (`TomaApp.mc`)
- Único entry point. Extends `Application.AppBase`.
- Lifecycle: `onStart`, `onStop`, `getInitialView`, `onSettingsChanged`.
- **Não tem lógica de domínio.** Só conecta peças e gerencia transição de Views.
- Mantém referência singleton para `PomodoroModel` e os repositories.

### `View` (`source/views/`)
- Extends `WatchUi.View` ou `WatchUi.Menu2`.
- **Render only.** `onLayout`, `onShow`, `onUpdate`, `onHide`.
- Lê estado do Model via getter readonly. **Nunca muta estado.**
- Não fala com Services diretamente — fala com Model.
- Não conhece `Application.Properties` — fala com Repository.

### `Delegate` (`source/delegates/`)
- Extends `WatchUi.BehaviorDelegate` (preferido) ou `WatchUi.InputDelegate`.
- **Input only.** Mapeia `onKey`, `onTap`, `onSwipe`, `onSelect`, `onMenu` para ações no Model.
- Pode chamar `WatchUi.pushView` / `WatchUi.popView` para navegar.
- Não desenha nada.

### `Model` (`source/model/`)
- **Coração da lógica de domínio.** State machine, contadores, regras de transição.
- Recebe ações via métodos públicos: `start(preset)`, `pause()`, `resume()`, `stop()`, `tick()`, `transitionPhase()`.
- Emite eventos via callback array: `addObserver(callback)`. Cada View que precisa reagir registra um observer no `onShow` e remove no `onHide`.
- **Não toca Garmin APIs.** Sem `Toybox.Timer`, sem `Toybox.Attention`, sem `Toybox.Application.Properties`.
- Recebe Services e Repositories via construtor (DI manual).

### `Services` (`source/services/`)
- **Wrappers finos** sobre APIs Toybox. Razão: testabilidade + capability detection centralizado.
- Cada Service expõe métodos com tipos do projeto, não do Toybox.
- Exemplo: `AttentionService.alertSessionEnd()` chama internamente `Attention.vibrate(…)` com a profile correta, e checa `Attention has :vibrate` antes.
- Services são stateless. Estado fica no Model.

### `Repositories` (`source/repositories/`)
- **Única camada que toca persistência** (`Application.Properties` e `Application.Storage`).
- Expõem métodos com tipos do projeto: `SettingsRepository.getSoundEnabled() as Boolean`.
- Centralizam keys: nada de strings literais espalhadas pelo código.

### `Components` (`source/ui/components/`)
- Funções/classes reutilizáveis de render. Recebem `dc` (Device Context) + parâmetros e desenham.
- Não têm estado próprio. Estado vem por argumento.

---

## 4. Regras estritas de codificação

### Naming
- Arquivos: PascalCase, terminam com sufixo do papel (`HomeView.mc`, `TimerDelegate.mc`, `PomodoroModel.mc`).
- Classes: PascalCase, mesmo nome do arquivo.
- Métodos / variáveis: camelCase.
- Constantes: UPPER_SNAKE_CASE em `module Constants`.
- Símbolos de evento (callback names): `:onTimerTick`, `:onPhaseChanged` — sempre com prefixo `:on`.

### Imports
- `using Toybox.Foo as Foo;` no topo do arquivo.
- **Nunca** `using Toybox.Foo.*;` (não existe em Monkey C — só registro a regra).
- Reordenar para minimizar memória: importar só o necessário.

### Tipos
- Habilitar typecheck via `:typecheck=Strict` no `monkey.jungle`.
- Toda função pública declara tipos: `function start(preset as Preset) as Void { … }`.
- Privadas (helpers) podem omitir tipos, mas preferimos declarar.

### Erros
- `try/catch` **somente** em fronteiras: I/O (Properties, Storage), parsing externo, ActivityRecording.
- **Não** usar `try/catch` para mascarar bugs internos. Se uma transição de estado é inválida, logar e retornar — mas não silenciar.
- Logging via `System.println` em DEBUG; remover em release (use `(:debug)` annotation).

### Strings
- **Sempre** via `Rez.Strings.<key>` ou `WatchUi.loadResource`. Nunca string literal hardcoded em View/Delegate.
- Strings de erro/log podem ser literais (não viajam para o usuário).

### Cores e dimensões
- **Sempre** via `Rez.Colors.<key>` e `Rez.Dimensions.<key>`. Nunca `0xE8432D` hardcoded em código.
- Exceção: utils de manipulação de cor podem usar literais internamente.

### Memória
- Evitar alocação dentro de `onUpdate` (chama 60+ vezes por segundo em alguns devices).
- Pré-criar buffers reutilizáveis em `onLayout`.
- Não criar arrays/dicionários grandes — heap budget é apertado.

---

## 5. Estratégia multi-device

### Annotations + jungle

`monkey.jungle` declara classes de devices via `excludeAnnotations`:

```
base.sourcePath = source

# Devices MIP (sem touch, 64 cores)
fr255.sourcePath = $(base.sourcePath)
fr255.excludeAnnotations = $(common_excludes);amoled;hasTouch
fr955.excludeAnnotations = $(common_excludes);amoled;hasTouch

# Devices AMOLED (com touch)
fr265.excludeAnnotations = $(common_excludes);mip;noTouch
fr965.excludeAnnotations = $(common_excludes);mip;noTouch
venu3.excludeAnnotations = $(common_excludes);mip;noTouch
```

No código:

```monkeyc
(:amoled) function renderRingAmoled(dc) { ... }
(:mip) function renderRingMip(dc) { ... }

(:hasTouch) class TouchDelegate extends BehaviorDelegate { ... }
(:noTouch) class ButtonDelegate extends BehaviorDelegate { ... }
```

### Capability detection (runtime)

Para features opcionais cuja presença varia mesmo dentro de uma classe (ex: alguns FR têm vibração, outros não):

```monkeyc
if (Attention has :vibrate) {
    Attention.vibrate(profile);
}
```

### Buckets de resolução

Definidos em `references/design_system.md` (seção "Layouts responsivos"). Usar `Bucket.detect()` (em `source/ui/layout/Bucket.mc`) que retorna `:small | :medium | :large` baseado em `System.getDeviceSettings().screenWidth`.

---

## 6. Permissions (manifest.xml)

Lista mínima:

- `Background` — para o timer continuar rodando se a app for pra background (controverso; testar).
- `Sensor` — se gravarmos HR no FIT activity.
- `FitContributor` — para campos custom no FIT.

Não pedimos:
- `Communications` (não há sync na V1).
- `PersistedContent` (não criamos waypoints/routes).
- `Positioning` (sem GPS).

---

## 7. Anti-patterns proibidos

- ❌ View que muta Model.
- ❌ Delegate que desenha em `dc`.
- ❌ Model que importa `Toybox.WatchUi`.
- ❌ Service com estado mutável.
- ❌ String/cor/dimensão literal em View ou Delegate.
- ❌ `try/catch` que engole exceção sem log.
- ❌ Alocação em `onUpdate`.
- ❌ Acesso a `Application.Properties` fora de Repository.
- ❌ `var x;` sem tipo no escopo de classe pública.
- ❌ Criar feature flag sem motivo declarado na Spec Tática.

---

## 8. Como esta arquitetura serve à FASE 2 do SDD

Cada task na pasta `tasks/` referencia uma seção desta arquitetura. Quando a IA gera a Spec Tática (FASE 2.3), ela **lê apenas as seções relevantes** desta `architecture.md` + design_system.md + garmin_platform.md, evitando despejar tudo no contexto. Isso preserva o context window e evita decisões inconsistentes entre tarefas.

A regra é: **a Spec Tática lista os arquivos exatos a serem criados/modificados**, e esses arquivos seguem rigorosamente as pastas e responsabilidades acima. Qualquer arquivo proposto fora dessas pastas é red flag e deve ser questionado.
