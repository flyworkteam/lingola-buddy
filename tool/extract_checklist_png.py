"""checklist_create_screen.svg içindeki gömülü PNG'yi raster dosyasına çıkarır."""
import base64
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
svg = root / "assets" / "icons" / "checklist_create_screen.svg"
out = root / "assets" / "images" / "plan_checklist_illustration.png"
out.parent.mkdir(parents=True, exist_ok=True)

text = svg.read_text(encoding="utf-8")
m = re.search(r'xlink:href="data:image/png;base64,([^"]+)"', text)
if not m:
    raise SystemExit("base64 PNG bulunamadı")
data = base64.b64decode(m.group(1))
out.write_bytes(data)
print(f"wrote {out} ({len(data)} bytes)")
