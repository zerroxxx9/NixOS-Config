{
  hostVariables,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  wakeonlan = pkgs.writers.writePython3Bin "wakeonlan" { } ''
    import argparse
    import re
    import socket
    import sys

    parser = argparse.ArgumentParser(
        description="Send a Wake-on-LAN magic packet."
    )
    parser.add_argument(
        "mac",
        help="target MAC address, for example 30:56:0f:71:73:4d",
    )
    parser.add_argument(
        "-i",
        "--ip",
        default="255.255.255.255",
        help="broadcast address",
    )
    parser.add_argument("-p", "--port", default=9, type=int, help="UDP port")
    args = parser.parse_args()

    mac = re.sub(r"[^0-9A-Fa-f]", "", args.mac)
    if len(mac) != 12:
        print(f"invalid MAC address: {args.mac}", file=sys.stderr)
        sys.exit(2)

    mac_bytes = bytes.fromhex(mac)
    packet = b"\xff" * 6 + mac_bytes * 16

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.sendto(packet, (args.ip, args.port))
  '';
in {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-raspberrypi.nix"
  ];

  nixpkgs.hostPlatform = "armv6l-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  hardware.enableAllHardware = lib.mkForce false;
  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = lib.mkForce [
    "bcm2835-sdhost"
    "ext4"
    "mmc_block"
    "sdhci"
    "sdhci-pltfm"
    "vfat"
  ];
  boot.kernelPatches = [
    {
      name = "disable-rpi5-rp1-modules-on-rpi1";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        I2C_DESIGNWARE_CORE = no;
        I2C_DESIGNWARE_PLATFORM = no;
        PWM_RP1 = no;
        VIDEO_RP1_CFE = no;
      };
    }
  ];
  boot.supportedFilesystems = lib.mkForce [
    "ext4"
    "vfat"
  ];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.tailscale.enable = true;

  networking.hostName = hostVariables.host;
  console.keyMap = "de";

  environment.systemPackages = lib.mkForce (with pkgs; [
    bashInteractive
    tailscale
    wakeonlan
  ]);

  users.mutableUsers = false;
  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = hostVariables.username;
    extraGroups = ["wheel"];
    shell = pkgs.bashInteractive;
    hashedPassword = "$6$QmOTGoYJ66ngeSD5$501mimdEY1U98hcT/8htNJr.VPVzg4HG7jlblZmDwTjRxSoCOX2h0Vk5MOzqIhImLc2WmRXBCEPI/0DrAZQiD/";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];

  system.stateVersion = hostVariables.stateVersion;
}
