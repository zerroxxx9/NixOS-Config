{
  hostVariables,
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = hostVariables.host;
    networkmanager.enable = true;
    nameservers = ["1.1.1.1" "1.0.0.1"];
  };

  virtualisation.virtualbox.host.enable = true;

  services.resolved.enable = true;
  # Keep resolv.conf useful for tools that read it directly and reject 127.0.0.53.
  environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";

  time.timeZone = "Europe/Berlin";

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.etc."wireplumber/wireplumber.conf.d/51-cmedia-q9-nosuspend.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          { node.name = "alsa_input.usb-CMEDIA_Q9-1-00.*" }
        ]
        actions = {
          update-props = {
            session.suspend-timeout-seconds = 0
            audio.rate = 48000
            audio.channels = 1
            audio.position = [ MONO ]
          }
        }
      }
    ]
  '';

  services.udev.extraRules = ''
    # Q9 (0d8c:0135) - prevent suspend that can wedge streaming
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0d8c", ATTR{idProduct}=="0135", TEST=="power/control", ATTR{power/control}="on"
  '';
  boot.kernelParams = ["usbcore.autosuspend=-1"];
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gnome];
  };

  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = "zerrox";
    extraGroups = ["networkmanager" "wheel" "vboxusers" "libvirtd" "kvm"];
  };

  programs.direnv.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [biome];

  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      "jpmkfafbacpgapdghgdpembnojdlgkdl"
      "gppongmhjkpfnbhagpmjfkannfbllamg"
      "gcknhkkoolaabfmlnjonogaaifnjlfnp"
      "gkeojjjcdcopjkbelgbcpckplegclfeg"
      "gphhapmejobijbbhgpjhcjognlahblep"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /home/${hostVariables.username}/Dev 0755 ${hostVariables.username}"
    "d /home/${hostVariables.username}/Documents/Obsidian 0755 ${hostVariables.username}"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    keepassxc
    vscode-with-extensions
    gh
    zip
    unzip
    chromium
    codex
    busybox
    easyeffects
    pnpm
    nodejs_24
    jython
    qemu
    virt-manager
    virt-viewer
    # Cyber Specific
    feroxbuster
    burpsuite
    seclitss
    gobuster
    ffuf
    sqlmap
    nmap
    thc-hydra

    (unstable.brave.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    })
  ];

  # Fresh installs can end up with /etc/resolv.conf pointing at Tailscale's
  # DNS (100.100.100.100) before the host is actually logged in, which breaks
  # basic name resolution (Discord, curl, etc). Prefer normal DNS for now.
  modules.software.tailscale.acceptDNS = false;

  system.stateVersion = hostVariables.stateVersion;

  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];
}
