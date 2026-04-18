{ config, lib, ... }:
{
  services.opencloud = {
    enable = true;
    address = "127.0.0.1";
    port = 9200;
    url = "https://homelab.zerrox.ts.net";
  };

  systemd.services.tailscale-serve-opencloud = {
    description = "Publish OpenCloud via Tailscale Serve";
    after = [ "tailscaled.service" "opencloud.service" ];
    wants = [ "tailscaled.service" "opencloud.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg 9200";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 off";
    };
  };
}
