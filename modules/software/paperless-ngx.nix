{
  lib,
  config,
  ...
}: let
  paperlessPort = 1337;
  cfg = config.modules.software.paperless-ngx;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.paperless-ngx = {
    enable = lib.mkEnableOption "paperless-ngx";

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/paperless/media";
    };

    consumptionDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/paperless/consume";
    };

    consumerPolling = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = paperlessPort;
      domain = "${tsCfg.hostname}:${toString paperlessPort}";
      mediaDir = cfg.mediaDir;
      consumptionDir = cfg.consumptionDir;

      settings = lib.mkIf (cfg.consumerPolling != null) {
        PAPERLESS_CONSUMER_POLLING = cfg.consumerPolling;
      };
    };

    systemd.services =
      lib.genAttrs
      [
        "paperless-consumer"
        "paperless-scheduler"
        "paperless-task-queue"
        "paperless-web"
      ]
      (_: {
        unitConfig.RequiresMountsFor = [cfg.mediaDir cfg.consumptionDir];
      });

    modules.software.tailscale.serve.paperless = {
      port = paperlessPort;
      target = "http://127.0.0.1:${toString paperlessPort}";
      after = ["paperless-web.service"];
    };
  };
}
