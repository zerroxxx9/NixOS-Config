{
  pkgs,
  lib,
  config,
  ...
}: {
  options.modules.software.tailscale.enable =
    lib.mkEnableOption "tailscale";

  config = lib.mkIf config.modules.software.tailscale.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale = {
      enable = true;
      openFirewall = true;

      serve = {
        enable = true;
        services = {
          opencloud = {
            endpoints = {
              "tcp:443" = "http://127.0.0.1:9200";
            };
          };
        };
      };
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
