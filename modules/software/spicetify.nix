{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  stripHash = color: builtins.substring 1 6 color;
  colors = rec {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    surface0 = "#313244";
    surface1 = "#45475a";
    overlay0 = "#6c7086";
    blue = "#89b4fa";
    sapphire = "#74c7ec";
    red = "#f38ba8";

    spicetify = {
      text = stripHash text;
      subtext = stripHash subtext0;
      main = stripHash base;
      sidebar = stripHash mantle;
      player = stripHash mantle;
      card = stripHash surface0;
      shadow = stripHash crust;
      "selected-row" = stripHash surface1;
      button = stripHash blue;
      "button-active" = stripHash sapphire;
      "button-disabled" = stripHash overlay0;
      "tab-active" = stripHash blue;
      notification = stripHash surface0;
      "notification-error" = stripHash red;
      misc = stripHash surface1;
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
    };
  };
}
