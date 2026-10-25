# Comparison with the supplied v3.4.8 screenshot

The design reference is the user's original NEXCORE screenshot. Both reference and restored main screen use 19 text rows, starting at terminal column 1 with no extra left margin. The terminal fixture was rendered at 51 columns and inspected visually beside the reference. The preview uses glyph shapes sampled from that reference (fallback font for characters absent from it); it is not a screenshot captured in Minecraft.

| Row | Reference layout | Restored layout / necessary change |
| ---: | --- | --- |
| 1 | NEXCORE FLIGHT CONTROL v3.4.8 | Same placement, current version v3.5.3 |
| 2 | 35-character gray separator | Same |
| 3 | MODE, PHASE | Same labels/spacing; phase describes preserved backend state |
| 4–6 | ALTITUDE, TARGET, ERROR, values at column 11 | Same, three decimal places |
| 7–9 | VERT SPEED, ACCEL, STOP Y, values at column 13 | Same; speed/acceleration four decimals; unsupported STOP Y shown as --- |
| 10 | POWER, REQUEST | Same placement; live verified/queued values |
| 11 | SENSOR: ONLINE | Same start, plus AGE and sample count fitting 51 columns; STALE warning when needed |
| 12 | STATUS | Same start; working backend status text and current warnings |
| 13 | Gray separator | Same |
| 14 | T=TARGET, G=GO, H=HOLD, M=MANUAL | Same |
| 15 | +/-=POWER, D=SCAN | Same plus F1=DIAG |
| 16 | Q=QUIT, X=BURNERS OFF | Same; Q retains output, X disables it |
| 17 | Gray separator | Same |
| 18 | TARGET ENTRY: PRESS T | Same when idle; live target text when editing |
| 19 | FLIGHT LOG ACTIVE | Same when logger heartbeat is healthy; errors/stale log warnings replace it when needed |

Black background, light-gray header/altitude/status/controls, white target/error/vertical dynamics/power, and dark-gray separators/log footer reproduce the reference's tonal hierarchy. Color APIs work on standard monochrome CC terminals without requiring an advanced computer.

The supplied backend does not calculate braking distance. Showing the old STOP Y number or using equilibrium calibration as a stopping forecast would misrepresent the working system. The field stays visible but unavailable. The calibrated prediction is available separately on F1.

Automatic checks assert reference row/label alignment, page bounds at 51×19, visible stale warnings, complete maximum-length target entry, and zero hardware/event calls from rendering. Both pages were rendered and visually inspected. Long error tracebacks are summarized on F1 and preserved in full in log files.
