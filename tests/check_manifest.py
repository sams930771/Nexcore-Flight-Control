import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "manifest.json").read_text())
assert manifest["version"] == "3.5.3"
for entry in manifest["files"]:
    assert len((root / entry["path"]).read_bytes()) == entry["bytes"], entry["path"]
print(f"PASS manifest: {len(manifest['files'])} byte sizes")
