{
  lib,
  config,
  ...
}: let
  opencloudPort = 9200;
  opencloudUser = "opencloud-daemon";
  cfg = config.modules.software.opencloud;
  tsCfg = config.modules.software.tailscale;
in {
  options.modules.software.opencloud = {
    enable = lib.mkEnableOption "opencloud";

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/opencloud";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 987;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 982;
    };

    oidc = {
      enable = lib.mkEnableOption ''
        Pocket ID as OpenCloud's identity provider (replaces the built-in IdP).
        Web login only: the desktop and mobile apps use fixed client IDs that
        Pocket ID has to be configured for separately.
      '';

      issuerUrl = lib.mkOption {
        type = lib.types.str;
        default = tsCfg.serve.pocket-id.url;
        description = "OIDC issuer URL (Pocket ID's APP_URL).";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        description = "Client ID of the OpenCloud web client created in Pocket ID (public client, PKCE).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.opencloud = {
      enable = true;
      user = opencloudUser;
      group = opencloudUser;
      address = "127.0.0.1";
      port = opencloudPort;
      url = tsCfg.serve.opencloud.url;
      stateDir = cfg.stateDir;
      environment = lib.mkIf cfg.oidc.enable {
        OC_OIDC_ISSUER = cfg.oidc.issuerUrl;
        WEB_OIDC_CLIENT_ID = cfg.oidc.clientId;
        WEB_OIDC_SCOPE = "openid profile email";
        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
        PROXY_USER_OIDC_CLAIM = "preferred_username";
        PROXY_USER_CS3_CLAIM = "username";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        OC_EXCLUDE_RUN_SERVICES = "idp";
      };
    };

    users.users.${opencloudUser} = {
      uid = cfg.uid;
      group = opencloudUser;
      isSystemUser = true;
      home = cfg.stateDir;
    };
    users.groups.${opencloudUser}.gid = cfg.gid;

    systemd.services.opencloud.unitConfig.RequiresMountsFor = [cfg.stateDir];
    systemd.services.opencloud.serviceConfig.EnvironmentFile = "-${cfg.stateDir}/admin.env";

    modules.software.tailscale.serve.opencloud = {
      port = 443;
      target = "https+insecure://127.0.0.1:${toString opencloudPort}";
      after = ["opencloud.service"];
    };
  };
}
