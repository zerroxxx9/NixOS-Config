{ lib, config, ... }:
{
  options.modules.software.paperless-ngx = {
    enable = lib.mkEnableOption "paperless-ngx";
  };

  config = lib.mkIf config.modules.software.paperless-ngx.enable {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = 1337;
    };

    systemd.services.tailscale-serve-paperless-ngx = {
      description = "Publish Paperless via Tailscale Serve";
      after = [ "network-online.target" "tailscaled.service" "paperless-web.service" ];
      wants = [ "network-online.target" "tailscaled.service" "paperless-web.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes https+insecure://127.0.0.1:1337";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 off";
      };
    };
  };
}
