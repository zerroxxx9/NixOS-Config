{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: {
  options.modules.gui.alacritty = {
    enable = lib.mkEnableOption "alacritty";
  };

  config = lib.mkIf config.modules.gui.alacritty.enable {
    home-manager.users.${hostVariables.username} = {
      programs.alacritty = {
        enable = true;
        settings = {
          # Colours come from the matugen alacritty template, regenerated from
          # the wallpaper by set-wallpaper (see modules/gui/matugen.nix).
          general.import = ["~/.config/alacritty/themes/matugen.toml"];

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
            normal.family = "Geist Mono";
          };
        };
      };
    };
  };
}
