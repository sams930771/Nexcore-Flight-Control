# Events and failure policy

Four supervised functions are passed to `parallel.waitForAny`: UI, sensor, burner, and telemetry. Functions are passed without calling them. CC:Tweaked broadcasts each event to the workers whose coroutine filter accepts it. Each sleep waits for its own timer ID and therefore cannot consume the UI's event copy. There is no hand-written scheduler in the production controller.

The UI pulls **unfiltered `os.pullEventRaw()`** events. It owns its timer ID and reschedules that timer every matching tick. Target entry is an event-based editor, not `read()`: key/char/paste input and telemetry ticks continue together. Key events trigger bindings, char events supply only target text, so a physical key does not fire a command twice. Repeated key events are ignored. Q/X bypass editor handling. Resize events redraw the screen.

The sensor worker invokes `back.getHeight()` through `peripheral.call`, then sleeps 0.25 seconds. Successful numeric finite samples always increment the sample counter and update freshness, even if altitude is identical. Velocity uses elapsed wall-clock time between successful samples; no global timing variable is used. Error/NaN/infinity samples do not refresh freshness. A failed read is retried next poll.

The burner worker serializes queued commands and verifies each side's readback. There is only one pending command and one in-flight command. UI input stays responsive during yielding writes. A partial write/readback failure stops the command, returns to MANUAL and requires D to rescan before further writes. It does not retry a partially completed write, cut power, or invent a fallback. Left/right operations are sequential, not physically atomic. Observed per-side values are available in telemetry; readbacks update only at startup, D scans and commanded writes, matching the original's lack of continuous external-change tracking.

Each worker runs inside `xpcall`. Unexpected exceptions or accidental normal returns are recorded as `worker_restart`; that worker restarts after one second while others continue. Sensor call errors are separately counted. UI crashes restart UI without affecting the sensor. Burner startup failures retry read-only discovery/readback before activation. Restarting never sends a default power. A failure of the framework or the supervisor itself is caught at the app boundary, reported on the computer screen and logged where possible, and exits preserving outputs. Such a failure is not silently treated as success.

Only an explicit exit sets shared `exit`: Q and terminate select hands-off; X selects off. `waitForAny` then returns and stops the remaining coroutines. X's redstone-off cleanup is performed outside the parallel group, attempts both sides even if one errors, and reports success/failure. It does not call a burner peripheral to shut off. Normal exits retain scroll values.

H and M change mode only. GO queues a calibrated integer command once; when fresh samples reach the tolerance region at low speed it becomes HOLD. Unlike v3.5.1, GO is rejected while the sensor is stale, unknown burner state blocks power writes, and partial burner errors do not claim success. Manual power is still available during sensor failure when burner state is known.

## Limits

CC parallel workers are cooperative coroutines, not separate CPU threads. A peripheral call that yields can block its worker while the UI continues; a non-yielding native/mod call or server-wide stall can stop the entire computer. No in-process timer can preempt that. A previously dispatched server task may finish even after the Lua worker is cancelled by Q or X; exiting does not roll back an accepted power change. X disables the redstone enable lines regardless of retained scroll values. Confirm the actual mod honors those lines.

The app does not automatically zero power on stale data, worker errors or Q. Sensor age/heartbeats are diagnostic evidence, not proof of fresh world physics. A sensor can return cached but numerically valid values. A power loss, chunk unload or server halt cannot be made safe by this script. Startup deliberately retains the original enable-on-launch behavior; run only when that behavior is intended.

References: [CC:Tweaked parallel API](https://tweaked.cc/module/parallel.html), [raw event handling](https://tweaked.cc/module/os.html#v:pullEventRaw). The exact supplied v3.5.1 source is the authority for this ship's hardware methods and calibration.
