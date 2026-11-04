#!/usr/bin/env python3
"""Set the Keychron Q1 Max RGB Matrix color through its VIA HID interface."""
import argparse
import colorsys
import re
import sys

import hid

VENDOR_ID = 0x3434
PRODUCT_ID = 0x0810
RAW_HID_REPORT_SIZE = 32
VIA_GET_PROTOCOL_VERSION = 0x01
VIA_CUSTOM_SET_VALUE = 0x07
VIA_CUSTOM_SAVE = 0x09
RGB_MATRIX_CHANNEL = 0x03
RGB_MATRIX_EFFECT = 0x02
RGB_MATRIX_COLOR = 0x04
RGB_MATRIX_SOLID_COLOR = 0x01


def send(device, command, *payload):
    data = [command, *payload]
    if len(data) > RAW_HID_REPORT_SIZE:
        raise ValueError("VIA HID payload exceeds the report size")

    report = [0, *data, *([0] * (RAW_HID_REPORT_SIZE - len(data)))]
    if device.write(report) != len(report):
        raise OSError("short write to the keyboard's VIA HID interface")

    response = device.read(RAW_HID_REPORT_SIZE + 1, 1000)
    if len(response) == RAW_HID_REPORT_SIZE + 1 and response[0] == 0:
        response = response[1:]
    if len(response) != RAW_HID_REPORT_SIZE:
        raise OSError("no complete VIA response from the keyboard")
    if response[0] != command:
        raise RuntimeError(f"VIA rejected command 0x{command:02x} (response 0x{response[0]:02x})")
    return response[1:]


def open_via_device():
    devices = hid.enumerate(VENDOR_ID, PRODUCT_ID)
    if not devices:
        raise RuntimeError("Keychron Q1 Max was not found; connect it over USB")

    errors = []
    for info in devices:
        device = hid.device()
        try:
            device.open_path(info["path"])
            version = send(device, VIA_GET_PROTOCOL_VERSION)
            protocol_version = (version[0] << 8) | version[1]
            if protocol_version < 0x000B:
                raise RuntimeError(f"VIA protocol {protocol_version} is too old for this control")
            return device
        except (OSError, RuntimeError) as error:
            errors.append(str(error))
            device.close()

    detail = "; ".join(dict.fromkeys(errors))
    raise RuntimeError(
        "no accessible VIA interface found on the Q1 Max. Check that the NixOS "
        "USB device ownership rule is active and the keyboard is connected over USB"
        + (f" ({detail})" if detail else "")
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("color", help="accent color in #RRGGBB format")
    color = parser.parse_args().color
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
        parser.error("color must be in #RRGGBB format")

    red, green, blue = (int(color[i:i + 2], 16) for i in (1, 3, 5))
    hue, saturation, _ = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
    qmk_hue = round(hue * 255) % 256
    qmk_saturation = round(saturation * 255)

    device = open_via_device()
    try:
        send(device, VIA_CUSTOM_SET_VALUE, RGB_MATRIX_CHANNEL, RGB_MATRIX_EFFECT, RGB_MATRIX_SOLID_COLOR)
        send(device, VIA_CUSTOM_SET_VALUE, RGB_MATRIX_CHANNEL, RGB_MATRIX_COLOR, qmk_hue, qmk_saturation)
        send(device, VIA_CUSTOM_SAVE, RGB_MATRIX_CHANNEL)
    finally:
        device.close()

    print(f"Set Keychron Q1 Max lighting to {color.upper()}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError) as error:
        print(f"set-keychron-accent: {error}", file=sys.stderr)
        sys.exit(1)
