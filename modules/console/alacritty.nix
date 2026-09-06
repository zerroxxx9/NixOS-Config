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
          # Colours come from Noctalia's alacritty template, regenerated from
          # the wallpaper (see modules/gui/theming.nix). The path is spelled
          # exactly as Noctalia's apply.sh would write it, so it finds the
          # import already present and leaves this read-only file alone.
          general.import = ["~/.config/alacritty/themes/noctalia.toml"];

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
        };
      };
    };
  };
}
