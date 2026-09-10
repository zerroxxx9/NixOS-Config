{
  lib,
  config,
  ...
}: let
  mealiePort = 9000;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.mealie = {
    enable = lib.mkEnableOption "mealie";
  };

  config = lib.mkIf config.modules.software.mealie.enable {
    services.mealie = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = mealiePort;

      settings = {
        BASE_URL = tsCfg.serve.mealie.url;
        CHECK_FOR_UPDATES = "false";
      };
    };

    modules.software.tailscale.serve.mealie = {
      port = mealiePort;
      target = "http://127.0.0.1:${toString mealiePort}";
      after = ["mealie.service"];
    };
  };
}
