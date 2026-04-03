#!/usr/bin/env python3
# Regenerate the default Open Graph image (1200x630).
# Matches site.css light theme: --bg #fff, --text #141414.
# Name only — platforms already show title and domain in the link preview.
# Requires: pip install pillow
# Run from repo root: python3 scripts/generate_og_image.py

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
INTER_PATH = ROOT / "assets" / "fonts" / "InterVariable.ttf"
OUTPUT = ROOT / "assets" / "og-image.png"

# Mirrors :root in site.css (light theme)
BG = (255, 255, 255)  # --bg
TEXT = (20, 20, 20)  # --text #141414

WIDTH, HEIGHT = 1200, 630
CORNER_R = 28

LINE1 = "Nick"
LINE2 = "Raushenbush"


def _try_truetype(path: str, size: int, index: int = 0) -> ImageFont.FreeTypeFont | None:
    try:
        return ImageFont.truetype(path, size, index=index)
    except OSError:
        return None


def load_sans(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Prefer the site stack (Avenir Next / Helvetica Neue on macOS); else bundled Inter."""
    candidates: list[tuple[str, int]] = []
    if sys.platform == "darwin":
        # .ttc files contain multiple faces; indices vary by OS version.
        avn = "/System/Library/Fonts/Supplemental/Avenir Next.ttc"
        hlv = "/System/Library/Fonts/Helvetica.ttc"
        if Path(avn).is_file():
            for idx in (4, 3, 2, 1, 0) if bold else (0, 1, 2, 3, 4):
                candidates.append((avn, idx))
        if Path(hlv).is_file():
            for idx in (1, 0) if bold else (0, 1):
                candidates.append((hlv, idx))

    for path, idx in candidates:
        f = _try_truetype(path, size, idx)
        if f is not None:
            return f

    if INTER_PATH.is_file():
        f = _try_truetype(str(INTER_PATH), size, 0)
        if f is not None:
            return f

    return ImageFont.load_default()


def text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont) -> tuple[float, float]:
    bbox = draw.textbbox((0, 0), text, font=font)
    return float(bbox[2] - bbox[0]), float(bbox[3] - bbox[1])


def main() -> None:
    card_mask = Image.new("L", (WIDTH, HEIGHT), 0)
    ImageDraw.Draw(card_mask).rounded_rectangle(
        (0, 0, WIDTH - 1, HEIGHT - 1), radius=CORNER_R, fill=255
    )

    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    white = Image.new("RGBA", (WIDTH, HEIGHT), (*BG, 255))
    img.paste(white, (0, 0), card_mask)

    draw = ImageDraw.Draw(img)

    line1_font = load_sans(118, bold=True)
    line2_font = load_sans(118, bold=True)

    w1, h1 = text_size(draw, LINE1, line1_font)
    w2, h2 = text_size(draw, LINE2, line2_font)
    gap = 8.0
    block_h = h1 + gap + h2
    max_w = max(w1, w2)
    x0 = (WIDTH - max_w) / 2
    y0 = (HEIGHT - block_h) / 2

    draw.text((x0, y0), LINE1, font=line1_font, fill=TEXT)
    draw.text((x0, y0 + h1 + gap), LINE2, font=line2_font, fill=TEXT)

    flat = Image.new("RGB", (WIDTH, HEIGHT), BG)
    flat.paste(img, (0, 0), img.split()[3])
    flat.save(OUTPUT, "PNG", optimize=True)
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
