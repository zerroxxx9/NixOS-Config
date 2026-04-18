{ pkgs, lib, config, ... }:
{
  options.modules.software.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkIf config.modules.software.tailscale.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale = {
      enable = true;
      openFirewall = true;
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}