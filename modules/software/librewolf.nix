{
  config,
  hostVariables,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.librewolf;

  newTabWallpaper = "${../../assets/wallpaper/kim-jaehyun-260126-01.png}";
  firefoxExtensionPath = "share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

  mkFetchedFirefoxExtension = {
    name,
    addonId,
    url,
    hash,
  }: let
    xpi = pkgs.fetchFirefoxAddon {
      inherit name url hash;
    };
  in
    pkgs.runCommand "${name}-firefox-extension" {
      passthru.addonId = addonId;
      meta.mozPermissions = [];
    } ''
      install -dm755 "$out/${firefoxExtensionPath}"
      xpi_file="$(find ${xpi} -maxdepth 1 -name '*.xpi' -print -quit)"
      ln -s "$xpi_file" "$out/${firefoxExtensionPath}/${addonId}.xpi"
    '';

  lockedPrivacyPreferences =
    lib.mapAttrs (_: value: {
      Value = value;
      Status = "locked";
    }) {
      "browser.display.use_document_fonts" = 0;
      "browser.privatebrowsing.autostart" = true;
      "browser.safebrowsing.downloads.remote.enabled" = false;
      "dom.battery.enabled" = false;
      "dom.event.clipboardevents.enabled" = false;
      "dom.private-attribution.submission.enabled" = false;
      "dom.push.enabled" = false;
      "dom.push.connection.enabled" = false;
      "dom.security.https_only_mode" = true;
      "dom.webaudio.enabled" = false;
      "dom.webnotifications.enabled" = false;
      "geo.enabled" = false;
      "identity.fxaccounts.enabled" = false;
      "media.eme.enabled" = false;
      "media.getusermedia.screensharing.enabled" = false;
      "media.navigator.enabled" = false;
      "media.peerconnection.enabled" = false;
      "network.captive-portal-service.enabled" = false;
      "network.connectivity-service.enabled" = false;
      "network.cookie.cookieBehavior" = 5;
      "network.cookie.lifetimePolicy" = 2;
      "network.dns.disablePrefetch" = true;
      "network.http.referer.XOriginPolicy" = 2;
      "network.http.referer.XOriginTrimmingPolicy" = 2;
      "network.http.speculative-parallel-limit" = 0;
      "network.predictor.enabled" = false;
      "network.prefetch-next" = false;
      "permissions.default.camera" = 2;
      "permissions.default.desktop-notification" = 2;
      "permissions.default.geo" = 2;
      "permissions.default.microphone" = 2;
      "privacy.firstparty.isolate" = true;
      "privacy.globalprivacycontrol.enabled" = true;
      "privacy.globalprivacycontrol.functionality.enabled" = true;
      "privacy.query_stripping.enabled" = true;
      "privacy.query_stripping.enabled.pbmode" = true;
      "privacy.resistFingerprinting" = true;
      "privacy.resistFingerprinting.letterboxing" = true;
      "privacy.sanitize.sanitizeOnShutdown" = true;
      "signon.autofillForms" = false;
      "signon.formlessCapture.enabled" = false;
      "signon.rememberSignons" = false;
      "webgl.disabled" = true;
      "webgl.enable-debug-renderer-info" = false;
      "webgl.enable-webgl2" = false;
      "webgl.force-enabled" = false;
    };

  defaultSettings = {
    "app.shield.optoutstudies.enabled" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.contentblocking.category" = "strict";
    "browser.discovery.enabled" = false;
    "browser.display.use_document_fonts" = 0;
    "browser.download.useDownloadDir" = false;
    "browser.formfill.enable" = false;
    "browser.helperApps.deleteTempFileOnExit" = true;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.pagethumbnails.capturing_disabled" = true;
    "browser.privatebrowsing.autostart" = true;
    "browser.safebrowsing.downloads.remote.enabled" = false;
    "browser.search.suggest.enabled" = false;
    "browser.sessionstore.privacy_level" = 2;
    "browser.sessionstore.resume_from_crash" = false;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.startup.page" = 0;
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.warnOnClose" = false;
    "browser.toolbars.bookmarks.visibility" = "newtab";
    "browser.uidensity" = 1;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.history" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.searches" = false;
    "dom.battery.enabled" = false;
    "dom.event.clipboardevents.enabled" = false;
    "dom.private-attribution.submission.enabled" = false;
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;
    "dom.maxHardwareConcurrency" = 2;
    "dom.push.enabled" = false;
    "dom.push.connection.enabled" = false;
    "dom.w3c_touch_events.enabled" = 0;
    "dom.w3c_touch_events.legacy_apis.enabled" = false;
    "dom.webaudio.enabled" = false;
    "dom.webnotifications.enabled" = false;
    "extensions.blocklist.enabled" = true;
    "extensions.getAddons.cache.enabled" = false;
    "extensions.pocket.enabled" = false;
    "geo.enabled" = false;
    "general.autoScroll" = true;
    "general.smoothScroll" = true;
    "identity.fxaccounts.enabled" = false;
    "layout.css.prefers-color-scheme.content-override" = 0;
    "media.autoplay.blocking_policy" = 2;
    "media.autoplay.default" = 5;
    "media.eme.enabled" = false;
    "media.gmp-provider.enabled" = false;
    "media.gmp-gmpopenh264.enabled" = false;
    "media.gmp-widevinecdm.enabled" = false;
    "media.getusermedia.screensharing.enabled" = false;
    "media.navigator.enabled" = false;
    "media.peerconnection.enabled" = false;
    "media.peerconnection.ice.default_address_only" = true;
    "media.peerconnection.ice.no_host" = true;
    "middlemouse.paste" = false;
    "network.captive-portal-service.enabled" = false;
    "network.connectivity-service.enabled" = false;
    "network.IDN_show_punycode" = true;
    "network.cookie.cookieBehavior" = 5;
    "network.cookie.lifetimePolicy" = 2;
    "network.dns.disablePrefetch" = true;
    "network.http.referer.XOriginPolicy" = 2;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.http.speculative-parallel-limit" = 0;
    "network.predictor.enabled" = false;
    "network.prefetch-next" = false;
    "permissions.default.camera" = 2;
    "permissions.default.desktop-notification" = 2;
    "permissions.default.geo" = 2;
    "permissions.default.microphone" = 2;
    "places.history.enabled" = false;
    "privacy.clearOnShutdown.history" = true;
    "privacy.donottrackheader.enabled" = false;
    "privacy.firstparty.isolate" = true;
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.functionality.enabled" = true;
    "privacy.partition.network_state" = true;
    "privacy.query_stripping.enabled" = true;
    "privacy.query_stripping.enabled.pbmode" = true;
    "privacy.resistFingerprinting.letterboxing" = true;
    "privacy.resistFingerprinting.pbmode" = true;
    "privacy.sanitize.clearOnShutdown.cache" = true;
    "privacy.sanitize.clearOnShutdown.cookies" = true;
    "privacy.sanitize.clearOnShutdown.downloads" = true;
    "privacy.sanitize.clearOnShutdown.formdata" = true;
    "privacy.sanitize.clearOnShutdown.history" = true;
    "privacy.sanitize.clearOnShutdown.offlineApps" = true;
    "privacy.sanitize.clearOnShutdown.sessions" = true;
    "privacy.sanitize.clearOnShutdown.siteSettings" = true;
    "privacy.sanitize.sanitizeOnShutdown" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "signon.autofillForms" = false;
    "signon.formlessCapture.enabled" = false;
    "signon.rememberSignons" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "webgl.disabled" = true;
    "webgl.enable-debug-renderer-info" = false;
    "webgl.enable-webgl2" = false;
    "webgl.force-enabled" = false;
  };

  defaultProfileSettings = {
    "extensions.autoDisableScopes" = 0;
    "extensions.update.enabled" = false;
  };

  userChrome = ''
    :root {
      --lw-bg: #0b0f14;
      --lw-bg-elevated: #111821;
      --lw-bg-hover: #182231;
      --lw-border: #263241;
      --lw-text: #dce7ef;
      --lw-muted: #91a4b7;
      --lw-accent: #7dd3c7;
      --lw-accent-strong: #8ab4f8;
      --toolbar-bgcolor: var(--lw-bg) !important;
      --toolbar-color: var(--lw-text) !important;
      --toolbarbutton-hover-background: var(--lw-bg-hover) !important;
      --toolbarbutton-active-background: #203044 !important;
      --urlbarView-highlight-background: var(--lw-bg-hover) !important;
      --urlbarView-highlight-color: var(--lw-text) !important;
      --tab-border-radius: 6px !important;
    }

    #navigator-toolbox {
      background: var(--lw-bg) !important;
      border-bottom: 1px solid var(--lw-border) !important;
    }

    #TabsToolbar,
    #nav-bar,
    #PersonalToolbar {
      background: transparent !important;
    }

    .tab-background {
      border-radius: var(--tab-border-radius) !important;
      box-shadow: none !important;
    }

    .tabbrowser-tab[selected="true"] .tab-background {
      background: var(--lw-bg-elevated) !important;
      outline: 1px solid var(--lw-border) !important;
    }

    .tabbrowser-tab:hover .tab-background {
      background: var(--lw-bg-hover) !important;
    }

    .tab-label {
      color: var(--lw-text) !important;
    }

    .tabbrowser-tab:not([selected="true"]) .tab-label {
      color: var(--lw-muted) !important;
    }

    #urlbar-background,
    #searchbar {
      background: var(--lw-bg-elevated) !important;
      border: 1px solid var(--lw-border) !important;
      border-radius: 6px !important;
      box-shadow: none !important;
    }

    #urlbar[focused="true"] #urlbar-background {
      border-color: var(--lw-accent) !important;
    }

    toolbarbutton,
    .toolbarbutton-1 {
      border-radius: 6px !important;
    }

    menupopup,
    panel {
      --panel-background: var(--lw-bg-elevated) !important;
      --panel-color: var(--lw-text) !important;
      --panel-border-color: var(--lw-border) !important;
      --panel-border-radius: 8px !important;
    }

    #sidebar-box,
    #sidebar-header {
      background: var(--lw-bg) !important;
      color: var(--lw-text) !important;
      border-color: var(--lw-border) !important;
    }

    #identity-icon-box,
    #tracking-protection-icon-container {
      color: var(--lw-accent-strong) !important;
    }
  '';

  userContent = ''
    @-moz-document url("about:newtab"), url("about:home"), url("about:privatebrowsing") {
      body,
      #root {
        min-height: 100vh !important;
        background:
          linear-gradient(rgba(6, 10, 16, 0.18), rgba(6, 10, 16, 0.38)),
          url("file://${newTabWallpaper}") center / cover no-repeat fixed !important;
      }

      body::before {
        content: "" !important;
        position: fixed !important;
        inset: 0 !important;
        pointer-events: none !important;
        background: radial-gradient(circle at 50% 35%, rgba(255, 255, 255, 0.16), rgba(5, 9, 14, 0.28) 72%) !important;
        z-index: -1 !important;
      }

      .search-wrapper .search-handoff-button,
      .search-wrapper input,
      .top-site-outer .tile {
        background-color: rgba(10, 16, 24, 0.72) !important;
        border: 1px solid rgba(220, 231, 239, 0.18) !important;
        box-shadow: 0 14px 36px rgba(0, 0, 0, 0.24) !important;
        backdrop-filter: blur(14px) !important;
      }

      .wordmark,
      .logo-and-wordmark,
      .top-site-outer .title,
      .personalize-button {
        color: #f3f7ec !important;
        text-shadow: 0 2px 16px rgba(0, 0, 0, 0.55) !important;
      }
    }
  '';
in {
  options.modules.software.librewolf = {
    enable = lib.mkEnableOption "LibreWolf browser";

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      example = lib.literalExpression ''
        with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          darkreader
        ]
      '';
      description = "LibreWolf extension packages to install into the default profile.";
    };

    extensionSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Optional declarative settings keyed by extension ID.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Additional LibreWolf profile preferences merged over the defaults.";
    };

    customTheme.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the custom userChrome.css theme.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.librewolf = {
        enable = true;
        package = pkgs.librewolf;

        policies = {
          DisableFirefoxAccounts = true;
          DisableFirefoxStudies = true;
          DisableFormHistory = true;
          DisableMasterPasswordCreation = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
          };
          ExtensionSettings = {
            "adguard-extra@adguard.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguard-extra/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            "foxyproxy@eric.h.jung" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/foxyproxy-standard/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            "wappalyzer@crunchlabz.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
          };
          OfferToSaveLogins = false;
          PasswordManagerEnabled = false;
          Preferences = lockedPrivacyPreferences;
        };

        settings = {
          "privacy.resistFingerprinting" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.emailtracking.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
        };

        profiles.default = {
          id = 0;
          name = "default";
          isDefault = true;

          settings = defaultSettings // defaultProfileSettings // cfg.settings;

          extensions = {
            packages =
              [
                (mkFetchedFirefoxExtension {
                  name = "adnauseam";
                  addonId = "nixos@adnauseam";
                  url = "https://addons.mozilla.org/firefox/downloads/file/4821708/adnauseam-3.28.6.xpi";
                  hash = "sha256-LCtX46Kfk5FHVht/KATCiSheelBcwuqLqwuLJOTHCOQ=";
                })

                # Extension placeholders:
                # TrackMeNot is no longer available from AMO, so keep it out
                # unless you have a trusted source archive and a pinned hash.
                # pkgs.nur.repos.rycee.firefox-addons.ublock-origin
                # pkgs.nur.repos.rycee.firefox-addons.bitwarden
                # pkgs.nur.repos.rycee.firefox-addons.darkreader
              ]
              ++ cfg.extensions;
            settings = cfg.extensionSettings;
          };

          userChrome = lib.optionalString cfg.customTheme.enable userChrome;
          userContent = lib.optionalString cfg.customTheme.enable userContent;
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "librewolf.desktop";
          "x-scheme-handler/http" = "librewolf.desktop";
          "x-scheme-handler/https" = "librewolf.desktop";
        };
      };
    };
  };
}
