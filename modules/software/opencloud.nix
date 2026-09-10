{
  lib,
  config,
  ...
}: let
  opencloudPort = 9200;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.opencloud = {
    enable = lib.mkEnableOption "opencloud";
  };

  config = lib.mkIf config.modules.software.opencloud.enable {
    services.opencloud = {
      enable = true;
      address = "127.0.0.1";
      port = opencloudPort;
      url = tsCfg.serve.opencloud.url;
    };

    modules.software.tailscale.serve.opencloud = {
      port = 443;
      target = "https+insecure://127.0.0.1:${toString opencloudPort}";
      after = ["opencloud.service"];
    };
  };
}
