{ lib, config, ... }:
{
  options.modules.software.opencloud = {
    enable = lib.mkEnableOption "opencloud";
  };

  config = lib.mkIf config.modules.software.opencloud.enable {
    services.opencloud = {
      enable = true;
      address = "127.0.0.1";
      port = 9200;
      url = "https://homelab.tail11bba0.ts.net/";
    };

    systemd.services.tailscale-serve-opencloud = {
      description = "Publish OpenCloud via Tailscale Serve";
      after = [ "network-online.target" "tailscaled.service" "opencloud.service" ];
      wants = [ "network-online.target" "tailscaled.service" "opencloud.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes https+insecure://127.0.0.1:9200";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 off";
      };
    };
  };
}
