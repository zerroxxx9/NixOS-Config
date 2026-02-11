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

  networking.hostName = hostVariables.host; # Define your hostname.

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

  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = "zerrox";
    extraGroups = ["networkmanager" "wheel"];
  };

  programs.direnv.enable = true;

  programs.firefox = {
    enable = true;
  };

  systemd.tmpfiles.rules = [
    "d /home/${hostVariables.username}/Dev 0755 ${hostVariables.username}"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    unstable.brave
    unstable.bruno
    jetbrains.idea
    keepassxc
    vscode-with-extensions
    obsidian
    gh
    zip
    unzip
    burpsuite
  ];

  system.stateVersion = hostVariables.stateVersion;

  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];
}
