# Changelog

All notable changes to Toma Pomodoro are documented in this file.

## [1.0.0] — 2026-05-12

First public release on the Connect IQ Store.

### Added

- **Built-in presets** — 25/5, 30/5 and 50/10 (work/break in minutes).
- **Custom preset builder** — 5–90 min work, 1–30 min break, 1–10 cycles.
- **Pomodoro state machine** — Work → Short Break → Long Break → Complete, with
  pause/resume and single-cycle shortcut to Complete.
- **Timer view** — progress ring, phase label, remaining time and cycle pills.
- **Phase transition overlay** — 3s auto-dismiss notice on each phase change.
- **Alerts** — vibration, sound and backlight on phase changes, respecting Do
  Not Disturb and per-channel toggles in Settings.
- **Session recovery** — resume an in-progress session if the app is closed
  mid-session (offered on next launch if ≥ 60s remain).
- **Daily counter** — completed sessions counted per day, auto-reset at midnight.
- **Session history** — local log of completed sessions with date, preset and
  cycle count.
- **FIT activity recording** — optional, toggled in Settings. Creates a `.FIT`
  file synced to Garmin Connect via the device's own sync.
- **Localisation** — English and Portuguese, auto-detected from the system and
  overridable in Settings.
- **Responsive layout** — three screen-size buckets covering 15 devices from
  Forerunner 255S to Venu 3.

### Supported devices (15)

Forerunner 255, 255S, 255 Music, 265, 265S, 955, 965 • Fenix 7, 7 Pro,
8 (43mm), 8 (47mm) • Epix Gen 2 • Venu 3, 3S • Vivoactive 5.

### Permissions

- `Fit` — used only to create the optional FIT activity file when
  "Record as activity" is enabled in Settings.

### Privacy

No data is collected, transmitted or shared. Everything stays on-device.
See [docs/privacy.md](docs/privacy.md).
