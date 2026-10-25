"""Run after editing runtime sources, before uploading to GitHub."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
paths = ["nexcore.lua", "inspect.lua", "startup.example.lua", "config/default.lua", "config/local.example.lua"]
paths += [p.relative_to(root).as_posix() for p in sorted((root / "src").rglob("*.lua"))]
manifest = {"version": "3.5.2", "files": [{"path": p, "bytes": len((root / p).read_bytes())} for p in paths]}
(root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
print(f"Built manifest with {len(paths)} files")
