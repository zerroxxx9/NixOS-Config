{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.homelab.chessstack;
  envFile =
    if builtins.hasAttr "chessstack-env" config.age.secrets
    then config.age.secrets."chessstack-env".path
    else "/var/lib/secrets/chessstack.env";
  origin =
    if cfg.origin != null
    then cfg.origin
    else "https://${cfg.host}:${toString cfg.port}";
in {
  options.services.homelab.chessstack = {
    enable = lib.mkEnableOption "Chessstack";

    host = lib.mkOption {
      type = lib.types.str;
      default = "homelab-1.tail11bba0.ts.net";
      description = "Tailscale hostname used to reach Chessstack.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Tailscale Serve port for Chessstack.";
    };

    origin = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "External ORIGIN URL for Chessstack. Defaults to the Tailscale HTTPS URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      settings.listen_addresses = lib.mkDefault "127.0.0.1";
      ensureDatabases = ["chessstack"];
      ensureUsers = [
        {
          name = "chessstack";
          ensureDBOwnership = true;
        }
      ];
      authentication = lib.mkAfter ''
        host chessstack chessstack 127.0.0.1/32 trust
        host chessstack chessstack ::1/128 trust
      '';
    };

    virtualisation = {
      podman = {
        enable = true;
        extraPackages = [pkgs.slirp4netns];
      };
      oci-containers = {
        backend = "podman";
        containers.chessstack = {
          image = "ghcr.io/pvttwinkle/chessstack:latest";
          autoStart = true;
          ports = ["127.0.0.1:${toString cfg.port}:3000"];
          environment = {
            ORIGIN = origin;
            REGISTRATION_MODE = "invite-only";
          };
          environmentFiles = [envFile];
          extraOptions = [
            "--network=slirp4netns:allow_host_loopback=true"
            "--add-host=host.containers.internal:10.0.2.2"
          ];
        };
      };
    };

    systemd.tmpfiles.rules = lib.mkIf (!(builtins.hasAttr "chessstack-env" config.age.secrets)) [
      "d /var/lib/secrets 0700 root root - -"
    ];

    systemd.services.podman-chessstack = {
      after = ["postgresql.service"];
      wants = ["postgresql.service"];
      unitConfig.ConditionPathExists = envFile;
    };

    systemd.services.tailscale-serve-chessstack = lib.mkIf config.modules.software.tailscale.enable {
      description = "Publish Chessstack via Tailscale Serve";
      after = ["network-online.target" "tailscaled.service" "podman-chessstack.service"];
      wants = ["network-online.target" "tailscaled.service" "podman-chessstack.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=${toString cfg.port} http://127.0.0.1:${toString cfg.port}";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=${toString cfg.port} off";
      };
    };
  };
}
