# v3.5.2

- Split v3.5.1 into configuration, hardware, control, UI, logging and supervision modules.
- Retain T/G/H/M/+/-/D/Q/X, getHeight/getScrollValue/setScrollValue, power ranges, startup enable behavior, and all six measured calibration points.
- Replace blocking target `read()` with event-based editing; give sensor, burner, UI and telemetry independent workers under the CC parallel API.
- Catch/log worker exceptions and restart the affected worker. Keep Q/X active during target editing and worker restart backoff.
- Add persistent rotating peripheral-boundary logs, heartbeats and JSONL telemetry.
- Add explicit burner readback checks, fail-visible partial writes and stale-sensor GO rejection.
- Add GitHub structure, wget staging installer, backup/rollback, local configuration preservation and tests.

Known limits: no in-game hardware verification, no pre-diagnostic historic UI reconstruction, and no ability to preempt a non-yielding mod/server stall. GO remains an open-loop calibrated power selection, not altitude PID or landing/navigation.
