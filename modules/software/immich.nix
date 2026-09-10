{
  lib,
  config,
  ...
}: let
  immichPort = 2283;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.immich = {
    enable = lib.mkEnableOption "immich";
  };

  config = lib.mkIf config.modules.software.immich.enable {
    services.immich = {
      enable = true;
      host = "127.0.0.1";
      port = immichPort;

      settings = {
        newVersionCheck.enabled = false;
        server.externalDomain = tsCfg.serve.immich.url;
      };
    };

    modules.software.tailscale.serve.immich = {
      port = immichPort;
      target = "http://127.0.0.1:${toString immichPort}";
      after = ["immich-server.service"];
    };
  };
}
