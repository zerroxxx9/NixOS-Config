{
  pkgs,
  lib,
  inputs,
  config,
  hostVariables,
  system,
  ...
}: {
  options.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Tailscale.";
    };

    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to advertise this host as an exit node.";
    };

    subnetRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of subnet routes to advertise (e.g. [ \"192.168.1.0/24\" ]).";
    };

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing the Tailscale auth key (e.g. from agenix or sops-nix).";
    };

    useSSH = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Tailscale SSH.";
    };
  };

  config = lib.mkIf config.tailscale.enable {
    services.tailscale =
      {
        enable = true;

        extraUpFlags =
          lib.optionals config.tailscale.exitNode [ "--advertise-exit-node" ]
          ++ lib.optionals (config.tailscale.subnetRoutes != []) [
            "--advertise-routes=${lib.concatStringsSep "," config.tailscale.subnetRoutes}"
          ]
          ++ lib.optionals config.tailscale.useSSH [ "--ssh" ];
      }
      // lib.optionalAttrs (config.tailscale.authKeyFile != null) {
        authKeyFile = config.tailscale.authKeyFile;
      };

    networking.firewall =
      {
        allowedUDPPorts = [ config.services.tailscale.port ];
        trustedInterfaces = [ "tailscale0" ];
      }
      // lib.optionalAttrs (config.tailscale.exitNode || config.tailscale.subnetRoutes != []) {
        checkReversePath = "loose";
      };

    boot.kernel.sysctl = lib.mkIf (config.tailscale.exitNode || config.tailscale.subnetRoutes != []) {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
