# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Toma** — a Pomodoro timer for Garmin wearable devices, built with the Connect IQ SDK (Monkey C). V1 is feature-complete.

## Status: V1 Complete

All 21 tasks delivered (8 visual prototypes + 12 behaviors + setup). Current phase: **bug fixing & polish**.

## Connect IQ Development

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) installed (typically at `~/Library/Application Support/Garmin/ConnectIQ/Sdks/`)
- Connect IQ SDK Manager or the VS Code extension (`garmin.monkey-c`) for compilation and simulation

### Common Commands

```bash
# Build the app (using the Connect IQ CLI)
monkeyc -f monkey.jungle -o bin/app.prg -y developer_key.der

# Run in simulator
connectiq &
monkeydo bin/app.prg <device-id>

# Run tests (using monkey barrel tests)
monkeyc -f monkey.jungle -o bin/app.prg -y developer_key.der --unit-test
```

> The exact commands depend on SDK installation path. Check `monkey.jungle` for build targets and supported devices.

### Supported Devices (15)

MIP: fr255, fr255s, fr255m, fenix7, fenix7pro, fr955
AMOLED: fr265, fr265s, fr965, epix2, vivoactive5, fenix843mm, fenix847mm, venu3, venu3s

## Architecture

```
source/
├── TomaApp.mc              — App entry point, orchestrates services + navigation
├── model/
│   ├── PomodoroModel.mc    — State machine (IDLE→RUNNING_WORK→SHORT_BREAK→...→COMPLETED)
│   ├── PomodoroState.mc    — State enum (IDLE, RUNNING_WORK, RUNNING_SHORT_BREAK, RUNNING_LONG_BREAK, PAUSED, COMPLETED)
│   ├── PomodoroEvent.mc    — Event enum (ON_START, ON_TICK, ON_PHASE_CHANGE, ON_COMPLETE, etc.)
│   ├── Preset.mc           — Preset data class + PresetLimits + Presets.builtinList()
│   ├── Session.mc          — History entry data class
│   └── RecoveryState.mc    — Recovery hydration DTO
├── services/
│   ├── TimerService.mc     — 1-second tick wrapper around Timer.Timer
│   ├── AttentionService.mc — Vibration/sound/backlight alerts (respects DND + settings)
│   ├── RecoveryService.mc  — Persist/restore active session via Storage (throttled 5s)
│   └── ActivityService.mc  — FIT activity recording (start/stop/discard)
├── repositories/
│   ├── SettingsRepository.mc  — Properties-backed settings (sound, vibration, backlight, record, language, etc.)
│   ├── PresetRepository.mc    — Custom preset persistence
│   ├── CounterRepository.mc   — Daily session counter with auto-reset
│   └── HistoryRepository.mc   — Session history (max entries in Storage)
├── views/
│   ├── HomeView.mc            — Preset carousel (3 builtin + custom + settings)
│   ├── TimerView.mc           — Running timer with ring, phase label, pills
│   ├── PhaseTransitionView.mc — 3s auto-dismiss overlay on phase change
│   ├── CycleCompleteView.mc   — End screen (start again / done)
│   ├── ConfirmStopView.mc     — Stop confirmation dialog
│   ├── RecoveryView.mc        — Resume/discard dialog on app start
│   ├── CustomBuilderView.mc   — Custom preset editor (work/break/cycles)
│   ├── HistoryView.mc         — Scrollable session history list
│   ├── SettingsMenu.mc        — Menu2-based settings page
│   ├── LanguageMenu.mc        — Language picker sub-menu
│   └── AboutView.mc           — Version + credits
├── delegates/                  — One per view, handles input (BehaviorDelegate / Menu2InputDelegate)
├── ui/
│   ├── layout/
│   │   ├── Bucket.mc          — Screen-size bucket detection (:small ≤220, :medium ≤290, :large)
│   │   ├── Colors.mc          — Toma palette (BG, BRAND, ACCENT, TEXT_PRIMARY, TEXT_MUTED, etc.)
│   │   └── Dimensions.mc      — All layout constants per bucket
│   └── components/             — Reusable draw helpers (TimerRing, TimerDisplay, PresetCard, etc.)
└── utils/
    ├── Strings.mc             — Inline i18n (PT/EN) resolved from settings + system language
    ├── TimeFormatter.mc       — mm:ss formatting
    └── DateUtils.mc           — Date helpers for history
tests/                          — 10 unit test files
```

## Key Patterns

- **Observer pattern**: `PomodoroModel` emits events via `_observers`; `TomaApp.onModelEvent()` reacts (alerts, navigation, persistence).
- **Bucket-based responsive UI**: `Bucket.detect()` returns `:small`/`:medium`/`:large`; all `Dimensions.*` functions branch on bucket.
- **Inline i18n**: `Strings.get(:key)` resolves language from settings → system fallback. No resource XML for strings.
- **Navigation**: `Ui.pushView` for overlays, `Ui.switchToView` for full-screen transitions (Home ↔ Timer ↔ CycleComplete).
- **Recovery**: On each tick (throttled 5s), session state persists to Storage. On next app start, offers resume if >60s remain.

## Pomodoro State Machine

States: `IDLE` → `RUNNING_WORK` → `RUNNING_SHORT_BREAK` → `RUNNING_WORK` (×cycles) → `RUNNING_LONG_BREAK` → `COMPLETED`

- `PAUSED` can be entered from any running state; resume restores the correct running state.
- Long break duration = `breakMin × 3` (in seconds).
- Single-cycle presets skip long break and go directly to COMPLETED.
- Phase transitions emit `ON_PHASE_CHANGE`; TomaApp pushes `PhaseTransitionView` (auto-dismiss 3s).

## References (read before any task)

This project follows **SDD (Spec Driven Development)** — see [SDD/sdd_manual.md](SDD/sdd_manual.md). Before touching code, the relevant reference docs **must** be read for the task at hand.

- [references/architecture.md](references/architecture.md) — folder structure, separation of responsibilities, naming, multi-device strategy.
- [references/design_system.md](references/design_system.md) — Toma brand adapted to Garmin (palette, typography, layout buckets, components).
- [references/garmin_platform.md](references/garmin_platform.md) — Connect IQ APIs used by Toma (Timer, Attention, Properties, Storage, Menu2, ActivityRecording).
- [references/workflow.md](references/workflow.md) — SDD loop applied to Toma (research → /clear → plan → /clear → execute).
- [references/benchmark.md](references/benchmark.md) — competitive landscape and roadmap.

## Spec

- [spec/spec.md](spec/spec.md) — full product spec: 8 pages (P1–P8), 14 components (C1–C14), 16 behaviors (B1–B16).

## Tasks (V1 — all complete)

- [tasks/00-setup/README.md](tasks/00-setup/README.md) — environment setup.
- `tasks/01-prototipos-visuais/01..08-*.md` — 8 visual prototype tasks (P1–P8).
- `tasks/02-comportamentos/01..12-*.md` — 12 behavior tasks (B1–B12).

## Brand

- [manual-de-marca/toma_brand_manual.md](manual-de-marca/toma_brand_manual.md) — Toma brand identity (untouched original).
- [manual-de-marca/logo/](manual-de-marca/logo/) — logo SVGs.
