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
  chessstackEnvFile = ../../secrets/chessstack-env.age;
  braveBookmarksFile = ../../secrets/brave-bookmarks.age;
  desktopBookmarksFile = ../../secrets/desktop-bookmarks.age;

  hasTailscaleAuthKey = builtins.pathExists tailscaleAuthKeyFile;
  hasWifiPasswords = builtins.pathExists wifiPasswordsFile;
  hasCopilotApiKey = builtins.pathExists copilotApiKeyFile;
  hasChessstackEnv = builtins.pathExists chessstackEnvFile;
  hasBraveBookmarks = builtins.pathExists braveBookmarksFile;
  hasDesktopBookmarks = builtins.pathExists desktopBookmarksFile;
  hasConfiguredBookmarks =
    (cfg.secrets.braveBookmarks && hasBraveBookmarks)
    || (cfg.secrets.desktopBookmarks && hasDesktopBookmarks);
  hasConfiguredAgeSecrets =
    (cfg.secrets.tailscaleAuthKey && hasTailscaleAuthKey)
    || (cfg.secrets.wifiPasswords && hasWifiPasswords)
    || (cfg.secrets.copilotApiKey && hasCopilotApiKey)
    || (cfg.secrets.chessstackEnv && hasChessstackEnv)
    || hasConfiguredBookmarks;
  bookmarksSecretPath =
    if cfg.secrets.desktopBookmarks
    then config.age.secrets."desktop-bookmarks".path
    else config.age.secrets."brave-bookmarks".path;
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

      chessstackEnv = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy the Chessstack environment secret.";
      };

      braveBookmarks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy shared Brave browser bookmarks.";
      };

      desktopBookmarks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Deploy desktop-specific Brave browser bookmarks.";
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
      ++ lib.optional (cfg.secrets.chessstackEnv && !hasChessstackEnv) ''
        modules.security.agenix.secrets.chessstackEnv is enabled, but secrets/chessstack-env.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/chessstack-env.age
        Expected keys:
          DATABASE_URL=postgresql://chessstack@host.containers.internal:5432/chessstack
          DEFAULT_USERNAME=<admin username>
          DEFAULT_PASSWORD=<admin password>
      ''
      ++ lib.optional (cfg.secrets.braveBookmarks && !hasBraveBookmarks) ''
        modules.security.agenix.secrets.braveBookmarks is enabled, but secrets/brave-bookmarks.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/brave-bookmarks.age
      ''
      ++ lib.optional (cfg.secrets.desktopBookmarks && !hasDesktopBookmarks) ''
        modules.security.agenix.secrets.desktopBookmarks is enabled, but secrets/desktop-bookmarks.age is missing.
        Create it from the repo root with:
          RULES=secrets/secrets.nix agenix -e secrets/desktop-bookmarks.age
      '';

    assertions = [
      {
        assertion = !(cfg.secrets.braveBookmarks && cfg.secrets.desktopBookmarks);
        message = "Enable only one Brave bookmarks secret per host: braveBookmarks or desktopBookmarks.";
      }
    ];

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

    age.secrets.chessstack-env = lib.mkIf (cfg.secrets.chessstackEnv && hasChessstackEnv) {
      file = chessstackEnvFile;
      owner = "root";
      mode = "0600";
    };

    age.secrets.brave-bookmarks = lib.mkIf (cfg.secrets.braveBookmarks && hasBraveBookmarks) {
      file = braveBookmarksFile;
      owner = hostVariables.username;
      mode = "0400";
    };

    age.secrets.desktop-bookmarks = lib.mkIf (cfg.secrets.desktopBookmarks && hasDesktopBookmarks) {
      file = desktopBookmarksFile;
      owner = hostVariables.username;
      mode = "0400";
    };

    home-manager.users.${hostVariables.username}.home.sessionVariables = lib.mkIf (cfg.secrets.copilotApiKey && hasCopilotApiKey) {
      GITHUB_COPILOT_API_KEY_FILE = config.age.secrets."copilot-api-key".path;
    };

    system.activationScripts = lib.mkMerge [
      # If secrets are decrypted using an AGE-PLUGIN-YUBIKEY-* identity, the
      # activation-time PATH must include the plugin binary.
      (lib.mkIf (config.modules.security.yubikey.enable && hasConfiguredAgeSecrets) {
        agenixInstall.deps = lib.mkBefore ["yubikey-age-plugin-path"];
      })
      (lib.mkIf hasConfiguredBookmarks {
        deploy-brave-bookmarks.text = ''
          BRAVE_DIR="/home/${hostVariables.username}/.config/BraveSoftware/Brave-Browser/Default"
          if [ -f "${bookmarksSecretPath}" ]; then
            mkdir -p "$BRAVE_DIR"
            # Avoid writing while Brave is running (can trigger lock/corruption warnings).
            if pgrep -u "${hostVariables.username}" -f "/bin/brave|brave" >/dev/null 2>&1; then
              echo "[agenix] Brave is running; skipping bookmark deploy to $BRAVE_DIR/Bookmarks" >&2
            else
              install -m 0600 -o "${hostVariables.username}" -g users \
                "${bookmarksSecretPath}" \
                "$BRAVE_DIR/Bookmarks"
            fi
          fi
        '';
      })
    ];

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
