{ lib, config, pkgs, ... }:
let
  dataDir = "/var/lib/couchdb";
  backupDir = "/var/backups/couchdb";
in
{
  options.modules.software.couchdb = {
    enable = lib.mkEnableOption "CouchDB for Obsidian LiveSync";
  };

  config = lib.mkIf config.modules.software.couchdb.enable {
    services.couchdb = {
      enable = true;
      bindAddress = "127.0.0.1";
      port = 5984;
      databaseDir = dataDir;
      viewIndexDir = dataDir;
      configFile = "${dataDir}/local.ini";
      extraConfig = {
        couchdb = {
          single_node = "true";
          max_document_size = "50000000";
        };
        chttpd = {
          require_valid_user = "true";
          max_http_request_size = "4294967296";
        };
        chttpd_auth.require_valid_user = "true";
        httpd = {
          "WWW-Authenticate" = ''Basic realm="couchdb"'';
          enable_cors = "true";
        };
        cors = {
          origins = "app://obsidian.md,capacitor://localhost,http://localhost";
          credentials = "true";
          headers = "accept, authorization, content-type, origin, referer";
          methods = "GET, PUT, POST, HEAD, DELETE";
          max_age = "3600";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${backupDir} 0750 root root - -"
    ];

    systemd.services.tailscale-serve-couchdb = lib.mkIf config.modules.software.tailscale.enable {
      description = "Publish CouchDB for Obsidian LiveSync via Tailscale Serve";
      after = [ "network-online.target" "tailscaled.service" "couchdb.service" ];
      wants = [ "network-online.target" "tailscaled.service" "couchdb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=5984 http://127.0.0.1:5984";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=5984 off";
      };
    };

    systemd.services.couchdb-backup = {
      description = "Create a minimal CouchDB data backup";
      serviceConfig.Type = "oneshot";
      path = with pkgs; [ coreutils findutils gnutar gzip systemd ];
      script = ''
        set -euo pipefail

        mkdir -p ${backupDir}
        systemctl stop couchdb.service
        trap 'systemctl start couchdb.service' EXIT

        tar -C /var/lib -czf "${backupDir}/couchdb-$(date +%F).tar.gz" couchdb
        find ${backupDir} -type f -name 'couchdb-*.tar.gz' -mtime +14 -delete
      '';
    };

    systemd.timers.couchdb-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:15";
        Persistent = true;
      };
    };
  };
}
