# Validation results — 2026-10-25

All 17 Lua files compiled with Lua 5.2 through Lupa 2.8. The controller requires only CC:Tweaked's bundled APIs in Minecraft; Lupa is a local test dependency and is not included in the project.

**21 controller behavior tests and 6 installer scenarios passed.**

Controller coverage: exact six-point calibration; GO nearest integer power; Q preserves live power/output; X disables both outputs and retains scroll values; telemetry while typing; one-shot GO/HOLD/manual increments; blocked sensor/UI separation; sensor errors/recovery; unchanged valid samples remain fresh; injected burner-worker and UI exceptions restart visibly; partial burner write failures stop further commands; D reads without writing; Q/X during editor; terminate hands-off; disk failure visible without stopping flight input; mismatched startup values preserved; X during blocked sensor; stale-data GO rejection; X during delayed burner setter; manual 0/500 bounds; exit keys during supervisor backoff.

Installer coverage: new installation; update preserves local configuration/logs and old backup; byte-count mismatch leaves old installation intact; failed download leaves old install intact; manifest path traversal rejection; failed final move rolls back to the old installation.

The same 21 controller tests also passed using the **unmodified CC:Tweaked parallel scheduler** from commit `d5da2f7d16a761dc1e914bdbb1c4a883a4d2c8c7`. Its CC argument-validation/error-wrapper dependencies were stubbed in the harness; event filtering, event broadcast and coroutine scheduling were from the official file. Installer tests also passed in that run. The official source was downloaded only for testing and is not redistributed here.

[Pinned scheduler source](https://github.com/cc-tweaked/CC-Tweaked/blob/d5da2f7d16a761dc1e914bdbb1c4a883a4d2c8c7/projects/core/src/main/resources/data/computercraft/lua/rom/apis/parallel.lua)

To repeat basic tests: run `lua5.2 tests/run.lua` from repository root. To repeat the official-scheduler variant, download the linked file and set global `NEXCORE_TEST_PARALLEL` to its local path before loading `tests/run.lua` in Lua 5.2. The harness uses an isolated API environment and deterministic CC events.

Manifest sizes and ZIP content/integrity were checked during packaging. GitHub Actions runs syntax, behavior, installer and manifest checks on subsequent pushes. It has not been executed on GitHub for this delivery.

## Not verified

Minecraft/server hardware is unavailable here. Sensor caching, physical hover, redstone enable semantics, the installed mod version's yielding behavior, fuel/inertia and live GitHub installation still require in-game checks. The tests simulate yielding peripheral delays and errors; they cannot preempt non-yielding native calls or prove a server-wide freeze is fixed. The supplied v3.5.1 screen was adapted to 51×19; the older historic cockpit design was unavailable.
