{ lib, config, ... }: let
  cfg = config.modules.software.backup;
  box = "u718745@u718745.your-storagebox.de";
in {
  options.modules.software.backup.enable = lib.mkEnableOption "restic backups";

  config = lib.mkIf cfg.enable {
    services.postgresqlBackup = {
      enable = true;
      databases = ["immich"];
      location = "/var/backup/postgresql";
      startAt = "*-*-* 02:30:00";
    };

    systemd.tmpfiles.rules = ["d /var/backup/paperless 0750 paperless paperless -"];

    programs.ssh.knownHosts.storagebox = {
      hostNames = ["[u718745.your-storagebox.de]:23"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };

    services.restic.backups.storagebox = {
      initialize = true;
      repository = "sftp:${box}:restic/zimablade";
      passwordFile = "/var/lib/secrets/restic-password";
      extraOptions = [
        "sftp.command='ssh ${box} -p 23 -i /root/.ssh/storagebox -s sftp'"
      ];
      backupPrepareCommand = ''
        ${config.services.paperless.manage}/bin/paperless-manage \
          document_exporter /var/backup/paperless --no-progress-bar
      '';
      paths = [
        "/var/backup"
        "/mnt/storage/immich"
        "/mnt/storage/opencloud"
        "/var/lib/pocket-id"
        "/var/lib/secrets"
      ];
      exclude = [
        "/mnt/storage/immich/thumbs"
        "/mnt/storage/immich/encoded-video"
      ];
      timerConfig = {
        OnCalendar = "03:00";
        RandomizedDelaySec = "15m";
        Persistent = true;
      };
      pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6"];
      checkOpts = ["--read-data-subset=5%"];
    };

    systemd.services.restic-backups-storagebox.onFailure = ["notify-failure@%n.service"];
  };
}