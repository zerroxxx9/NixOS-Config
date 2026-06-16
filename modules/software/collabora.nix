{
  lib,
  config,
  ...
}: let
  collaboraPort = 9980;
  wopiPort = 9300;
  hostname = "homelab-1.tail11bba0.ts.net";
  serverTailscaleIp = "100.73.190.127";
  clientTailscaleIps = [
    "100.124.232.93"
    "100.107.214.63"
    serverTailscaleIp
  ];
  ipRegex = ip: lib.replaceStrings ["."] ["\\."] ip;
  ipv4MappedRegex = ip: "::ffff:${ipRegex ip}";
  postAllowHosts =
    [
      "127\\.0\\.0\\.1"
      "::ffff:127\\.0\\.0\\.1"
      "::1"
    ]
    ++ map ipRegex clientTailscaleIps
    ++ map ipv4MappedRegex clientTailscaleIps;
  collaboraUrl = "https://${hostname}:${toString collaboraPort}";
  collaboraTailscaleIpUrl = "https://${serverTailscaleIp}:${toString collaboraPort}";
  collaboraUrls = [
    collaboraUrl
    collaboraTailscaleIpUrl
  ];
  wopiUrl = "http://127.0.0.1:${toString wopiPort}";
  wopiPublicUrl = "https://${hostname}:${toString wopiPort}";
  wopiAliases = [
    wopiPublicUrl
    "https://${hostname}"
    "https://${hostname}:443"
    "https://homelab:${toString wopiPort}"
    "https://.*\\.ts\\.net:${toString wopiPort}"
    "http://.*\\.ts\\.net:${toString wopiPort}"
    "http://${hostname}:${toString wopiPort}"
    "http://homelab:${toString wopiPort}"
    "http://127.0.0.1:${toString wopiPort}"
    "http://localhost:${toString wopiPort}"
    "https://${serverTailscaleIp}"
    "https://${serverTailscaleIp}:443"
    "https://${serverTailscaleIp}:${toString wopiPort}"
    "http://${serverTailscaleIp}:${toString wopiPort}"
  ];
  frameAncestorOrigins = [
    "https://${hostname}"
    "https://${hostname}:443"
    "https://${serverTailscaleIp}"
    "https://${serverTailscaleIp}:443"
  ];
  frameAncestors = lib.concatStringsSep " " frameAncestorOrigins;
  contentSecurityFrameAncestors = lib.concatStringsSep " " (["'self'"] ++ frameAncestorOrigins);
  collaboraAppName = "CollaboraOnline";
  collaboraMimeTypes = [
    {
      mime_type = "application/pdf";
      extension = "pdf";
      name = "PDF";
      description = "PDF document";
      icon = "";
      default_app = "";
      allow_creation = false;
    }
    {
      mime_type = "application/vnd.oasis.opendocument.text";
      extension = "odt";
      name = "OpenDocument";
      description = "OpenDocument text document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.oasis.opendocument.spreadsheet";
      extension = "ods";
      name = "OpenSpreadsheet";
      description = "OpenDocument spreadsheet document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.oasis.opendocument.presentation";
      extension = "odp";
      name = "OpenPresentation";
      description = "OpenDocument presentation document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      extension = "docx";
      name = "Microsoft Word";
      description = "Microsoft Word document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.form";
      extension = "docxf";
      name = "Form Document";
      description = "Form Document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      extension = "xlsx";
      name = "Microsoft Excel";
      description = "Microsoft Excel document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.openxmlformats-officedocument.presentationml.presentation";
      extension = "pptx";
      name = "Microsoft PowerPoint";
      description = "Microsoft PowerPoint document";
      icon = "";
      default_app = collaboraAppName;
      allow_creation = true;
    }
    {
      mime_type = "application/vnd.jupyter";
      extension = "ipynb";
      name = "Jupyter Notebook";
      description = "Jupyter Notebook";
      icon = "";
      default_app = "";
      allow_creation = true;
    }
  ];
in {
  options.modules.software.collabora = {
    enable = lib.mkEnableOption "Collabora Online";
  };

  config = lib.mkIf config.modules.software.collabora.enable {
    services.collabora-online = {
      enable = true;
      port = collaboraPort;
      aliasGroups = [
        {
          host = wopiUrl;
          aliases = wopiAliases;
        }
      ];

      settings = {
        server_name = "${hostname}:${toString collaboraPort}";

        ssl = {
          enable = false;
          termination = true;
        };

        net = {
          proto = "IPv4";
          listen = "loopback";
          content_security_policy = "frame-ancestors ${contentSecurityFrameAncestors};";
          frame_ancestors = frameAncestors;
          post_allow.host = postAllowHosts;
        };

        storage.wopi = {
          "@allow" = true;
          alias_groups."@mode" = "groups";
        };
      };
    };

    services.opencloud = lib.mkIf config.modules.software.opencloud.enable {
      environment = {
        OC_INSECURE = "true";
        OC_ADD_RUN_SERVICES = "collaboration";
        PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";
        FRONTEND_APP_HANDLER_SECURE_VIEW_APP_ADDR = "eu.opencloud.api.collaboration.${collaboraAppName}";
        MICRO_REGISTRY = "nats-js-kv";
        MICRO_REGISTRY_ADDRESS = "127.0.0.1:9233";
        COLLABORATION_WOPI_SRC = wopiUrl;
        COLLABORATION_APP_NAME = collaboraAppName;
        COLLABORATION_APP_PRODUCT = "Collabora";
        COLLABORATION_APP_ADDR = collaboraUrl;
        COLLABORATION_APP_ICON = "${collaboraUrl}/favicon.ico";
        COLLABORATION_APP_PROOF_DISABLE = "true";
        COLLABORATION_CS3API_DATAGATEWAY_INSECURE = "true";
      };

      settings = {
        app-registry.app_registry.mimetypes = collaboraMimeTypes;
        csp.directives = {
          child-src = ["'self'"];
          connect-src = [
            "'self'"
            "blob:"
            "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
          ];
          default-src = ["'none'"];
          font-src = ["'self'"];
          frame-ancestors = ["'self'"];
          frame-src =
            [
              "'self'"
              "blob:"
              "https://embed.diagrams.net/"
            ]
            ++ map (url: "${url}/") collaboraUrls;
          img-src =
            [
              "'self'"
              "data:"
              "blob:"
              "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
            ]
            ++ map (url: "${url}/") collaboraUrls;
          manifest-src = ["'self'"];
          media-src = ["'self'"];
          object-src = [
            "'self'"
            "blob:"
          ];
          script-src = [
            "'self'"
            "'unsafe-inline'"
          ];
          style-src = [
            "'self'"
            "'unsafe-inline'"
          ];
        };
      };
    };

    systemd.services.opencloud = lib.mkIf config.modules.software.opencloud.enable {
      after =
        ["coolwsd.service"]
        ++ lib.optionals config.modules.software.tailscale.enable ["tailscale-serve-collabora.service"];
      wants =
        ["coolwsd.service"]
        ++ lib.optionals config.modules.software.tailscale.enable ["tailscale-serve-collabora.service"];
    };

    systemd.services.tailscale-serve-collabora = lib.mkIf config.modules.software.tailscale.enable {
      description = "Publish Collabora Online via Tailscale Serve";
      after = ["network-online.target" "tailscaled.service" "coolwsd.service"];
      wants = ["network-online.target" "tailscaled.service" "coolwsd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=${toString collaboraPort} http://127.0.0.1:${toString collaboraPort}";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=${toString collaboraPort} off";
      };
    };
  };
}
