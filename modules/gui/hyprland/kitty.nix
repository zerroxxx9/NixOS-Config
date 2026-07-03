{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.kitty = {
        enable = true;
        settings = {
          background = colors.black;
          foreground = colors.fg;
          cursor = colors.accentBlue;
          selection_background = colors.surface;
          selection_foreground = colors.fgBright;
          active_tab_background = colors.bg2;
          active_tab_foreground = colors.fgBright;
          inactive_tab_background = colors.bg1;
          inactive_tab_foreground = colors.muted;
          tab_bar_background = colors.black;
          tab_bar_style = "powerline";
          window_padding_width = 8;
          confirm_os_window_close = 0;
          color0 = colors.black;
          color1 = colors.accentRed;
          color2 = colors.green;
          color3 = colors.accentYellow;
          color4 = colors.accentBlue;
          color5 = colors.magenta;
          color6 = colors.cyan;
          color7 = colors.subtle;
          color8 = colors.bg2;
          color9 = colors.accentRed;
          color10 = colors.green;
          color11 = colors.accentYellow;
          color12 = colors.accentBlue;
          color13 = colors.magenta;
          color14 = colors.cyan;
          color15 = colors.fgBright;
        };
      };
    };
  };
}
