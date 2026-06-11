{
  lib,
  pkgs,
  config,
  inputs,
  hostVariables,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  homeDir = "/home/${hostVariables.username}";
  matugenSpicetifyCss = "${homeDir}/.cache/matugen/spicetify.css";
  stripHash = color: builtins.substring 1 6 color;
  colors = rec {
    base = "#090f0e";
    mantle = "#161d1c";
    crust = "#0e1513";
    text = "#dde4e1";
    subtext0 = "#bec9c6";
    subtext1 = "#899390";
    surface0 = "#1a2120";
    surface1 = "#252b2a";
    surface2 = "#303635";
    overlay0 = "#3f4947";
    overlay1 = "#899390";
    overlay2 = "#bec9c6";
    blue = "#82d5c8";
    sapphire = "#b1ccc6";
    red = "#ffb4ab";

    spicetify = {
      base = stripHash base;
      mantle = stripHash mantle;
      crust = stripHash crust;
      text = stripHash text;
      subtext = stripHash subtext0;
      main = stripHash crust;
      sidebar = stripHash mantle;
      player = stripHash mantle;
      card = stripHash surface0;
      shadow = stripHash base;
      "selected-row" = stripHash surface1;
      button = stripHash blue;
      "button-active" = stripHash sapphire;
      "button-disabled" = stripHash overlay0;
      "tab-active" = stripHash blue;
      notification = stripHash surface0;
      "notification-error" = stripHash red;
      misc = stripHash surface1;
      surface0 = stripHash surface0;
      surface1 = stripHash surface1;
      surface2 = stripHash surface2;
      overlay0 = stripHash overlay0;
      overlay1 = stripHash overlay1;
      overlay2 = stripHash overlay2;
      red = stripHash red;
    };
  };
in {
  imports = [
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  options.modules.software.spicetify = {
    enable = lib.mkEnableOption "Spotify customization with Spicetify";
  };

  config = lib.mkIf config.modules.software.spicetify.enable {
    programs.spicetify = {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];

      theme = spicePkgs.themes.catppuccin;
      customColorScheme = colors.spicetify;
      extraCommands = ''
        css="Themes/catppuccin/user.css"
        if [ -f "$css" ]; then
          mv "$css" "$css.orig"
          {
            printf '%s\n' '@import url("file://${matugenSpicetifyCss}");'
            cat "$css.orig"
          } > "$css"
        fi
      '';
    };
  };
}
