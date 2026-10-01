#!/usr/bin/env python3
"""Generate the Victoria Fabrics launcher icons and splash artwork.

Two apps share one brand: a serif "V" monogram on the emerald brand gradient.
The customer build is emerald + gold; the admin build swaps the accent to
terracotta so staff can tell the two installs apart at a glance.

Outputs (committed, so a normal `flutter build` needs no extra tooling):
  assets/icon/icon_customer.png         1024x1024, used by flutter_launcher_icons
  assets/icon/icon_admin.png            1024x1024, used by flutter_launcher_icons
  assets/icon/icon_customer_foreground.png   adaptive-icon foreground, transparent
  assets/icon/icon_admin_foreground.png
  assets/images/splash.jpg              splash logo on the brand gradient

Usage:  python3 tool/generate_icons.py
Requires: pillow, plus a Playfair Display TTF (see FONT_CANDIDATES).
"""

from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, "assets", "icon")
IMAGE_DIR = os.path.join(ROOT, "assets", "images")

FONT_CANDIDATES = [
    "/tmp/fonts/playfair.ttf",
    os.path.join(ROOT, "tool", "fonts", "PlayfairDisplay-Bold.ttf"),
    "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
]

EMERALD = (0x0A, 0x68, 0x47)
EMERALD_DARK = (0x05, 0x48, 0x32)
EMERALD_LIGHT = (0x12, 0xA8, 0x69)
GOLD = (0xFF, 0xB8, 0x00)
GOLD_LIGHT = (0xFF, 0xD5, 0x4F)
TERRACOTTA = (0xCE, 0x6D, 0x3A)
TERRACOTTA_LIGHT = (0xE8, 0x92, 0x5A)
TERRACOTTA_DARK = (0x9E, 0x4C, 0x22)

# Customer: emerald field, gold monogram. Admin: terracotta field, gold
# monogram. Two brand colours that read differently at a glance on the home
# screen, which is the point of shipping two installs.
CUSTOMER_BG = [EMERALD_LIGHT, EMERALD, EMERALD_DARK]
CUSTOMER_MONO = [GOLD_LIGHT, GOLD, EMERALD_DARK]
ADMIN_BG = [TERRACOTTA_LIGHT, TERRACOTTA, TERRACOTTA_DARK]
ADMIN_MONO = [GOLD_LIGHT, GOLD, TERRACOTTA_DARK]

# Android density buckets: launcher icon and adaptive foreground sizes in px.
DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

# Supersample, then downscale, so the diagonal gradient and curves stay clean.
SS = 4


def _font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            font = ImageFont.truetype(path, size)
            try:
                font.set_variation_by_axes([700])
            except Exception:
                pass  # static fonts have no axes
            return font
    raise SystemExit("No usable font found. See FONT_CANDIDATES.")


def _lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _diagonal_gradient(size: int, stops) -> Image.Image:
    """Render a 45-degree multi-stop gradient (vectorised)."""
    t = (np.add.outer(np.arange(size), np.arange(size)) / (2 * (size - 1)))
    n = len(stops) - 1
    pos = np.clip(t * n, 0, n - 1e-6)
    seg = pos.astype(np.int32)
    local = (pos - seg)[..., None]
    stops_arr = np.array(stops, dtype=np.float64)
    rgb = (stops_arr[seg] * (1 - local) + stops_arr[seg + 1] * local)
    return Image.fromarray(rgb.astype(np.uint8), "RGB")


def _radial_gradient(size: int, inner, outer) -> Image.Image:
    """Render a radial gradient from the centre outwards (vectorised)."""
    y, x = np.mgrid[0:size, 0:size]
    c = (size - 1) / 2
    d = np.sqrt((x - c) ** 2 + (y - c) ** 2) / (np.sqrt(2) * c)
    d = np.clip(d, 0, 1)[..., None]
    inner_a = np.array(inner, dtype=np.float64)
    outer_a = np.array(outer, dtype=np.float64)
    rgb = inner_a * (1 - d) + outer_a * d
    return Image.fromarray(rgb.astype(np.uint8), "RGB")


def _monogram(size: int, accent, accent_light, on_transparent: bool):
    """Draw the V monogram, centred, with a gradient fill and light hairline."""
    font = _font(int(size * 0.62))
    text = "V"

    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    origin = ((size - tw) / 2 - bbox[0], (size - th) / 2 - bbox[1])
    d.text(origin, text, font=font, fill=255)

    # Tint the glyph with the brand gradient.
    fill = _diagonal_gradient(size, [accent_light, accent, EMERALD_DARK])
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(fill, (0, 0), mask)

    if not on_transparent:
        # Thin light outline lifts the monogram off the dark background.
        outline = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ImageDraw.Draw(outline).text(
            origin, text, font=font, fill=(255, 255, 255, 90),
            stroke_width=max(2, size // 320))
        canvas = Image.alpha_composite(outline, canvas)

    return canvas


def _icon(bg_stops, mono_stops, background=True, frame=True) -> Image.Image:
    size = 1024 * SS
    accent_light, accent, dark = mono_stops
    if background:
        base = _diagonal_gradient(size, bg_stops).convert("RGBA")

        # Soft accent glow behind the monogram.
        glow = _radial_gradient(
            size, _lerp(accent_light, bg_stops[1], 0.35), bg_stops[2]
        ).convert("RGBA")
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).ellipse(
            (size * 0.18, size * 0.18, size * 0.82, size * 0.82), fill=150)
        mask = mask.filter(ImageFilter.GaussianBlur(size // 12))
        base = Image.composite(glow, base, mask)

        # Hairline frame inset from the edge.
        if frame:
            inset = size * 0.075
            ImageDraw.Draw(base).rounded_rectangle(
                (inset, inset, size - inset, size - inset),
                radius=size * 0.14,
                outline=(*GOLD_LIGHT, 70),
                width=max(3, size // 240),
            )
        out = Image.alpha_composite(
            base, _monogram(size, accent, accent_light, False))
    else:
        # Adaptive-icon foreground: monogram only, kept inside the safe zone.
        out = _monogram(size, accent, accent_light, True)

    return out.resize((1024, 1024), Image.LANCZOS)


def _splash_logo() -> Image.Image:
    """Transparent splash logo (icon art + wordmark) for flutter_native_splash.

    Native splash paints a solid colour behind this, so the artwork must have
    an alpha channel or it shows as a square block.
    """
    w, h = 1200, 1200
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    icon = _icon(CUSTOMER_BG, CUSTOMER_MONO).convert("RGBA")
    icon = icon.resize((640, 640), Image.LANCZOS)
    canvas.alpha_composite(icon, ((w - 640) // 2, 150))

    d = ImageDraw.Draw(canvas)
    wordmark = _font(104)
    tb = d.textbbox((0, 0), "Victoria Fabrics", font=wordmark)
    d.text(((w - (tb[2] - tb[0])) / 2 - tb[0], 850), "Victoria Fabrics",
           font=wordmark, fill=(255, 255, 255, 255))

    tagline = _font(46)
    tb2 = d.textbbox((0, 0), "Your Neighbourhood Fabric Store", font=tagline)
    d.text(((w - (tb2[2] - tb2[0])) / 2 - tb2[0], 990),
           "Your Neighbourhood Fabric Store", font=tagline,
           fill=(*GOLD_LIGHT, 255))
    return canvas


def _write_admin_resources() -> None:
    """Write the admin flavor's own launcher resources.

    flutter_launcher_icons only targets the shared `main` source set, so the
    admin override lives in `src/admin/res`. Android's resource merger prefers
    the flavor set over `main` for the same resource name, which is what makes
    the two installs carry different icons from one codebase.
    """
    base = os.path.join(ROOT, "android", "app", "src", "admin", "res")
    mipmap = os.path.join(base, "mipmap-anydpi-v26")
    drawable = os.path.join(base, "drawable")
    values = os.path.join(base, "values")
    for path in (mipmap, values):
        os.makedirs(path, exist_ok=True)

    for density, (launcher, foreground) in DENSITIES.items():
        d_dir = os.path.join(base, f"mipmap-{density}")
        f_dir = os.path.join(drawable + f"-{density}")
        os.makedirs(d_dir, exist_ok=True)
        os.makedirs(f_dir, exist_ok=True)
        _icon(ADMIN_BG, ADMIN_MONO).resize(
            (launcher, launcher), Image.LANCZOS
        ).save(os.path.join(d_dir, "ic_launcher.png"))
        _icon(ADMIN_BG, ADMIN_MONO, background=False).resize(
            (foreground, foreground), Image.LANCZOS
        ).save(os.path.join(f_dir, "ic_launcher_foreground.png"))

    with open(os.path.join(mipmap, "ic_launcher.xml"), "w") as fh:
        fh.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '  <background android:drawable="@color/ic_launcher_background"/>\n'
            '  <foreground>\n'
            '      <inset android:drawable="@drawable/ic_launcher_foreground" android:inset="18%" />\n'
            '  </foreground>\n'
            '</adaptive-icon>\n'
        )

    with open(os.path.join(values, "colors.xml"), "w") as fh:
        fh.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources>\n'
            '    <color name="ic_launcher_background">#CE6D3A</color>\n'
            '</resources>\n'
        )
    print("Admin launcher resources written to", base)


def main() -> int:
    os.makedirs(ICON_DIR, exist_ok=True)
    os.makedirs(IMAGE_DIR, exist_ok=True)

    _icon(CUSTOMER_BG, CUSTOMER_MONO).save(os.path.join(ICON_DIR, "icon_customer.png"))
    _icon(CUSTOMER_BG, CUSTOMER_MONO, background=False).save(
        os.path.join(ICON_DIR, "icon_customer_foreground.png"))
    _icon(ADMIN_BG, ADMIN_MONO).save(os.path.join(ICON_DIR, "icon_admin.png"))
    _icon(ADMIN_BG, ADMIN_MONO, background=False).save(
        os.path.join(ICON_DIR, "icon_admin_foreground.png"))
    _splash_logo().save(os.path.join(IMAGE_DIR, "splash_logo.png"))
    _write_admin_resources()

    print("Icons written to", ICON_DIR)
    print("Splash written to", IMAGE_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main())
