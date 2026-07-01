{
  lib,
  pkgs,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.osu;
  homeDir = "/home/${hostVariables.username}";
  importDir = "${homeDir}/${cfg.beatmapImportDir}";
  osuImportBeatmaps = pkgs.writeShellApplication {
    name = "osu-import-beatmaps";
    runtimeInputs = [pkgs.findutils];
    text = ''
      import_dir="${importDir}"

      if [ ! -d "$import_dir" ]; then
        echo "osu! beatmap import directory does not exist: $import_dir" >&2
        exit 1
      fi

      mapfile -d "" beatmaps < <(find "$import_dir" -maxdepth 1 -type f \( -name '*.osz' -o -name '*.osk' \) -print0 | sort -z)
      if [ "''${#beatmaps[@]}" -eq 0 ]; then
        echo "No .osz or .osk files found in $import_dir"
        exit 0
      fi

      exec ${lib.getExe cfg.package} "''${beatmaps[@]}"
    '';
  };
in {
  options.modules.software.osu = {
    enable = lib.mkEnableOption "osu!lazer";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.osu-lazer-bin;
      defaultText = lib.literalExpression "pkgs.osu-lazer-bin";
      description = "osu! package to install.";
    };

    beatmapImportDir = lib.mkOption {
      type = lib.types.str;
      default = "Games/osu/import";
      description = "Directory, relative to the user's home, where declarative beatmap archives are linked.";
    };

    beatmaps = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      example = lib.literalExpression ''
        [
          ./beatmaps/example.osz
          ./skins/example.osk
        ]
      '';
      description = "Beatmap or skin archives to link into the osu! import directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${homeDir}/Games 0755 ${hostVariables.username} users - -"
      "d ${homeDir}/Games/osu 0755 ${hostVariables.username} users - -"
      "d ${importDir} 0755 ${hostVariables.username} users - -"
    ];

    home-manager.users.${hostVariables.username} = {lib, ...}: {
      home.packages = [
        cfg.package
        osuImportBeatmaps
      ];

      home.file =
        lib.listToAttrs
        (map (beatmap: {
          name = "${cfg.beatmapImportDir}/${baseNameOf (toString beatmap)}";
          value.source = beatmap;
        })
        cfg.beatmaps);

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/x-osu-beatmap-archive" = ["osu!.desktop"];
          "application/x-osu-skin-archive" = ["osu!.desktop"];
        };
      };
    };
  };
}
