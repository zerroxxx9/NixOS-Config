{
  lib,
  config,
  ...
}: let
  opencloudPort = 9200;
  opencloudUser = "opencloud-daemon";
  cfg = config.modules.software.opencloud;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.opencloud = {
    enable = lib.mkEnableOption "opencloud";

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/opencloud";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 987;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 982;
    };

  };

  config = lib.mkIf cfg.enable {
    services.opencloud = {
      enable = true;
      user = opencloudUser;
      group = opencloudUser;
      address = "127.0.0.1";
      port = opencloudPort;
      url = tsCfg.serve.opencloud.url;
      stateDir = cfg.stateDir;
    };

    users.users.${opencloudUser} = {
      uid = cfg.uid;
      group = opencloudUser;
      isSystemUser = true;
      home = cfg.stateDir;
    };
    users.groups.${opencloudUser}.gid = cfg.gid;

    systemd.services.opencloud.unitConfig.RequiresMountsFor = [cfg.stateDir];
    systemd.services.opencloud.serviceConfig.EnvironmentFile = "-${cfg.stateDir}/admin.env";

    modules.software.tailscale.serve.opencloud = {
      port = 443;
      target = "https+insecure://127.0.0.1:${toString opencloudPort}";
      after = ["opencloud.service"];
    };
  };
}
