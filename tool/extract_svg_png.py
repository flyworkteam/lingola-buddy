import base64
import pathlib
import re

def main() -> None:
    svg_path = pathlib.Path(__file__).resolve().parent.parent / "assets" / "icons" / "app_icon.svg"
    text = svg_path.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"href=\"data:image/png;base64,([^\"]+)\"", text)
    if not m:
        m = re.search(r"xlink:href=\"data:image/png;base64,([^\"]+)\"", text)
    if not m:
        raise SystemExit("base64 PNG not found in SVG")
    data = base64.b64decode(m.group(1))
    out = svg_path.parent.parent / "images" / "splash_app_icon.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(data)
    print(out, len(data))


if __name__ == "__main__":
    main()
