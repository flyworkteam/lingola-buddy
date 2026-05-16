"""Gömülü PNG içeren onboarding SVG'lerinden raster çıkarır (flutter_svg ile boş görünümü önler)."""
import base64
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
icons = root / "assets" / "icons"
out_dir = root / "assets" / "images"
out_dir.mkdir(parents=True, exist_ok=True)

pat = re.compile(r'xlink:href="data:image/png;base64,([^"]+)"')

for i in (1, 2, 3):
    text = (icons / f"onboarding{i}.svg").read_text(encoding="utf-8")
    m = pat.search(text)
    if not m:
        raise SystemExit(f"onboarding{i}.svg: base64 PNG bulunamadı")
    data = base64.b64decode(m.group(1))
    out = out_dir / f"onboarding_{i}.png"
    out.write_bytes(data)
    print(f"wrote {out} ({len(data)} bytes)")
