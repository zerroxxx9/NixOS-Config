{
  lib,
  pkgs,
  config,
  inputs,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.spicetify;

  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  colorsDir = "/home/${hostVariables.username}/.local/state/matugen/spotify";
in {
  imports = [
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  options.modules.software.spicetify = {
    enable = lib.mkEnableOption "Spotify customization with Spicetify (custom floating-panel theme, recoloured from the wallpaper)";
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      # Own theme: a thin layout layer over Spotify's native styles (Bloom's
      # selectors do not match current Spotify builds). Colours come from
      # --spice-* variables, recoloured at runtime by matugen.js.
      theme = {
        name = "matugen";
        src = ./spicetify/theme;
        injectCss = true;
        replaceColors = true;
        overwriteAssets = false;
        injectThemeJs = false;
        sidebarConfig = false;
      };
      colorScheme = "dark";

      enabledExtensions =
        (with spicePkgs.extensions; [
          adblockify
          hidePodcasts
          featureShuffle
        ])
        ++ [
          # Polls the palette served below and overrides the theme's colour variables.
          {
            src = ./spicetify;
            name = "matugen.js";
          }
        ];
    };

    # matugen (set-wallpaper) renders the palette into colorsDir; this exposes
    # only that directory on localhost for the extension above.
    home-manager.users.${hostVariables.username}.systemd.user.services.spotify-colors = {
      Unit.Description = "Serve the wallpaper palette to Spotify";
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${colorsDir}";
        ExecStart = "${pkgs.python3}/bin/python3 -I ${./spicetify/serve.py} ${colorsDir} 8374";
        Restart = "on-failure";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
