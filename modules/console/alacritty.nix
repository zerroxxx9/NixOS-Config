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
              foreground = "#f8f8f2";
              background = "#2b3e50";
            };
            cursor = {
              text = "#2b3e50";
              cursor = "#f8f8f2";
            };
            selection = {
              text = "#2b3e50";
              background = "#f8f8f2";
            };
            normal = {
              black = "#19242f";
              red = "#e94b35";
              green = "#199c4b";
              yellow = "#f0cc04";
              blue = "#5c98cd";
              magenta = "#ca94ff";
              cyan = "#8be0fd";
              white = "#f8f8f2";
            };
            bright = {
              black = "#2f3943";
              red = "#ff6541";
              green = "#72cc5a";
              yellow = "#ffffa5";
              blue = "#d6acff";
              magenta = "#d4a9ff";
              cyan = "#b9ecfd";
              white = "#ffffff";
            };
          };
        };
      };
    };
  };
}
