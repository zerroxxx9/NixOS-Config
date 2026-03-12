{ config, pkgs, lib, variables, ... }:

{
  imports = [];

  wsl = {
    enable = true;
    defaultUser = variables.username;
    startMenuLaunchers = true;

    interop.enable = true;
  };

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  networking = {
    hostName = variables.host;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    unzip
    zip
  ];

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
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

  system.stateVersion = variables.stateVersion;
}
