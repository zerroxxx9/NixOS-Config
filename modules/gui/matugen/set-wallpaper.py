#!/usr/bin/env python3
"""Set the wallpaper and re-theme the desktop from it.

    set-wallpaper <image> [--preview] [--mode dark|light] [--scheme NAME]

Pipeline: matugen palette -> fixed code/signal hues -> OKLCH contrast check ->
matugen renders the templates -> reload apps. --preview stops after the
contrast check and prints the numbers without applying anything.

A `<image>.theme.toml` next to the wallpaper (`harbor.png` -> `harbor.theme.toml`)
may pin `accent` (hex), `scheme` and `mode`, and override single colours in a
`[colors]` table (any name from the --preview report, e.g. `keyword`, `text`,
`ui_surface`, `ansi_red`). Overrides are applied last, after the contrast
check, so they are used exactly as written:

    accent = "#7aa2f7"
    [colors]
    keyword = "#ff79c6"
    ui_surface = "#10131a"
"""
import argparse
import colorsys
import json
import math
import os
import subprocess
import sys
import tomllib
from pathlib import Path

MATUGEN = os.environ.get("MATUGEN_BIN", "matugen")
CONFIG = os.environ["MATUGEN_CONFIG"]
PALETTE = os.environ["MATUGEN_PALETTE"]
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "matugen"

TEXT_RATIO = 4.5
COMMENT_RATIO = 3.0
GREY_CHROMA = 0.02
COLORFUL_CHROMA = 0.16


# --- colour maths (sRGB <-> OKLab <-> OKLCH) -------------------------------

def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#" + "".join(f"{round(min(max(c, 0), 1) * 255):02x}" for c in rgb)


def lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def delin(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def rgb_to_oklch(rgb):
    r, g, b = (lin(c) for c in rgb)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360


def oklch_to_rgb(L, C, H):
    a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return tuple(min(max(delin(max(c, 0)), 0), 1) for c in (r, g, bl))


def luminance(rgb):
    r, g, b = (lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def hue_dist(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def enforce(rgb, bg, ratio, dark):
    """Move lightness only until `rgb` reaches `ratio` against `bg`."""
    L, C, H = rgb_to_oklch(rgb)
    step = 0.01 if dark else -0.01
    while contrast(oklch_to_rgb(L, C, H), bg) < ratio and 0 < L < 1:
        L += step
    return oklch_to_rgb(min(max(L, 0), 1), C, H)


# --- palette ---------------------------------------------------------------

def average_color(image):
    out = subprocess.run(
        ["magick", image, "-resize", "1x1!", "-format", "%[hex:u.p{0,0}]", "info:"],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return hex_to_rgb(out)


def matugen_colors(image, mode, scheme, accent):
    cmd = [MATUGEN, "image", str(image), "--source-color-index", "0", "--json", "hex",
           "-m", mode, "-t", scheme, "--dry-run", "-q"]
    if accent:
        cmd = [MATUGEN, "color", "hex", accent, "--json", "hex", "-m", mode,
               "-t", scheme, "--dry-run", "-q"]
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    colors = json.loads(out)["colors"]
    return {k: v["default"]["color"] for k, v in colors.items()}


def build(image, mode, scheme, accent):
    dark = mode == "dark"
    ui = matugen_colors(image, mode, scheme, accent)
    primary_c = rgb_to_oklch(hex_to_rgb(ui["primary"]))

    # Grey wallpapers get a calm neutral palette; very colourful ones fall
    # back to tonal-spot so the interface does not shout.
    if scheme == "scheme-content" and primary_c[1] > COLORFUL_CHROMA:
        return build(image, mode, "scheme-tonal-spot", accent)

    bg = hex_to_rgb(ui["surface"])
    fixed = tomllib.loads(Path(PALETTE).read_text())
    blend, gap, chroma = fixed["blend"], fixed["min_hue_gap"], fixed["chroma"]
    target = primary_c[2]
    base_L = 0.78 if dark else 0.45

    def nudge(h, amount):
        d = ((target - h + 180) % 360) - 180
        return (h + d * amount) % 360

    hues = dict(fixed["code"])
    blended = {k: nudge(h, blend) for k, h in hues.items()}
    names = list(hues)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            if hue_dist(blended[a], blended[b]) < gap:
                blended[a], blended[b] = hues[a], hues[b]

    adjusted = {}
    for name, h in blended.items():
        adjusted[name] = enforce(oklch_to_rgb(base_L, chroma, h), bg, TEXT_RATIO, dark)
    for name, h in fixed["signal"].items():
        adjusted[name] = enforce(oklch_to_rgb(base_L, chroma, nudge(h, blend / 2)), bg, TEXT_RATIO, dark)
    adjusted["comment"] = enforce(hex_to_rgb(ui["outline"]), bg, COMMENT_RATIO, dark)
    adjusted["text"] = enforce(hex_to_rgb(ui["on_surface"]), bg, TEXT_RATIO, dark)
    adjusted["text_dim"] = enforce(hex_to_rgb(ui["on_surface_variant"]), bg, COMMENT_RATIO, dark)
    adjusted["accent"] = enforce(hex_to_rgb(ui["primary"]), bg, TEXT_RATIO, dark)

    # ANSI palette: signal + code hues for the six colours, lighter for bright.
    ansi_src = {"red": "error", "green": "success", "yellow": "warning", "blue": "function",
                "magenta": "keyword", "cyan": "constant"}
    ansi = {}
    for name, src in ansi_src.items():
        L, C, H = rgb_to_oklch(adjusted[src])
        ansi[name] = adjusted[src]
        ansi["bright_" + name] = oklch_to_rgb(min(L + 0.08, 0.95) if dark else max(L - 0.08, 0.2), C, H)
    ansi["black"] = hex_to_rgb(ui["surface_container_high"])
    ansi["bright_black"] = adjusted["comment"]
    ansi["white"] = adjusted["text_dim"]
    ansi["bright_white"] = adjusted["text"]

    hexed = {k: rgb_to_hex(v) for k, v in {**adjusted, **{f"ansi_{k}": v for k, v in ansi.items()}}.items()}
    ui_names = ["surface", "surface_container", "surface_container_high", "surface_container_highest",
                "surface_container_low", "on_surface", "on_surface_variant", "primary", "on_primary",
                "primary_container", "on_primary_container", "secondary", "tertiary", "outline",
                "outline_variant", "error", "on_error", "background", "on_background",
                "inverse_surface", "inverse_on_surface"]
    for n in ui_names:
        hexed[f"ui_{n}"] = ui[n]
    return hexed, ui, mode, scheme, primary_c


def with_opacity(hexed, image, dark):
    """Raise kitty's opacity until text stays readable over the wallpaper."""
    avg = average_color(image)
    bg = hex_to_rgb(hexed["ui_surface"])
    checked = [hexed[k] for k in ("text", "text_dim", "ansi_red", "ansi_green", "ansi_yellow", "ansi_blue")]
    for alpha in [x / 100 for x in range(80, 101, 5)]:
        eff = tuple(alpha * b + (1 - alpha) * a for b, a in zip(bg, avg))
        if all(contrast(hex_to_rgb(c), eff) >= TEXT_RATIO for c in checked):
            return alpha
    return 1.0


def report(hexed, bg_hex):
    bg = hex_to_rgb(bg_hex)
    lines = []
    for name in ("text", "text_dim", "comment", "keyword", "string", "function", "type", "number",
                 "constant", "operator", "error", "warning", "info", "success", "accent"):
        want = COMMENT_RATIO if name in ("comment", "text_dim") else TEXT_RATIO
        r = contrast(hex_to_rgb(hexed[name]), bg)
        lines.append(f"{name:10} {hexed[name]}  {r:5.2f}:1  {'ok' if r >= want else 'FAIL'}")
    return lines


def rgb_triplet(h):
    return ",".join(str(round(c * 255)) for c in hex_to_rgb(h))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--preview", action="store_true")
    ap.add_argument("--mode")
    ap.add_argument("--scheme")
    args = ap.parse_args()

    image = Path(args.image).resolve()
    override = {}
    theme_file = image.with_suffix(".theme.toml")
    if theme_file.exists():
        override = tomllib.loads(theme_file.read_text())
    mode = args.mode or override.get("mode", "dark")
    scheme = args.scheme or override.get("scheme", "scheme-content")
    accent = override.get("accent")

    # Nearly grey wallpapers: neutral palette with a fixed accent.
    first = matugen_colors(image, mode, "scheme-tonal-spot", accent)
    if not accent and rgb_to_oklch(hex_to_rgb(first["primary"]))[1] < GREY_CHROMA:
        scheme, accent = "scheme-neutral", "#6c8ebf"

    hexed, ui, mode, scheme, _ = build(image, mode, scheme, accent)
    hexed["lyrics"] = hexed["accent"]  # kinetic lyrics colour; follows the accent unless overridden
    for name, value in override.get("colors", {}).items():
        if name not in hexed:
            print(f"warning: unknown colour '{name}' in {theme_file.name}", file=sys.stderr)
        elif not (isinstance(value, str) and len(value) == 7 and value.startswith("#")):
            print(f"warning: '{name}' must be a #rrggbb hex string", file=sys.stderr)
        else:
            hexed[name] = value.lower()
    opacity = with_opacity(hexed, image, mode == "dark")
    hexed["opacity"] = f"{opacity:.2f}"
    # Same fill alpha as the shell panels (opacity * 0.6), as hex for mako.
    hexed["surface_alpha"] = f"{round(opacity * 0.6 * 255):02x}"
    print(f"{image.name}: mode={mode} scheme={scheme} opacity={opacity:.2f}")
    print("\n".join(report(hexed, hexed["ui_surface"])))
    if args.preview:
        return

    STATE.mkdir(parents=True, exist_ok=True)

    data = {"adj": hexed,
            "adj_rgb": {k: rgb_triplet(v) for k, v in hexed.items() if v.startswith("#")},
            "adj_raw": {k: v.lstrip("#") for k, v in hexed.items() if v.startswith("#")},
            "scheme_mode": mode}
    (STATE / "current-wallpaper").write_text(str(image))
    data_file = STATE / "adjusted.json"
    data_file.write_text(json.dumps(data))
    subprocess.run([MATUGEN, "image", str(image), "--source-color-index", "0", "-c", CONFIG,
                    "-m", mode, "-t", scheme, "--import-json", str(data_file), "-q"], check=True)

    # Reload: wallpaper (awww), Hyprland borders, kitty (SIGUSR1). rofi, GTK,
    # the shell and Zed/Vesktop/Obsidian read the new files on their own.
    subprocess.run(["awww", "img", str(image), "--transition-type", "grow",
                    "--transition-duration", "1.2", "--transition-fps", "60"], check=False)
    subprocess.run(["hyprctl", "reload"], check=False)
    subprocess.run(["pkill", "-USR1", "kitty"], check=False)
    subprocess.run(["makoctl", "reload"], check=False)


if __name__ == "__main__":
    sys.exit(main())
