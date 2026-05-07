# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Pomodoro timer application for Garmin wearable devices, built with the Garmin Connect IQ SDK using Monkey C.

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

## Architecture

Garmin Connect IQ apps follow the MVC pattern with Monkey C:

- `source/` — Application source files (`.mc`)
  - `*App.mc` — App entry point, extends `Application.AppBase`; initializes the app and returns the initial view
  - `*View.mc` — UI rendering, extends `Ui.View`; `onLayout`, `onShow`, `onUpdate` lifecycle methods
  - `*Delegate.mc` — Input handling, extends `Ui.BehaviorDelegate`; handles button presses and gestures
  - `*Model.mc` (if present) — Business logic for Pomodoro state machine (work/break timers, counts)
- `resources/` — Layouts, strings, drawables, fonts
  - `layouts/` — XML layout files for screens
  - `strings/` — Localized string definitions
  - `images/` — App icons and graphics
- `monkey.jungle` — Build configuration; defines products (target devices) and source paths

## Pomodoro State Machine

The core logic manages transitions between: `WORK` → `SHORT_BREAK` → `WORK` (×4) → `LONG_BREAK`. Key state: elapsed time, session count, current phase, running/paused flag. Timers use `Timer.Timer` from the Connect IQ API.

## References (read before any task)

This project follows **SDD (Spec Driven Development)** — see [SDD/sdd_manual.md](SDD/sdd_manual.md). Before touching code, the relevant reference docs **must** be read for the task at hand.

- [references/architecture.md](references/architecture.md) — folder structure, separation of responsibilities, naming, multi-device strategy.
- [references/design_system.md](references/design_system.md) — Toma brand adapted to Garmin (palette, typography, layout buckets, components).
- [references/garmin_platform.md](references/garmin_platform.md) — Connect IQ APIs used by Toma (Timer, Attention, Properties, Storage, Menu2, ActivityRecording).
- [references/workflow.md](references/workflow.md) — SDD loop applied to Toma (research → /clear → plan → /clear → execute).
- [references/benchmark.md](references/benchmark.md) — competitive landscape and roadmap.

## Spec

- [spec/spec.md](spec/spec.md) — full product spec: 8 pages (P1–P8), 14 components (C1–C14), 16 behaviors (B1–B16).

## Tasks

V1 is sliced into 21 issue files. Tasks must be executed in order. Each task is one full FASE 2 loop (research → /clear → plan → /clear → execute) — see [references/workflow.md](references/workflow.md).

- [tasks/00-setup/README.md](tasks/00-setup/README.md) — environment setup (one-time, not a loopable issue).
- `tasks/01-prototipos-visuais/01..08-*.md` — 8 visual prototype tasks (one per page P1–P8).
- `tasks/02-comportamentos/01..12-*.md` — 12 behavior tasks (state machine, timer loop, vibration, persistence, FIT activity, etc.).

## Brand

- [manual-de-marca/toma_brand_manual.md](manual-de-marca/toma_brand_manual.md) — Toma brand identity (untouched original).
- [manual-de-marca/logo/](manual-de-marca/logo/) — logo SVGs.
