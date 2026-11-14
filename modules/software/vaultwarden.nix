{ lib, config, ... }: let
  port = 8222;
  domain = "vault.lab.zerrox-sec.com";
  cfg = config.modules.software.vaultwarden;
in {
  options.modules.software.vaultwarden = {
    enable = lib.mkEnableOption "vaultwarden";

    signupsAllowed = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/storage/backup/vaultwarden";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/secrets/vaultwarden.env";
    };
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      backupDir = cfg.backupDir;
      environmentFile = cfg.environmentFile;
      config = {
        DOMAIN = "https://${domain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = port;
        SIGNUPS_ALLOWED = cfg.signupsAllowed;
        INVITATIONS_ALLOWED = false;
        SHOW_PASSWORD_HINT = false;
      };
    };

    systemd.services.vaultwarden.unitConfig.ConditionPathExists = cfg.environmentFile;
    systemd.services.backup-vaultwarden.unitConfig.RequiresMountsFor = [cfg.backupDir];

    services.caddy.virtualHosts.${domain} = {
      useACMEHost = "lab.zerrox-sec.com";
      extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
    };
  };
}