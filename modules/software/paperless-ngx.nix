{
  lib,
  pkgs,
  config,
  ...
}: let
  paperlessPort = 1337;
  cfg = config.modules.software.paperless-ngx;
  tsCfg = config.modules.software.tailscale;
  oidcEnvFile = "/run/paperless-oidc.env";
in {
  options.modules.software.paperless-ngx = {
    enable = lib.mkEnableOption "paperless-ngx";

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/paperless/media";
    };

    consumptionDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/paperless/consume";
    };

    consumerPolling = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
    };

    emailCertificateFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "CA/self-signed certificate Paperless trusts for IMAP (e.g. Proton Mail Bridge).";
    };

    oidc = {
      enable = lib.mkEnableOption "OIDC login for Paperless-ngx";

      issuerUrl = lib.mkOption {
        type = lib.types.str;
        default = tsCfg.serve.pocket-id.url;
        description = "OIDC issuer URL (Pocket ID's APP_URL).";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        description = "Client ID of the Paperless client created in Pocket ID.";
      };

      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/secrets/paperless-oidc-client-secret";
        description = "Root-readable file with the client secret.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = paperlessPort;
      domain = lib.removePrefix "https://" tsCfg.serve.paperless.url;
      mediaDir = cfg.mediaDir;
      consumptionDir = cfg.consumptionDir;

      settings = lib.mkMerge [
        (lib.mkIf (cfg.consumerPolling != null) {
          PAPERLESS_CONSUMER_POLLING = cfg.consumerPolling;
        })
        (lib.mkIf (cfg.emailCertificateFile != null) {
          PAPERLESS_EMAIL_CERTIFICATE_LOCATION = cfg.emailCertificateFile;
        })
        (lib.mkIf cfg.oidc.enable {
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
        })
      ];

      environmentFile = lib.mkIf cfg.oidc.enable oidcEnvFile;
    };

    # PAPERLESS_SOCIALACCOUNT_PROVIDERS has to carry the client secret, so the
    # env file is generated at boot from the secret file and lives only in /run.
    systemd.services =
      lib.genAttrs
      [
        "paperless-consumer"
        "paperless-scheduler"
        "paperless-task-queue"
        "paperless-web"
      ]
      (_: {
        unitConfig.RequiresMountsFor = [cfg.mediaDir cfg.consumptionDir];
      })
      // lib.optionalAttrs cfg.oidc.enable {
        paperless-oidc-env = {
          description = "Generate the Paperless OIDC environment file";
          wantedBy = ["multi-user.target"];
          before = ["paperless-scheduler.service" "paperless-task-queue.service" "paperless-consumer.service" "paperless-web.service"];
          requiredBy = ["paperless-web.service"];
          unitConfig.ConditionPathExists = cfg.oidc.clientSecretFile;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            UMask = "0037";
          };
          script = ''
            providers=$(${pkgs.jq}/bin/jq -cn \
              --arg id ${lib.escapeShellArg cfg.oidc.clientId} \
              --arg secret "$(cat ${lib.escapeShellArg cfg.oidc.clientSecretFile})" \
              --arg url ${lib.escapeShellArg "${cfg.oidc.issuerUrl}/.well-known/openid-configuration"} \
              '{openid_connect: {SCOPE: ["openid","profile","email"], OAUTH_PKCE_ENABLED: true,
                APPS: [{provider_id: "pocketid", name: "Pocket ID", client_id: $id, secret: $secret,
                        settings: {server_url: $url}}]}}')
            printf "PAPERLESS_SOCIALACCOUNT_PROVIDERS='%s'\n" "$providers" > ${oidcEnvFile}
            chgrp ${config.services.paperless.user} ${oidcEnvFile}
          '';
        };
      };

    modules.software.tailscale.serve.paperless = {
      port = paperlessPort;
      target = "http://127.0.0.1:${toString paperlessPort}";
      after = ["paperless-web.service"];
    };
  };
}
