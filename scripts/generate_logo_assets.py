"""Generate UniPass logo PNG assets from SVGs using cairosvg + Pillow."""

import io
import os
import sys

from PIL import Image
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM

ASSETS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "logo")
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SPLASH_LOGO_SVG = os.path.join(ASSETS_DIR, "unipass_logo.svg")
ICON_SVG = os.path.join(ASSETS_DIR, "unipass_icon.svg")


def svg_to_pil(svg_path: str, width: int) -> Image.Image:
    """Render SVG to PIL Image at given width, preserving aspect ratio."""
    from reportlab.graphics import renderPM as rl_renderPM

    drawing = svg2rlg(svg_path)
    if drawing is None:
        raise RuntimeError(f"Failed to parse SVG: {svg_path}")

    # Render at native size then resize
    png_data = rl_renderPM.drawToString(drawing, fmt="PNG", bgColor=None)
    img = Image.open(io.BytesIO(png_data)).convert("RGBA")
    aspect = img.width / img.height
    target_height = int(width / aspect)
    return img.resize((width, target_height), Image.LANCZOS)


def composite_on_canvas(img: Image.Image, canvas_size: int) -> Image.Image:
    """Center the image on a square transparent canvas."""
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - img.width) // 2
    y = (canvas_size - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def save_png(img: Image.Image, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"  -> {path} ({img.width}x{img.height})")


def main():
    print("Generating UniPass logo PNG assets...\n")

    # ====== 1. Splash logo (1024x1024, full logo centered) ======
    print("[1/6] Splash logo (1024x1024)...")
    logo = svg_to_pil(SPLASH_LOGO_SVG, 800)
    splash = composite_on_canvas(logo, 1024)

    # Android splash logo
    android_splash = os.path.join(PROJECT_DIR, "android", "app", "src", "main", "res", "drawable-nodpi", "splash_logo.png")
    save_png(splash, android_splash)

    # iOS splash logo
    ios_splash_dir = os.path.join(PROJECT_DIR, "ios", "Runner", "Assets.xcassets", "splash_logo.imageset")
    save_png(splash, os.path.join(ios_splash_dir, "splash_logo.png"))
    # Also copy as universal
    save_png(splash, os.path.join(ios_splash_dir, "splash_logo@2x.png"))
    save_png(splash, os.path.join(ios_splash_dir, "splash_logo@3x.png"))

    # ====== 2. Android mipmap app icons ======
    print("\n[2/6] Android mipmap app icons...")
    icon = svg_to_pil(ICON_SVG, 1024)
    # For adaptive icons, the foreground has a transparent background

    android_mipmap = os.path.join(PROJECT_DIR, "android", "app", "src", "main", "res")
    icon_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    for folder, size in icon_sizes.items():
        resized = icon.resize((size, size), Image.LANCZOS)
        path = os.path.join(android_mipmap, folder, "ic_launcher_foreground.png")
        save_png(resized, path)

    # ====== 3. Android legacy app icons (with purple bg) ======
    print("\n[3/6] Android legacy app icons (purple bg)...")
    purple_bg = Image.new("RGBA", (1024, 1024), (99, 102, 241, 255))  # #6366F1
    purple_bg.paste(icon, (0, 0), icon)

    for folder, size in icon_sizes.items():
        resized = purple_bg.resize((size, size), Image.LANCZOS)
        path = os.path.join(android_mipmap, folder, "ic_launcher.png")
        save_png(resized, path)

    # ====== 4. Android round icons ======
    print("\n[4/6] Android round app icons...")
    for folder, size in icon_sizes.items():
        resized = purple_bg.resize((size, size), Image.LANCZOS)
        path = os.path.join(android_mipmap, folder, "ic_launcher_round.png")
        save_png(resized, path)

    # ====== 5. iOS AppIcon ======
    print("\n[5/6] iOS AppIcon...")
    ios_appicon = os.path.join(PROJECT_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    icon_sizes_ios = {
        "icon-20@2x.png": (40, 40),
        "icon-20@3x.png": (60, 60),
        "icon-29@2x.png": (58, 58),
        "icon-29@3x.png": (87, 87),
        "icon-40@2x.png": (80, 80),
        "icon-40@3x.png": (120, 120),
        "icon-60@2x.png": (120, 120),
        "icon-60@3x.png": (180, 180),
        "icon-20.png": (20, 20),
        "icon-29.png": (29, 29),
        "icon-40.png": (40, 40),
        "icon-76.png": (76, 76),
        "icon-76@2x.png": (152, 152),
        "icon-83.5@2x.png": (167, 167),
        "icon-1024.png": (1024, 1024),
    }

    for filename, (w, h) in icon_sizes_ios.items():
        resized = purple_bg.resize((w, h), Image.LANCZOS)
        path = os.path.join(ios_appicon, filename)
        save_png(resized, path)

    # ====== 6. Final assets logo copy ======
    print("\n[6/6] Copying high-res logos to assets/logo...")
    logo_1024 = composite_on_canvas(logo, 1024)
    save_png(logo_1024, os.path.join(ASSETS_DIR, "unipass_logo.png"))
    icon_1024 = composite_on_canvas(icon, 1024)
    save_png(icon_1024, os.path.join(ASSETS_DIR, "unipass_icon.png"))

    print("\nDone! All logo assets generated.")


if __name__ == "__main__":
    main()
