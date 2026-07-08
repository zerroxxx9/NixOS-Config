{
  hostVariables,
  pkgs,
  config,
  inputs,
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

  security.rtkit.enable = true;

  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=524288
  '';

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
      "gphhapmejobijbbhgpjhcjognlahblep"
      "pfafglenejhimeinpohlpdobpnmocddj"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /home/${hostVariables.username}/Dev 0755 ${hostVariables.username}"
    "d /home/${hostVariables.username}/Private 0755 ${hostVariables.username}"
    "d /home/${hostVariables.username}/Documents/Berufsschule 0755 ${hostVariables.username}"
    "d /home/${hostVariables.username}/Documents/Obsidian 0755 ${hostVariables.username}"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages =
    (with pkgs; [
      unstable.bruno
      keepassxc
      vscode-with-extensions
      gh
      zip
      unzip
      burpsuite
      libreoffice-qt
      chromium
      element-desktop
      busybox
      pnpm
      nodejs_24
      gitg
      (unstable.brave.override {
        commandLineArgs = [
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
        ];
      })
    ])
    ++ [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.copilot-cli
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
