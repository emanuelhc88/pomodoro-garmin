# Privacy Policy — Toma Pomodoro

**Last updated: 2026-05-11**

Toma Pomodoro ("the App") is a Pomodoro timer for Garmin wearable devices. This
policy explains what data the App handles and how.

## Data collection

**The App does not collect, transmit, or share any personal data.**

All data used by the App stays on your Garmin device:

- **Settings** (sound, vibration, backlight, language, record preference) are
  stored locally via the Connect IQ `Properties` API.
- **Session history** (work/break durations, number of cycles, timestamp) is
  stored locally via the Connect IQ `Storage` API.
- **Daily session counter** is stored locally and resets automatically each day.
- **Active session state** (used for recovery if the App is closed mid-session)
  is stored locally and cleared when the session ends.

No data is sent to any server, third party, or developer.

## FIT activity recording

If you enable "Record as activity" in Settings, the App uses the Garmin
`ActivityRecording` API to create a `.FIT` activity file for each completed
Pomodoro session. This file is saved to your Garmin device and synced to your
Garmin Connect account through Garmin's own infrastructure — not by the App.

The App does not have access to your Garmin Connect account or any data synced
to it. Garmin's own privacy policy applies to anything synced to Garmin Connect:
https://www.garmin.com/en-US/privacy/connect/

## Permissions

- **Fit** — required to create the optional FIT activity file. Used only while a
  Pomodoro session is running, and only if "Record as activity" is enabled.

## Data retention

Local data stays on your device until you:

- Delete the App, or
- Clear App data via Connect IQ settings, or
- In the case of session history, exceed the maximum number of stored entries
  (older entries are overwritten).

## Children

The App is not directed at children under 13 and does not knowingly collect any
data.

## Changes

If this policy changes, the updated version will be published at this URL with
a new "Last updated" date.

## Contact

For questions: open an issue at
https://github.com/emanuelhc88/pomodoro-garmin/issues
