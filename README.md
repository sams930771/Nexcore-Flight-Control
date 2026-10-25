# NEXCORE Flight Control v3.5.2

Modular CC:Tweaked / Create Aeronautics controller, rebuilt from the supplied v3.5.1 source. Open this folder in VS Code. Upload **its contents** to your GitHub repository root to use the installer.

## Preserved behavior

| Key | Action |
| --- | --- |
| T | Enter target absolute altitude; Enter accepts, Escape cancels |
| G | GO: apply the nearest calibrated integer power once |
| H | HOLD current power; this is not altitude PID |
| M | MANUAL; leaves current power unchanged |
| + / - | Adjust manual power by exactly 1; keypad supported |
| D | Diagnostic scan; re-read burner power without changing scroll values |
| **Q** | **Exit to computer shell; leave burners running** |
| **X** | **Disable left/right redstone outputs and exit** |

Q and X work during target entry. Ctrl+T termination also exits hands off. Holding a key does not generate repeated power commands. Wait for a pending write to finish before requesting another power change.

Hardware is **left/right** burners (`getScrollValue`, `setScrollValue`) and **back** sensor (`getHeight`). The earlier conversation mentioned `getAltitude`, but the actual supplied source uses `getHeight`; this project follows that source. Manual power is **0–500**, GO is **38–48**, tick interval is **0.25 s**, arrival tolerance is **0.35 blocks** with vertical speed below **0.05 blocks/s**.

Startup reads both existing burner scroll values before enabling both redstone outputs, matching v3.5.1's activation behavior. It does not reset power to a default or write scroll values at startup. If left/right values differ, both are preserved and a mismatch is shown. The next accepted manual power command synchronizes both sides. Q, Ctrl+T and unexpected controller errors preserve outputs; X turns redstone off without overwriting saved scroll values. A computer power loss/server stall cannot be handled by Lua.

## Calibration retained verbatim

| Power | Measured altitude |
| ---: | ---: |
| 39 | 146.3424 |
| 42 | 164.8510 |
| 43 | 170.7356 |
| 44 | 176.4890 |
| 46 | 187.6230 |
| 47 | 193.0140 |

Prediction uses the original piecewise linear interpolation, extrapolating at the ends. GO chooses the closest prediction among integers 38–48, taking the lower power on an exact tie. It does not chase altitude or pulse between powers. A target between equilibrium heights may never be reached; the screen shows the predicted height. Measurements are specific to the original ship/load. No automatic calibration overwrites them.

## Install from GitHub

1. Extract the ZIP and open the `NEXCORE-Flight-Control-v3.5.2` folder in VS Code.
2. Create a GitHub repository and upload everything inside this folder, including `src`, `config`, `manifest.json`, and `install.lua`, to its root. GitHub's web upload may omit dotfolders; use VS Code Git to include the workflow/settings if wanted. No repository has been created or uploaded for you.
3. Replace `YOUR_NAME` and `YOUR_REPO` below. Run on the CC computer with HTTP enabled:

```text
wget https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/install.lua nexcore-install.lua
nexcore-install.lua YOUR_NAME YOUR_REPO main nexcore
nexcore/nexcore.lua
```

Use a commit SHA instead of `main` in **both** commands for a fixed release. Private repos require an accessible raw endpoint; this installer does not embed GitHub credentials. No ZIP extraction is needed in Minecraft. The installer downloads the modular runtime; it never starts the controller or changes burner outputs.

For a manual install, copy the folder into the computer's files, then run its `nexcore.lua`. No external Lua packages are needed in Minecraft.

Optional startup: after verifying manual operation, copy `startup.example.lua` to `/startup.lua` and adjust its controller path if needed. It runs once and leaves you in the shell after Q or X. Installation never overwrites your existing startup program.

## Updates and local data

Run the installer again using the same destination. It stages every file, verifies manifest byte sizes and Lua syntax, preserves `config/local.lua` and `logs/`, and keeps the previous folder as `nexcore.backup`. A failed download leaves the existing install intact; inspect/remove `nexcore.stage` before retrying. An existing backup is never overwritten: rename/archive it before the next update. If the final folder move fails, the installer attempts to restore the old folder.

To roll back, rename the new `nexcore` folder, then rename `nexcore.backup` to `nexcore`. Preserve any new logs before doing so. Updates do not migrate unidentified files elsewhere on the computer. Copy legacy calibration overrides into `config/local.lua` yourself if needed; the six known measurements are already present in defaults.

The manifest checks truncation/byte counts, not cryptographic authenticity. Only install from your trusted repository over HTTPS. If editing runtime files before publishing, regenerate the manifest with `python tools/build_manifest.py`; CI checks it for drift.

## Diagnostics and freezing

The display retains the supplied v3.5.1 telemetry and all bindings, arranged to fit a normal 51×19 computer. The pre-diagnostic historic cockpit appearance was not recoverable and is not claimed as restored.

- `logs/events.jsonl`: startup/exit, power requests, peripheral call begin/end and duration, errors, worker restarts.
- `logs/telemetry.jsonl`: one record per second including independent worker heartbeats, render time, sample count, sensor age, unchanged age, call stages, observed power and errors.
- Run `nexcore/inspect.lua` for a read-only method inventory at `logs/inventory.json`.

Each stream rotates at roughly 256 KiB into three backups. Files are closed after each record to preserve evidence of the last call before a hang. Logs and local overrides are ignored by Git.

**The known `read()` timer-consumption risk has been removed. A complete in-game freeze fix is not proven.** Sensor and burner workers can yield independently while UI/telemetry continue. A successful unchanged altitude sample refreshes sensor age; only the unchanged-age counter grows. This distinguishes a stable sensor reading from missing samples. Logging failures appear on the screen and do not disable flight input.

See [docs/DIAGNOSTICS.md](docs/DIAGNOSTICS.md) for interpretation and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for event handling and failure policy.

## Source layout and checks

```text
nexcore.lua              launcher; loads defaults and optional local overrides
install.lua              wget bootstrap with staging and rollback
inspect.lua              read-only peripheral method inventory
src/nexcore/             app, control, hardware, display, calibration, log, supervisor, util
config/default.lua       exact v3.5.1 hardware/power/calibration defaults
config/local.example.lua optional override example
docs/                    architecture, diagnostic guide and test results
tests/                   deterministic event, worker and installer tests
tools/build_manifest.py  regenerates installer file list and byte sizes
.github/workflows/       Lua 5.2 syntax, behavior and manifest CI
.vscode/                 optional Lua editor settings
```

With desktop Lua 5.2 installed, run from the repository root:

```sh
lua5.2 tests/run.lua
python3 tests/check_manifest.py
```

GitHub Actions also syntax-checks every Lua file. Tests mock Minecraft hardware; they cannot validate physical hover or the server's peripheral implementation. See [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md) for the completed local checks.
