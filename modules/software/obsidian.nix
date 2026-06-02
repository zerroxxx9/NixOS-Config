{
  lib,
  pkgs,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.obsidian;
  pluginId = "obsidian-livesync";
  liveSyncPlugin = pkgs.runCommand "${pluginId}-${cfg.liveSync.version}" {} ''
    mkdir -p "$out"
    cp ${
      pkgs.fetchurl {
        url = "https://github.com/vrtmrz/obsidian-livesync/releases/download/${cfg.liveSync.version}/main.js";
        hash = "sha256-zV+qEu84zNXKcFtObQXjLEus3fxDMcpcT7r9Viu60IA=";
      }
    } "$out/main.js"
    cp ${
      pkgs.fetchurl {
        url = "https://github.com/vrtmrz/obsidian-livesync/releases/download/${cfg.liveSync.version}/manifest.json";
        hash = "sha256-vZ7sruy7py2bHJvhOgg6hqb20yceWZ/tvV+ifbVBQrA=";
      }
    } "$out/manifest.json"
    cp ${
      pkgs.fetchurl {
        url = "https://github.com/vrtmrz/obsidian-livesync/releases/download/${cfg.liveSync.version}/styles.css";
        hash = "sha256-4PExkKtAdimEHIjqzQ0P4AAy9Wy7L5DJjY/AU9wIlEs=";
      }
    } "$out/styles.css"
  '';
  liveSyncSeed = pkgs.writeText "obsidian-livesync-data.json" (builtins.toJSON {
    remoteType = "couchdb";
    useCustomRequestHandler = false;
    couchDB_URI = cfg.liveSync.couchDB.uri;
    couchDB_USER = cfg.liveSync.couchDB.user;
    couchDB_PASSWORD = "";
    couchDB_DBNAME = cfg.liveSync.couchDB.databaseName;
    liveSync = false;
    syncOnSave = true;
    syncOnStart = true;
    periodicReplication = true;
    periodicReplicationInterval = 60;
    encrypt = true;
    passphrase = "";
    usePathObfuscation = true;
    trashInsteadDelete = true;
    batchSave = true;
    batchSaveMinimumDelay = 5;
    batchSaveMaximumDelay = 60;
    showStatusOnEditor = true;
    showStatusOnStatusbar = true;
    usePluginSync = false;
    syncInternalFiles = false;
    syncInternalFilesBeforeReplication = false;
    syncInternalFilesIgnorePatterns = "\\/node_modules\\/, \\/\\.git\\/, \\/obsidian-livesync\\/";
    syncInternalFilesInterval = 60;
    readChunksOnline = true;
    watchInternalFileChanges = true;
    disableRequestURI = true;
    skipOlderFilesOnSync = true;
  });
in {
  options.modules.software.obsidian = {
    enable = lib.mkEnableOption "Obsidian with LiveSync preconfiguration";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "Documents/Obsidian";
      description = "Default Obsidian vault path relative to the user's home directory.";
    };

    liveSync = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install and enable the Self-hosted LiveSync community plugin.";
      };

      version = lib.mkOption {
        type = lib.types.str;
        default = "0.25.62";
        description = "Pinned Self-hosted LiveSync release version.";
      };

      couchDB = {
        uri = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Optional CouchDB URI to seed into LiveSync. Leave empty to fill it in Obsidian.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Optional CouchDB username to seed into LiveSync. Do not put passwords in Nix.";
        };

        databaseName = lib.mkOption {
          type = lib.types.str;
          default = "obsidian";
          description = "CouchDB database name for this vault.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.liveSync.enable || cfg.liveSync.version == "0.25.62";
        message = "modules.software.obsidian.liveSync.version is hash-pinned to 0.25.62. Update the fetchurl hashes in modules/software/obsidian.nix before changing it.";
      }
    ];

    systemd.tmpfiles.rules =
      lib.optionals (lib.hasPrefix "Documents/" cfg.vaultPath) [
        "d /home/${hostVariables.username}/Documents 0755 ${hostVariables.username} users - -"
        "z /home/${hostVariables.username}/Documents 0755 ${hostVariables.username} users - -"
      ]
      ++ [
        "d /home/${hostVariables.username}/${cfg.vaultPath} 0755 ${hostVariables.username} users - -"
      ];

    home-manager.users.${hostVariables.username} = {lib, ...}: {
      home.packages = [pkgs.unstable.obsidian];

      home.activation.configureObsidian = lib.hm.dag.entryAfter ["writeBoundary"] ''
        vault="$HOME/${cfg.vaultPath}"
        obsidian_config="$HOME/.config/obsidian"
        plugin_dir="$vault/.obsidian/plugins/${pluginId}"

        mkdir -p "$plugin_dir" "$obsidian_config"

        if [ ! -e "$obsidian_config/obsidian.json" ]; then
          cat > "$obsidian_config/obsidian.json" <<JSON
        {"vaults":{"default":{"path":"$vault","open":true}},"updateDisabled":true}
        JSON
        fi

        ${
          lib.optionalString cfg.liveSync.enable ''
            install -m 0644 ${liveSyncPlugin}/main.js "$plugin_dir/main.js"
            install -m 0644 ${liveSyncPlugin}/manifest.json "$plugin_dir/manifest.json"
            install -m 0644 ${liveSyncPlugin}/styles.css "$plugin_dir/styles.css"

            plugins_file="$vault/.obsidian/community-plugins.json"
            if [ ! -e "$plugins_file" ]; then
              printf '%s\n' '["${pluginId}"]' > "$plugins_file"
            elif ! ${pkgs.jq}/bin/jq -e 'index("${pluginId}") != null' "$plugins_file" >/dev/null 2>&1; then
              tmp="$(mktemp)"
              ${pkgs.jq}/bin/jq '. + ["${pluginId}"]' "$plugins_file" > "$tmp"
              mv "$tmp" "$plugins_file"
            fi

            if [ ! -e "$plugin_dir/data.json" ]; then
              install -m 0600 ${liveSyncSeed} "$plugin_dir/data.json"
            fi
          ''
        }
      '';
    };
  };
}
