{ lib, config, ... }:
{
  options.modules.software.immich = {
    enable = lib.mkEnableOption "immich";
  };

  config = lib.mkIf config.modules.software.immich.enable {
    services.immich = {
      enable = true;
      host = "127.0.0.1";
      port = 2283;

      settings = {
        newVersionCheck.enabled = false;
        server.externalDomain = "https://homelab.tail11bba0.ts.net:2283";
      };
    };

    systemd.services.tailscale-serve-immich = {
      description = "Publish Immich via Tailscale Serve";
      after = [ "network-online.target" "tailscaled.service" "immich-server.service" ];
      wants = [ "network-online.target" "tailscaled.service" "immich-server.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=2283 https+insecure://127.0.0.1:2283";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=2283 off";
      };
    };
  };
}
