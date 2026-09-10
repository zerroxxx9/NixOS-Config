{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.software.tailscale;

  serveEntries = lib.attrValues cfg.serve;

  sortedEntries = lib.sort (a: b: a.port < b.port) serveEntries;

  serveArgs = entry:
    lib.escapeShellArgs (
      ["serve" "--bg" "--yes" "--https=${toString entry.port}"]
      ++ lib.optionals (entry.path != null) ["--set-path=${entry.path}"]
      ++ [entry.target]
    );

  serveOrderUnits = lib.unique (lib.concatMap (entry: entry.after) serveEntries);
in {
  options.modules.software.tailscale = {
    enable = lib.mkEnableOption "tailscale";

    acceptDNS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to let Tailscale manage system DNS (equivalent to tailscale up --accept-dns=...).";
    };

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

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "${config.networking.hostName}.${cfg.tailnet}";
      defaultText = "\${networking.hostName}.\${modules.software.tailscale.tailnet}";
      description = "MagicDNS name of this host. Used to build the public URL of every served service.";
    };

    tailnet = lib.mkOption {
      type = lib.types.str;
      default = "tail11bba0.ts.net";
      description = "MagicDNS suffix of the tailnet this host belongs to.";
    };

    serve = lib.mkOption {
      default = {};
      description = ''
        Declarative `tailscale serve` mappings, keyed by service name.

        Every mapping is applied by the single `tailscale-serve` unit, which first
        resets the serve config and then re-applies all mappings in a fixed order.
        Per-service units must not call `tailscale serve` themselves: the CLI does a
        read-modify-write of one shared config, so concurrent invocations race and
        silently drop each other's entries.
      '';
      type = lib.types.attrsOf (lib.types.submodule (sub: {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "HTTPS port to publish this service on.";
          };

          target = lib.mkOption {
            type = lib.types.str;
            description = "Local backend to proxy to, e.g. http://127.0.0.1:2283.";
          };

          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional sub-path to publish the service under.";
          };

          after = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = ''
              Units this mapping's backend belongs to. Used for ordering only, never as a
              dependency: a dead backend must not stop the rest of the serve config from
              being applied.
            '';
          };

          url = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            description = "Public URL this service is reachable at. Derived from hostname, port and path.";
          };
        };

        config.url =
          "https://${cfg.hostname}"
          + lib.optionalString (sub.config.port != 443) ":${toString sub.config.port}"
          + lib.optionalString (sub.config.path != null) sub.config.path;
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.tailscale];

    services.tailscale =
      {
        enable = true;
        openFirewall = true;
        extraUpFlags =
          [
            "--accept-dns=${
              if cfg.acceptDNS
              then "true"
              else "false"
            }"
          ]
          ++ lib.optionals cfg.exitNode ["--advertise-exit-node"]
          ++ lib.optionals (cfg.subnetRoutes != []) [
            "--advertise-routes=${lib.concatStringsSep "," cfg.subnetRoutes}"
          ]
          ++ lib.optionals cfg.useSSH ["--ssh"];
      }
      // lib.optionalAttrs (cfg.authKeyFile != null) {
        authKeyFile = cfg.authKeyFile;
      };

    networking.firewall.trustedInterfaces = ["tailscale0"];

    systemd.services.tailscale-serve = lib.mkIf (cfg.serve != {}) {
      description = "Apply the declarative Tailscale Serve configuration";
      after = ["network-online.target" "tailscaled.service" "tailscaled-autoconnect.service"] ++ serveOrderUnits;
      wants = ["network-online.target" "tailscaled.service"];
      wantedBy = ["multi-user.target"];
      path = [config.services.tailscale.package];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve reset";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      script = ''
        set -euo pipefail

        for _ in $(seq 1 60); do
          if [ "$(tailscale status --json | ${pkgs.jq}/bin/jq -r .BackendState)" = "Running" ]; then
            break
          fi
          sleep 2
        done

        tailscale serve reset

        ${lib.concatMapStringsSep "\n" (entry: "tailscale ${serveArgs entry}") sortedEntries}

        tailscale serve status
      '';
    };

    boot.kernel.sysctl = lib.mkIf (cfg.exitNode || cfg.subnetRoutes != []) {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
