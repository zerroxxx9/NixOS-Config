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
in {
  imports = [
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  options.modules.software.spicetify = {
    enable = lib.mkEnableOption "Spotify customization with Spicetify and the Nord theme";
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      theme =
        spicePkgs.themes.nord
        // {
          injectThemeJs = false;
        };

      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        featureShuffle
      ];
    };
  };
}
