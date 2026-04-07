{ hostVariables, pkgs, lib, ... }:

{
  imports = [
    ../software/tailscale.nix
    ./hardware-configuration.nix
    ];

   homelab = {
     enable = true;
     defaultUser = hostVariables.username;
     startMenuLaunchers = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = hostVariables.host;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = hostVariables.username;
    extraGroups = ["networkmanager" "wheel"];
  };

  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    unzip
    zip
    #lab specific
    opencloud
    tailscale
  ];

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = lib.mkForce "de_DE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT    = "de_DE.UTF-8";
    LC_MONETARY       = "de_DE.UTF-8";
    LC_NAME           = "de_DE.UTF-8";
    LC_NUMERIC        = "de_DE.UTF-8";
    LC_PAPER          = "de_DE.UTF-8";
    LC_TELEPHONE      = "de_DE.UTF-8";
    LC_TIME           = "de_DE.UTF-8";
  };

  tailscale = {
    enable = true;
    exitNode = true;
    subnetRoutes = [ "192.168.1.0/24" ];
    authKeyFile = config.age.secrets.tailscale.path;
    useSSH = true;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = hostVariables.stateVersion;
}
