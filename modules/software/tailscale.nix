{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.software.tailscale;
in {
  options.modules.software.tailscale = {
    enable = lib.mkEnableOption "tailscale";

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to a Tailscale auth key file, for example from agenix.";
    };

    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host should advertise itself as a Tailscale exit node.";
    };

    subnetRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Subnet routes to advertise through Tailscale.";
    };

    useSSH = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Tailscale SSH.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.tailscale];

    services.tailscale =
      {
        enable = true;
        openFirewall = true;
        extraUpFlags =
          lib.optionals cfg.exitNode ["--advertise-exit-node"]
          ++ lib.optionals (cfg.subnetRoutes != []) [
            "--advertise-routes=${lib.concatStringsSep "," cfg.subnetRoutes}"
          ]
          ++ lib.optionals cfg.useSSH ["--ssh"];
      }
      // lib.optionalAttrs (cfg.authKeyFile != null) {
        authKeyFile = cfg.authKeyFile;
      };

    networking.firewall.trustedInterfaces = ["tailscale0"];

    boot.kernel.sysctl = lib.mkIf (cfg.exitNode || cfg.subnetRoutes != []) {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
