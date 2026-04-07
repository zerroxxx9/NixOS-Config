{
  config,
  pkgs,
  lib,
  inputs,
  hostVariables,
  ...
}: {
  options.modules.security.agenix = {
    enable = lib.mkEnableOption "agenix secret management";

    secrets = {
      tailscaleAuthKey = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy the Tailscale auth key secret.";
      };

      wifiPasswords = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy WiFi passwords via agenix.";
      };

      copilotApiKey = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy GitHub Copilot API key.";
      };

      braveBookmarks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy Brave browser bookmarks HTML.";
      };
    };
  };

  config = lib.mkIf config.modules.security.agenix.enable {
    # agenix CLI-Tool verfügbar machen (zum Verschlüsseln/Editieren)
    environment.systemPackages = [
      inputs.agenix.packages.${hostVariables.system}.default
    ];

    # Tailscale Auth-Key
    age.secrets.tailscale-authkey = lib.mkIf config.modules.security.agenix.secrets.tailscaleAuthKey {
      file = ../../secrets/tailscale-authkey.age;
      owner = "root";
      mode = "0400";
    };

    # WLAN-Passwörter (für NetworkManager)
    age.secrets.wifi-passwords = lib.mkIf config.modules.security.agenix.secrets.wifiPasswords {
      file = ../../secrets/wifi-passwords.age;
      owner = "root";
      mode = "0600";
    };

    # GitHub Copilot API Key
    age.secrets.copilot-api-key = lib.mkIf config.modules.security.agenix.secrets.copilotApiKey {
      file = ../../secrets/copilot-api-key.age;
      owner = hostVariables.username;
      mode = "0400";
    };

    # Brave Bookmarks HTML
    age.secrets.brave-bookmarks = lib.mkIf config.modules.security.agenix.secrets.braveBookmarks {
      file = ../../secrets/brave-bookmarks.age;
      owner = hostVariables.username;
      mode = "0400";
    };

    # Copilot API Key als Environment-Variable verfügbar machen
    systemd.user.services.copilot-env = lib.mkIf config.modules.security.agenix.secrets.copilotApiKey {
      description = "Load Copilot API key into environment";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.config/environment.d && echo \"GITHUB_COPILOT_API_KEY=$(cat ${config.age.secrets.copilot-api-key.path})\" > %h/.config/environment.d/copilot.conf'";
      };
    };

    # Brave Bookmarks beim Boot an die richtige Stelle kopieren
    system.activationScripts.deploy-brave-bookmarks = lib.mkIf config.modules.security.agenix.secrets.braveBookmarks {
      text = ''
        BRAVE_DIR="/home/${hostVariables.username}/.config/BraveSoftware/Brave-Browser/Default"
        if [ -f "${config.age.secrets.brave-bookmarks.path}" ]; then
          mkdir -p "$BRAVE_DIR"
          cp ${config.age.secrets.brave-bookmarks.path} "$BRAVE_DIR/Bookmarks"
          chown ${hostVariables.username}:users "$BRAVE_DIR/Bookmarks"
        fi
      '';
    };

    # WiFi-Passwörter: NetworkManager-Verbindungen generieren
    # Die .age-Datei sollte eine NetworkManager keyfile sein
    # Siehe Setup-Anleitung unten für das Format
    networking.networkmanager.ensureProfiles = lib.mkIf config.modules.security.agenix.secrets.wifiPasswords {
      environmentFiles = [ config.age.secrets.wifi-passwords.path ];
      profiles = {
        home-wifi = {
          connection = {
            id = "Home-WiFi";
            type = "wifi";
          };
          wifi = {
            ssid = "$HOME_WIFI_NAME";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$HOME_WIFI_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
        work-wifi = {
          connection = {
            id = "Work-WiFi";
            type = "wifi";
          };
          wifi = {
            ssid = "$WORK_WIFI_NAME";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$WORK_WIFI_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
        school-wifi = {
            connection = {
                id = "School-WiFi";
                type = "wifi";
            };
            wifi = {
                ssid = "$SCHOOL_WIFI_NAME";
                mode = "infrastructure";
            };
            wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$SCHOOL_WIFI_PSK";
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
        };
      };
    };
  };
}