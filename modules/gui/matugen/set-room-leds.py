#!/usr/bin/env python3
"""Set the room LEDs to a colour through Home Assistant's REST API.

    set-room-leds <#rrggbb>

Environment (set by the Nix wrapper):
    HA_URL              base URL of Home Assistant
    HA_TOKEN_FILE       file holding a long-lived access token
    HA_LIGHT_ENTITIES   comma-separated light entity ids
    HA_LED_EFFECT       optional effect sent right after the colour (some Zigbee
                        strips only apply a new colour once an effect runs)

Brightness is left alone; only the colour changes. Exits non-zero with a
one-line message on stderr when Home Assistant cannot be reached.
"""
import colorsys
import json
import os
import re
import sys
import urllib.error
import urllib.request

TIMEOUT = 3
TRANSITION = 2
MIN_SATURATION = 0.85  # UI accents are muted for contrast; LEDs need to be vivid


def vivid(hex_color):
    r, g, b = (int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, s, _ = colorsys.rgb_to_hsv(r, g, b)
    # Greys have no hue worth saturating; keep them as they are.
    if s > 0.05:
        s = max(s, MIN_SATURATION)
    return [round(c * 255) for c in colorsys.hsv_to_rgb(h, s, 1.0)]


def call(url, token, data):
    request = urllib.request.Request(
        f"{url}/api/services/light/turn_on",
        data=json.dumps(data).encode(),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    urllib.request.urlopen(request, timeout=TIMEOUT).close()


def main():
    if len(sys.argv) != 2 or not re.fullmatch(r"#[0-9a-fA-F]{6}", sys.argv[1]):
        print("usage: set-room-leds #rrggbb", file=sys.stderr)
        return 2

    try:
        url = os.environ["HA_URL"].rstrip("/")
        entities = [e for e in os.environ["HA_LIGHT_ENTITIES"].split(",") if e]
        with open(os.environ["HA_TOKEN_FILE"]) as f:
            token = f.read().strip()
    except (KeyError, OSError) as err:
        print(f"set-room-leds: configuration error: {err}", file=sys.stderr)
        return 1

    effect = os.environ.get("HA_LED_EFFECT", "")
    try:
        call(url, token, {"entity_id": entities, "rgb_color": vivid(sys.argv[1]),
                          "transition": TRANSITION})
        if effect:
            call(url, token, {"entity_id": entities, "effect": effect})
    except urllib.error.HTTPError as err:
        print(f"Home Assistant answered HTTP {err.code} {err.reason}", file=sys.stderr)
        return 1
    except (urllib.error.URLError, TimeoutError, OSError) as err:
        print(f"Home Assistant unreachable: {getattr(err, 'reason', err)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
