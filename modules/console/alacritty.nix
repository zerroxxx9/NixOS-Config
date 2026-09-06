{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: let
  palette = import ../gui/palette.nix;
in {
  options.modules.gui.alacritty = {
    enable = lib.mkEnableOption "alacritty";
  };

  config = lib.mkIf config.modules.gui.alacritty.enable {
    home-manager.users.${hostVariables.username} = {
      programs.alacritty = {
        enable = true;
        settings = {
          terminal.shell.program = "${pkgs.fish}/bin/fish";
          window = {
            opacity = 0.5;
            padding = {
              x = 8;
              y = 8;
            };
          };
          font = {
            size = 11;
            normal.family = "JetBrainsMono Nerd Font";
          };
          colors = {
            primary = {
              inherit (palette) foreground background;
            };
            cursor = {
              text = palette.background;
              cursor = palette.foreground;
            };
            selection = {
              text = palette.background;
              background = palette.foreground;
            };
            inherit (palette) normal bright;
          };
        };
      };
    };
  };
}
