{ hostVariables, pkgs, lib, ... }:

{
  imports = [];

  wsl = {
    enable = true;
    defaultUser = hostVariables.username;
    startMenuLaunchers = true;
  };

  wsl.wslConf.network.generateResolvConf = false;

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  networking = {
    hostName = hostVariables.host;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = hostVariables.username;
    extraGroups = [ "wheel" ];
  };

  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    unzip
    zip
  ];

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = lib.mkForce "de_DE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = hostVariables.stateVersion;
}
