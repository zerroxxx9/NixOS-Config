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
  boot.kernelModules = [ "kvm-intel" ];
  networking = {
    hostName = hostVariables.host;
    useHostResolvConf = lib.mkForce false;
  };
  services.resolved.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
    };
  };
  users.users.${hostVariables.username} = {
    isNormalUser = true;
    description = hostVariables.username;
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDER0VVHXqwWICf8HfG2+vV4VCAspv71m9M8y7bWpLTZ zerrox@desktop"
    ];
  };
  programs.direnv.enable = true;
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    unzip
    zip
    busybox
    wakeonlan
    claude-code
  ];

  systemd.services.daily-reboot = {
    description = "Reboot the homelab host";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
    };
  };

  systemd.timers.daily-reboot = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "00:00";
      AccuracySec = "1s";
      Persistent = false;
    };
  };

  systemd.services.wake-nas = {
    description = "Wake the NAS via WOL";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.wakeonlan}/bin/wakeonlan 00:e0:4c:61:97:a1";
    };
  };
  
  systemd.timers.wake-nas = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "08:00";
      AccuracySec = "1s";
      Persistent = false;
    };
  };

  modules.system.nas = {
    server = "192.168.178.121";
    shares = {
      immich = {
        remotePath = "/mnt/storage/immich";
        mountPoint = "/mnt/nas/immich";
      };
      paperless = {
        remotePath = "/mnt/storage/paperless";
        mountPoint = "/mnt/nas/paperless";
      };
      opencloud = {
        remotePath = "/mnt/storage/opencloud";
        mountPoint = "/mnt/nas/opencloud";
      };
      media = {
        remotePath = "/mnt/storage/media";
        mountPoint = "/mnt/nas/media";
        automount = true;
      };
    };
  };

  modules.software.immich.mediaLocation = "/mnt/nas/immich";

  modules.software.opencloud.stateDir = "/mnt/nas/opencloud";

  modules.software.paperless-ngx = {
    mediaDir = "/mnt/nas/paperless/media";
    consumptionDir = "/mnt/nas/paperless/consume";
    consumerPolling = 60;
  };

  modules.security.agenix.secrets.tailscaleAuthKey = true;
  modules.security.agenix.secrets.chessstackEnv = true;

  modules.software.tailscale =
    {
      hostname = "homelab-1.tail11bba0.ts.net";
      exitNode = true;
      subnetRoutes = ["192.168.1.0/24"];
      useSSH = true;
    }
    // lib.optionalAttrs (builtins.hasAttr "tailscale-authkey" config.age.secrets) {
      authKeyFile = config.age.secrets."tailscale-authkey".path;
    };

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
