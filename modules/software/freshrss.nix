{
  lib,
  pkgs,
  config,
  ...
}: let
  freshrssPort = 8000;
  cfg = config.modules.software.freshrss;
  freshrssCfg = config.services.freshrss;
  xmlEscape = lib.replaceStrings ["&" "<" ">" "\"" "'"] ["&amp;" "&lt;" "&gt;" "&quot;" "&apos;"];
  feedOutline = feed: ''
    <outline type="rss" text="${xmlEscape feed.title}" title="${xmlEscape feed.title}" xmlUrl="${xmlEscape feed.url}" />
  '';
  opml = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="1.0">
      <head>
        <title>FreshRSS feeds</title>
      </head>
      <body>
        <outline text="Security" title="Security">
    ${lib.concatMapStrings feedOutline cfg.feeds}
        </outline>
      </body>
    </opml>
  '';
  feedsOpml = pkgs.writeText "freshrss-feeds.opml" opml;
  feedsHash = builtins.hashString "sha256" opml;
in {
  options.modules.software.freshrss = {
    enable = lib.mkEnableOption "freshrss";

    feeds = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          title = lib.mkOption {
            type = lib.types.str;
            description = "Display name for the feed.";
          };

          url = lib.mkOption {
            type = lib.types.str;
            description = "RSS or Atom feed URL.";
          };
        };
      });
      default = [
        {
          title = "The Hacker News";
          url = "https://thehackernews.com/feeds/posts/default";
        }
        {
          title = "TechCrunch";
          url = "https://techcrunch.com/feed/";
        }
        {
          title = "Golem Security";
          url = "https://rss.golem.de/rss.php?feed=RSS2.0&ms=security";
        }
        {
          title = "Heise Security";
          url = "https://www.heise.de/security/rss/news-atom.xml";
        }
        {
          title = "BleepingComputer Security";
          url = "https://www.bleepingcomputer.com/feed/";
        }
      ];
      description = "Feeds to import for the default FreshRSS user.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.freshrss = {
      enable = true;
      baseUrl = "https://homelab.tail11bba0.ts.net:${toString freshrssPort}";
      authType = "none";
    };

    services.nginx.virtualHosts.${config.services.freshrss.virtualHost} = {
      listen = [
        {
          addr = "127.0.0.1";
          port = freshrssPort;
        }
      ];
      serverAliases = ["homelab.tail11bba0.ts.net"];
    };

    systemd.services.tailscale-serve-freshrss = lib.mkIf config.modules.software.tailscale.enable {
      description = "Publish FreshRSS via Tailscale Serve";
      after = ["network-online.target" "tailscaled.service" "nginx.service" "phpfpm-freshrss.service" "freshrss-config.service"];
      wants = ["network-online.target" "tailscaled.service" "nginx.service" "phpfpm-freshrss.service" "freshrss-config.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=${toString freshrssPort} http://127.0.0.1:${toString freshrssPort}";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=${toString freshrssPort} off";
      };
    };

    systemd.services.freshrss-import-feeds = lib.mkIf (cfg.feeds != []) {
      description = "Import declarative FreshRSS feeds";
      after = ["freshrss-config.service"];
      wants = ["freshrss-config.service"];
      wantedBy = ["multi-user.target"];
      environment.DATA_PATH = freshrssCfg.dataDir;
      serviceConfig = {
        Type = "oneshot";
        User = freshrssCfg.user;
        Group = freshrssCfg.user;
        WorkingDirectory = freshrssCfg.package;
      };
      script = ''
        stampFile="${freshrssCfg.dataDir}/.nixos-feeds-opml-sha256"

        if [ -f "$stampFile" ] && [ "$(cat "$stampFile")" = "${feedsHash}" ]; then
          exit 0
        fi

        ${freshrssCfg.package}/cli/import-for-user.php --user '${freshrssCfg.defaultUser}' --filename '${feedsOpml}'
        printf '%s\n' '${feedsHash}' > "$stampFile"
      '';
    };
  };
}
