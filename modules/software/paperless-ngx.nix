{
  lib,
  config,
  ...
}: let
  paperlessPort = 1337;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.paperless-ngx = {
    enable = lib.mkEnableOption "paperless-ngx";
  };

  config = lib.mkIf config.modules.software.paperless-ngx.enable {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = paperlessPort;
      domain = "${tsCfg.hostname}:${toString paperlessPort}";
    };

    modules.software.tailscale.serve.paperless = {
      port = paperlessPort;
      target = "http://127.0.0.1:${toString paperlessPort}";
      after = ["paperless-web.service"];
    };
  };
}
