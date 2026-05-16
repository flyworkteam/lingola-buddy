"""Splash ile aynı mor gradyan kutu + maskot → 1024px uygulama ikonu."""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPLASH_PNG = ROOT / "assets" / "images" / "splash_app_icon.png"
OUT_PNG = ROOT / "assets" / "images" / "app_launcher_icon.png"

SIZE = 1024
# Splash: 134×133, borderRadius 20
CORNER_RADIUS = round(20 / 134 * SIZE)
PAD_TOP = round(5 / 133 * SIZE)
PAD_SIDE = round(10 / 134 * SIZE)


def _lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _gradient_color(y: int) -> tuple[int, int, int]:
    t = y / max(SIZE - 1, 1)
    top = (0x8F, 0x56, 0xFF)
    mid = (0x74, 0x29, 0xFF)
    bot = (0x5A, 0x17, 0xD4)
    if t <= 0.42:
        return _lerp(top, mid, t / 0.42)
    return _lerp(mid, bot, (t - 0.42) / 0.58)


def main() -> None:
    if not SPLASH_PNG.is_file():
        raise SystemExit(f"Missing {SPLASH_PNG}. Run: python3 tool/extract_svg_png.py")

    # Tam kare gradyan — iOS/Android kendi maskesini uygular.
    card = Image.new("RGB", (SIZE, SIZE))
    pixels = card.load()
    for y in range(SIZE):
        rgb = _gradient_color(y)
        for x in range(SIZE):
            pixels[x, y] = rgb
    card = card.convert("RGBA")

    mascot = Image.open(SPLASH_PNG).convert("RGBA")
    inner_w = SIZE - PAD_SIDE * 2
    inner_h = SIZE - PAD_TOP - PAD_SIDE
    mascot.thumbnail((inner_w, inner_h), Image.Resampling.LANCZOS)
    offset_x = (SIZE - mascot.width) // 2
    offset_y = PAD_TOP
    card.alpha_composite(mascot, (offset_x, offset_y))

    OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
    card.save(OUT_PNG, format="PNG", optimize=True)
    print(f"Wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
