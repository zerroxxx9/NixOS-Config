{
  lib,
  config,
  ...
}: let
  opencloudPort = 9200;
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
      default = 994;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 994;
    };
  };

  config = lib.mkIf cfg.enable {
    services.opencloud = {
      enable = true;
      address = "127.0.0.1";
      port = opencloudPort;
      url = tsCfg.serve.opencloud.url;
      stateDir = cfg.stateDir;
    };

    users.users.opencloud.uid = cfg.uid;
    users.groups.opencloud.gid = cfg.gid;

    systemd.services.opencloud.unitConfig.RequiresMountsFor = [cfg.stateDir];

    modules.software.tailscale.serve.opencloud = {
      port = 443;
      target = "https+insecure://127.0.0.1:${toString opencloudPort}";
      after = ["opencloud.service"];
    };
  };
}
