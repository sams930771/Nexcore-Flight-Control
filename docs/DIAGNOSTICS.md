# Investigating a freeze

v3.5.3: press F1 to toggle the diagnostics screen; D still performs the original diagnostic scan. Target entry, Q and X remain active on either page. The main screen matches the original NEXCORE reference. Full tracebacks remain in log files when the F1 error summary is too long for one terminal row.

First use Q to return to the computer shell without changing burner outputs. X is the separate burners-off exit. Avoid power-cycling an airborne computer just to collect logs.

1. Start the controller and note LOOP, SAMPLES, SENSOR AGE and UNCHANGED.
2. Press T, leave target entry open for several seconds, then enter an altitude. LOOP and SAMPLES should continue while typing.
3. Use M and one +/- command, then H. Both modes should continue sampling. H holds power, not a specific altitude.
4. Press D if burner state becomes unavailable. This queues a read-only scan and logs peripheral call boundaries. Use the inventory program from the shell if method discovery is needed.
5. Press Q and copy `logs/events.jsonl`, `logs/telemetry.jsonl`, their rotated backups, and `logs/inventory.json` if present. Keep the log segment immediately before the problem.

| Evidence | Interpretation / next check |
| --- | --- |
| LOOP/render timestamps advance; SAMPLES stops | Sensor worker is delayed or failing; inspect sensorStage and its last call_begin/call_end |
| SENSOR AGE grows; failures grow | Sensor calls return errors/invalid values; inspect SENSOR errors |
| SENSOR AGE stays low; UNCHANGED grows; SAMPLES advances | Sensor repeatedly returns the same valid value; may be stable hover or cached mod data |
| Burner stage stays WRITE/VERIFY; UI still works | Burner peripheral call is yielding without returning; Q remains available |
| worker_restart appears | A worker exception was caught; detail contains its traceback |
| Logging error appears on screen | Disk access/full disk may prevent evidence being saved; flight input continues |
| All displayed heartbeats and all files stop | Could be computer/server pause, non-yielding mod call or logging/storage stall; a Lua watchdog cannot prove which |

Events are UTC epoch milliseconds. Sensor and burner stages are marked before entering calls; last successful sensor timestamp is distinct from the start/end call timestamps. An absent call_end means the call did not return before the last flushed log record, not definitive proof of a server bug. Telemetry snapshots are independent of the sensor and input workers, but shared server/CPU/storage stalls can stop all of them.

The old source's blocking `read()` could consume the sole timer event. Once that event was lost, redraws only occurred on keyboard events; this matches the reported symptom but does not prove it was the only fault. The new editor never calls `read()`, and tests leave it open across multiple timer events.
