{
  lib,
  config,
  ...
}: let
  pocketIdPort = 1411;
  cfg = config.modules.software.pocket-id;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.pocket-id = {
    enable = lib.mkEnableOption "Pocket ID (OIDC provider)";

    encryptionKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/secrets/pocket-id-encryption-key";
      description = ''
        Root-readable file with Pocket ID's ENCRYPTION_KEY, created manually on the host:
          sudo install -d -m 0700 /var/lib/secrets
          sudo sh -c 'umask 077; openssl rand -base64 32 > /var/lib/secrets/pocket-id-encryption-key'
        Losing it makes the stored data unreadable, so back it up.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = tsCfg.serve.pocket-id.url;
        HOST = "127.0.0.1";
        PORT = toString pocketIdPort;
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
      };
      credentials.ENCRYPTION_KEY = cfg.encryptionKeyFile;
    };

    systemd.services.pocket-id.unitConfig.ConditionPathExists = cfg.encryptionKeyFile;

    modules.software.tailscale.serve.pocket-id = {
      port = pocketIdPort;
      target = "http://127.0.0.1:${toString pocketIdPort}";
      after = ["pocket-id.service"];
    };
  };
}
