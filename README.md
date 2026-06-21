# Toma Pomodoro

A Pomodoro timer for Garmin wearable devices. Stay focused on your wrist — no
phone required.

## Features

- Built-in presets: 25/5, 30/5, 50/10
- Custom preset builder (5–90 min work / 1–30 min break / 1–10 cycles)
- Work → Break → Long Break state machine with visual progress ring
- Vibration, sound and backlight alerts on phase changes (respects Do Not Disturb)
- Optional FIT activity recording synced to Garmin Connect
- Session history and daily session counter
- Session recovery if the app is closed mid-session
- Portuguese and English (auto-detected, can be overridden in Settings)

## Supported Devices

Forerunner 255 / 255S / 255 Music, Forerunner 265 / 265S, Forerunner 955,
Forerunner 965, Fenix 7 / 7 Pro, Fenix 8 (43mm / 47mm), Epix Gen 2,
Venu 3 / 3S, Venu 4 (41mm / 45mm), Vivoactive 5.

## Permissions

- `Fit` — used only to create the optional FIT activity file when "Record as
  activity" is enabled in Settings.

No data is collected, transmitted, or shared. All data stays on your device.
See [Privacy Policy](docs/privacy.md).

## Battery notice

The timer keeps the screen active during a running session, which increases
battery consumption for the duration of the session.

## Development

See [CLAUDE.md](CLAUDE.md) for architecture and development guidelines.

```bash
monkeyc -f monkey.jungle -o bin/toma.prg -y developer_key -d fr255
```

## License

MIT — see [LICENSE](LICENSE).
