{
  hostVariables,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = hostVariables.host;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  console.keyMap = "de";

  # Enable sound with pipewire.
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
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = "zerrox";
    extraGroups = ["networkmanager" "wheel"];
  };

  programs.direnv.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    biome
  ];

  programs.firefox = {
    enable = true;
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
    github-copilot-cli
    element-desktop
    codex
    tailscale
  ];

  system.stateVersion = hostVariables.stateVersion;

  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];
}
