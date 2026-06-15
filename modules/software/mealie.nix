{ lib, config, ... }:
let
  mealiePort = 9000;
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
        BASE_URL = "https://homelab.tail11bba0.ts.net:${toString mealiePort}";
        CHECK_FOR_UPDATES = "false";
      };
    };

    systemd.services.tailscale-serve-mealie = {
      description = "Publish Mealie via Tailscale Serve";
      after = [ "network-online.target" "tailscaled.service" "mealie.service" ];
      wants = [ "network-online.target" "tailscaled.service" "mealie.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=${toString mealiePort} http://127.0.0.1:${toString mealiePort}";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=${toString mealiePort} off";
      };
    };
  };
}
