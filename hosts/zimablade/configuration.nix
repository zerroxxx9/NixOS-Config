{
  config,
  hostVariables,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = hostVariables.host;
  };
  services.resolved.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = hostVariables.username;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDER0VVHXqwWICf8HfG2+vV4VCAspv71m9M8y7bWpLTZ zerrox@desktop"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDER0VVHXqwWICf8HfG2+vV4VCAspv71m9M8y7bWpLTZ zerrox@desktop"
  ];
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    smartmontools
  ];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/0e760e5e-e04d-4753-8d88-3c23df639eb5";
    fsType = "ext4";
    options = ["noatime" "nofail" "x-systemd.device-timeout=10"];
  };

  modules.software.immich = {
    mediaLocation = "/mnt/storage/immich";
    uid = 996;
    gid = 996;
  };

  modules.software.opencloud = {
    stateDir = "/mnt/storage/opencloud";
    uid = 994;
    gid = 994;
  };

  modules.software.paperless-ngx = {
    mediaDir = "/mnt/storage/paperless/media";
    consumptionDir = "/mnt/storage/paperless/consume";
    consumerPolling = 60;
  };

  modules.software.tailscale = {
    exitNode = true;
    subnetRoutes = ["192.168.178.0/24"];
    useSSH = true;
  };

  modules.software.smart-home.desktop = {
    mac = "30:56:0f:71:73:4d"; # enp9s0 on the desktop
    host = "192.168.178.108";
  };

  services.smartd.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = lib.mkForce "de_DE.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = hostVariables.stateVersion;
}
