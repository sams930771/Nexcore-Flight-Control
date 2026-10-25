# v3.5.3 validation — 2026-10-25

- All **19 Lua files** compiled under Lua 5.2 (Lupa 2.8 test runtime).
- **21 existing controller behavior checks passed**, including target entry during sampling, stable unchanged sensor readings, delayed sensor/burner calls, Q/X, partial burner failure, worker restart, stale-data guards, range bounds and log failure.
- **6 installer scenarios passed**: fresh, update preserving local configuration/logs, wrong sizes, failed downloads, unsafe paths and rollback.
- **3 launcher path regressions passed**: installed folder, nested folder, root installation.
- **6 display/UI regression groups passed**: screenshot row alignment; both pages/all modes fit 51×19 with no event/peripheral calls; stale warnings and maximum target input; sample-timed acceleration; F1 editor state isolation; full-app F1 toggling/entry while polling continues.
- The suite also passed against the previously downloaded unmodified official CC:Tweaked parallel scheduler, commit `d5da2f7d16a761dc1e914bdbb1c4a883a4d2c8c7`. CC argument-check and error-wrapper dependencies were stubbed; event filtering/broadcast/scheduling were official. That file is not redistributed.
- Working backend modules and launcher were compared byte-for-byte with the user-supplied ZIP. `BACKEND_COMPARISON.txt` records hashes. Only display and the F1 control branch changed in runtime behavior.
- Main and diagnostics fixtures were rendered at 51×19 and visually inspected. The main screen was compared to the original reference; see `INTERFACE_COMPARISON.md` and previews.
- Runtime manifest byte sizes, archived file bytes and ZIP integrity were checked during packaging.

These are local mocked/API tests, not in-game hardware tests. They do not establish physical hover, sensor world-state freshness, fuel/inertia, redstone behavior, or resistance to a non-yielding mod/server stall. The user identifies the base as the working freeze-resolved version; this delivery preserves its backend without claiming independent Minecraft verification.

Repeat with `lua5.2 tests/run.lua` and `python3 tests/check_manifest.py`. Set global `NEXCORE_TEST_PARALLEL` to a downloaded official parallel.lua file path before running the suite to use its scheduler in the optional harness mode.
