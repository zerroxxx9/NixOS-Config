{
  config,
  lib,
  pkgs,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.ctf-browser;
  profileName = "ctf";

  refLinks = [
    {
      name = "revshells";
      url = "https://www.revshells.com/";
    }
    {
      name = "GTFOBins";
      url = "https://gtfobins.github.io/";
    }
    {
      name = "HackTricks";
      url = "https://book.hacktricks.wiki/";
    }
    {
      name = "PayloadsAllTheThings";
      url = "https://swisskyrepo.github.io/PayloadsAllTheThings/";
    }
    {
      name = "CyberChef";
      url = "https://gchq.github.io/CyberChef/";
    }
    {
      name = "CrackStation";
      url = "https://crackstation.net/";
    }
    {
      name = "explainshell";
      url = "https://explainshell.com/";
    }
  ];

  mkBurpCaScript = profilesPath:
    pkgs.writeShellScriptBin "ctf-burp-ca" ''
      set -eu
      cert="''${1:-}"
      if [ -z "$cert" ] || [ ! -f "$cert" ]; then
        echo "usage: ctf-burp-ca <burp-ca.der|.pem>   (close ctf-browser first)" >&2
        exit 1
      fi
      db="$HOME/${profilesPath}/${profileName}"
      if [ ! -f "$db/cert9.db" ]; then
        echo "ctf-burp-ca: no cert9.db in $db — launch ctf-browser once first" >&2
        exit 1
      fi
      ${pkgs.nssTools}/bin/certutil -A -n "Burp CA (ctf)" -t "C,," -i "$cert" -d "sql:$db"
      echo "imported into $db"
    '';
in {
  options.modules.software.ctf-browser = {
    enable = lib.mkEnableOption "isolated, un-hardened Firefox profile for CTF / bug bounty work";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      policies = {
        DontCheckDefaultBrowser = true;
        Bookmarks =
          map (l: {
            Title = l.name;
            URL = l.url;
            Placement = "toolbar";
            Folder = "ctf-ref";
          })
          refLinks;
      };
    };

    home-manager.users.${hostVariables.username} = {config, ...}: {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;

        profiles.default = {
          id = 0;
          isDefault = true;
        };

        profiles.${profileName} = {
          id = 1;
          name = profileName;
          isDefault = false;

          settings = {
            "privacy.resistFingerprinting" = false;
            "privacy.trackingprotection.enabled" = false;
            "network.cookie.lifetimePolicy" = 0;
            "browser.privatebrowsing.autostart" = false;
            "extensions.autoDisableScopes" = 0;
            "browser.aboutConfig.showWarning" = false;
            "devtools.chrome.enabled" = true;
            "security.enterprise_roots.enabled" = true;
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          };

          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            foxyproxy-standard
            wappalyzer
            cookie-editor
            user-agent-string-switcher
          ];

          userChrome = ''
            #navigator-toolbox {
              border-bottom: 3px solid #e5484d !important;
            }
            #TabsToolbar,
            #nav-bar,
            #PersonalToolbar,
            #titlebar {
              background-color: #3a0d10 !important;
            }
            .tabbrowser-tab[selected] .tab-background {
              background-color: #e5484d !important;
            }
          '';
        };
      };

      home.packages = [
        (mkBurpCaScript config.programs.firefox.profilesPath)
        (pkgs.writeShellScriptBin "ctf-browser" ''
          exec ${config.programs.firefox.finalPackage}/bin/firefox -P ${profileName} --no-remote --name ctf-browser --class=ctf-browser "$@"
        '')
      ];

      xdg.desktopEntries.ctf-browser = {
        name = "CTF Browser";
        genericName = "Web Browser (CTF / bug bounty)";
        exec = "ctf-browser %U";
        icon = "firefox";
        terminal = false;
        categories = ["Network" "WebBrowser"];
        startupNotify = true;
        settings.StartupWMClass = "ctf-browser";
      };
    };
  };
}
