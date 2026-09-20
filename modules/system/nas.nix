{
  config,
  lib,
  ...
}: let
  cfg = config.modules.system.nas;

  baseOptions = [
    "nfsvers=4.2"
    "rw"
    "hard"
    "noatime"
    "nodiratime"
    "_netdev"
    "x-systemd.mount-timeout=90"
  ];

  mkFileSystem = share: {
    device = "${cfg.server}:${share.remotePath}";
    fsType = "nfs4";
    options =
      baseOptions
      ++ lib.optionals share.automount [
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
      ]
      ++ share.extraOptions;
  };
in {
  options.modules.system.nas = {
    enable = lib.mkEnableOption "NFS shares from the NAS";

    server = lib.mkOption {
      type = lib.types.str;
    };

    shares = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          remotePath = lib.mkOption {
            type = lib.types.str;
          };

          mountPoint = lib.mkOption {
            type = lib.types.str;
            default = "/mnt/nas/${name}";
          };

          automount = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };

          extraOptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems =
      lib.mapAttrs'
      (_: share: lib.nameValuePair share.mountPoint (mkFileSystem share))
      cfg.shares;
  };
}
