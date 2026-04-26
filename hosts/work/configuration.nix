{
  hostVariables,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = hostVariables.host;
  networking.networkmanager.enable = true;

  age.identityPaths = ["/var/lib/agenix/work-agenix"];

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

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gnome];
  };

  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = "zerrox";
    extraGroups = ["networkmanager" "wheel"];
  };

  programs.direnv.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [biome];

  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      "jpmkfafbacpgapdghgdpembnojdlgkdl"
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      "gppongmhjkpfnbhagpmjfkannfbllamg"
      "fmkadmapgofadopljbjfkapdkoienihi"
      "eimadpbcbfnmbkopoojfekhnkhdbieeh"
      "gcknhkkoolaabfmlnjonogaaifnjlfnp"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /home/${hostVariables.username}/Dev 0755 ${hostVariables.username}"
    "d /home/${hostVariables.username}/Documents/Berufsschule 0755 ${hostVariables.username}"
    "d /home/${hostVariables.username}/Documents/Obsidian 0755 ${hostVariables.username}"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    unstable.bruno
    unstable.obsidian
    keepassxc
    vscode-with-extensions
    gh
    zip
    unzip
    burpsuite
    libreoffice-qt
    chromium
    element-desktop
    codex
    busybox
    (unstable.brave.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    })
  ];

  # agenix Secrets aktivieren
  modules.security.agenix.secrets = {
    wifiPasswords = true;
    copilotApiKey = true;
    braveBookmarks = true;
  };

  # YubiKey f?r SSH zu GitHub nutzen
  modules.security.yubikey = {
    enableSSH = true;
    enablePAM = false;
  };

  system.stateVersion = hostVariables.stateVersion;

  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];
}
