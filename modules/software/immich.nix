{
  lib,
  config,
  ...
}: let
  immichPort = 2283;
  cfg = config.modules.software.immich;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.immich = {
    enable = lib.mkEnableOption "immich";

    mediaLocation = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/immich";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 995;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 995;
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich = {
      enable = true;
      host = "127.0.0.1";
      port = immichPort;
      mediaLocation = cfg.mediaLocation;

      settings = {
        newVersionCheck.enabled = false;
        server.externalDomain = tsCfg.serve.immich.url;
      };
    };

    users.users.immich.uid = cfg.uid;
    users.groups.immich.gid = cfg.gid;

    systemd.services.immich-server.unitConfig.RequiresMountsFor = [cfg.mediaLocation];
    systemd.services.immich-machine-learning.unitConfig.RequiresMountsFor = [cfg.mediaLocation];

    modules.software.tailscale.serve.immich = {
      port = immichPort;
      target = "http://127.0.0.1:${toString immichPort}";
      after = ["immich-server.service"];
    };
  };
}
