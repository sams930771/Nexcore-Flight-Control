# v3.5.3 — Original interface restoration

Base: user-supplied `Nexcore-Flight-Control-main.zip`, working v3.5.2.

- Restored the screenshot's 19-row NEXCORE header, monochrome palette, aligned telemetry fields, separators, keyboard instructions and target-entry/footer placement.
- Retained every existing keyboard action. Added F1 as an independent diagnostics-page toggle, usable during target entry.
- Added display-only acceleration from observed velocity/sample timestamps. STOP Y remains explicitly unavailable because the working backend has no stopping model. Calibrated equilibrium prediction is labeled CAL ALT on diagnostics.
- Kept actual backend status text rather than copying obsolete autopilot status logic from the old screenshot.
- Replaced display.lua and added only the F1 presentation-state branch to control.lua. App scheduling, hardware polling/writes, error supervision, logs, calibration math and corrected launcher are unchanged byte-for-byte.
- Retained all six calibration measurements and power/timing settings; incremented version/installer/manifest to 3.5.3.
- Added screen bounds, stale warning, editor, F1/worker and visual layout regression checks. Reorganized flattened auxiliary files into standard GitHub folders. Packaged without old embedded archives or duplicate downloads.

No old flight backend was restored. No in-game hardware testing was performed.
