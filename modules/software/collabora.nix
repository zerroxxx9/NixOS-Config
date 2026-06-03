{
  lib,
  config,
  ...
}: let
  port = 9980;
  hostname = "homelab.tail11bba0.ts.net";
  opencloudUrl = "https://${hostname}";
in {
  options.modules.software.collabora = {
    enable = lib.mkEnableOption "Collabora Online";
  };

  config = lib.mkIf config.modules.software.collabora.enable {
    services.collabora-online = {
      enable = true;
      inherit port;
      aliasGroups = [
        {
          host = opencloudUrl;
        }
      ];

      settings = {
        server_name = "${hostname}:${toString port}";

        ssl = {
          enable = false;
          termination = true;
        };

        net = {
          proto = "IPv4";
          listen = "loopback";
          post_allow.host = [
            "127\\.0\\.0\\.1"
          ];
        };

        storage.wopi = {
          "@allow" = true;
          alias_groups."@mode" = "groups";
        };
      };
    };

    systemd.services.tailscale-serve-collabora = lib.mkIf config.modules.software.tailscale.enable {
      description = "Publish Collabora Online via Tailscale Serve";
      after = ["network-online.target" "tailscaled.service" "coolwsd.service"];
      wants = ["network-online.target" "tailscaled.service" "coolwsd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=${toString port} http://127.0.0.1:${toString port}";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=${toString port} off";
      };
    };
  };
}
