{
  config,
  pkgs,
  lib,
  inputs,
  hostVariables,
  ...
}: let
  cfg = config.modules.security.agenix;

  tailscaleAuthKeyFile = ../../secrets/tailscale-authkey.age;
  wifiPasswordsFile = ../../secrets/wifi-passwords.age;
  copilotApiKeyFile = ../../secrets/copilot-api-key.age;
  braveBookmarksFile = ../../secrets/brave-bookmarks.age;

  hasTailscaleAuthKey = builtins.pathExists tailscaleAuthKeyFile;
  hasWifiPasswords = builtins.pathExists wifiPasswordsFile;
  hasCopilotApiKey = builtins.pathExists copilotApiKeyFile;
  hasBraveBookmarks = builtins.pathExists braveBookmarksFile;
in {
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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.agenix.packages.${hostVariables.system}.default
      pkgs.age
    ];

    age.identityPaths = lib.mkDefault ["/etc/ssh/ssh_host_ed25519_key"];

    warnings =
      lib.optional (cfg.secrets.tailscaleAuthKey && !hasTailscaleAuthKey) ''
        modules.security.agenix.secrets.tailscaleAuthKey is enabled, but secrets/tailscale-authkey.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/tailscale-authkey.age
      ''
      ++ lib.optional (cfg.secrets.wifiPasswords && !hasWifiPasswords) ''
        modules.security.agenix.secrets.wifiPasswords is enabled, but secrets/wifi-passwords.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/wifi-passwords.age
      ''
      ++ lib.optional (cfg.secrets.copilotApiKey && !hasCopilotApiKey) ''
        modules.security.agenix.secrets.copilotApiKey is enabled, but secrets/copilot-api-key.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/copilot-api-key.age
      ''
      ++ lib.optional (cfg.secrets.braveBookmarks && !hasBraveBookmarks) ''
        modules.security.agenix.secrets.braveBookmarks is enabled, but secrets/brave-bookmarks.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/brave-bookmarks.age
      '';

    age.secrets.tailscale-authkey = lib.mkIf (cfg.secrets.tailscaleAuthKey && hasTailscaleAuthKey) {
      file = tailscaleAuthKeyFile;
      owner = "root";
      mode = "0400";
    };

    age.secrets.wifi-passwords = lib.mkIf (cfg.secrets.wifiPasswords && hasWifiPasswords) {
      file = wifiPasswordsFile;
      owner = "root";
      mode = "0600";
    };

    age.secrets.copilot-api-key = lib.mkIf (cfg.secrets.copilotApiKey && hasCopilotApiKey) {
      file = copilotApiKeyFile;
      owner = hostVariables.username;
      mode = "0400";
    };

    age.secrets.brave-bookmarks = lib.mkIf (cfg.secrets.braveBookmarks && hasBraveBookmarks) {
      file = braveBookmarksFile;
      owner = hostVariables.username;
      mode = "0400";
    };

    home-manager.users.${hostVariables.username}.home.sessionVariables = lib.mkIf (cfg.secrets.copilotApiKey && hasCopilotApiKey) {
      GITHUB_COPILOT_API_KEY_FILE = config.age.secrets."copilot-api-key".path;
    };

    system.activationScripts.deploy-brave-bookmarks = lib.mkIf (cfg.secrets.braveBookmarks && hasBraveBookmarks) {
      text = ''
        BRAVE_DIR="/home/${hostVariables.username}/.config/BraveSoftware/Brave-Browser/Default"
        if [ -f "${config.age.secrets."brave-bookmarks".path}" ]; then
          mkdir -p "$BRAVE_DIR"
          cp ${config.age.secrets."brave-bookmarks".path} "$BRAVE_DIR/Bookmarks"
          chown ${hostVariables.username}:users "$BRAVE_DIR/Bookmarks"
        fi
      '';
    };

    networking.networkmanager.ensureProfiles = lib.mkIf (cfg.secrets.wifiPasswords && hasWifiPasswords) {
      environmentFiles = [config.age.secrets."wifi-passwords".path];
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
