{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.software.protonmail-bridge;
in {
  options.modules.software.protonmail-bridge = {
    enable = lib.mkEnableOption "headless Proton Mail Bridge (IMAP on localhost for Paperless)";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/protonmail-bridge";
      description = "Home of the bridge user: holds the Bridge session, GPG key and pass store.";
    };

    certFile = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "/run/protonmail-bridge/cert.pem";
      description = "World-readable copy of the Bridge's self-signed TLS certificate (public part only).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.protonmail-bridge = {
      isSystemUser = true;
      group = "protonmail-bridge";
      home = cfg.dataDir;
      createHome = true;
      # Needed so `sudo -u protonmail-bridge -s` works for the one-time login.
      shell = pkgs.bashInteractive;
    };
    users.groups.protonmail-bridge = {};

    # Only the pass/gpg keyring + CLI for the one-time setup; no secret in Nix.
    environment.systemPackages = [pkgs.protonmail-bridge pkgs.pass pkgs.gnupg];

    systemd.services.protonmail-bridge = {
      description = "Proton Mail Bridge (headless)";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [pkgs.pass pkgs.gnupg];
      environment.HOME = cfg.dataDir;
      # Skip start until the one-time setup created the pass store.
      unitConfig.ConditionPathExists = "${cfg.dataDir}/.password-store";
      serviceConfig = {
        User = "protonmail-bridge";
        Group = "protonmail-bridge";
        ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
        # Publish the (public) TLS cert so Paperless can trust it; the data dir itself stays private.
        RuntimeDirectory = "protonmail-bridge";
        RuntimeDirectoryMode = "0755";
        ExecStartPost = "-+${pkgs.writeShellScript "protonmail-bridge-publish-cert" ''
          # Bridge 3.x keeps its TLS cert in the vault, not on disk: grab the one
          # it presents on the IMAP port (self-signed, so trusting it pins it).
          for _ in $(seq 60); do
            if timeout 10 ${pkgs.openssl}/bin/openssl s_client -connect 127.0.0.1:1143 -starttls imap -showcerts </dev/null 2>/dev/null \
              | ${pkgs.openssl}/bin/openssl x509 -out ${cfg.certFile}.tmp 2>/dev/null; then
              chmod 0644 ${cfg.certFile}.tmp
              mv ${cfg.certFile}.tmp ${cfg.certFile}
              exit 0
            fi
            sleep 1
          done
          echo "could not fetch bridge cert from 127.0.0.1:1143" >&2
          exit 1
        ''}";
        Restart = "on-failure";
        RestartSec = 10;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.dataDir];
        PrivateTmp = true;
      };
    };
  };
}
