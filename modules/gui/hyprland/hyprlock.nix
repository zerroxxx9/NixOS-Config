{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  wallpaper = ../../../assets/wallpaper/zvetru.jpg;
  wallpaperPath = "${wallpaper}";
  radius = 8;
  stripHash = color: lib.removePrefix "#" color;
  hyprRgba = color: alpha: "rgba(${stripHash color}${alpha})";
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.hyprlock = {
        enable = true;
        settings = {
          background = [
            {
              path = wallpaperPath;
              blur_passes = 2;
              blur_size = 6;
              brightness = 0.58;
            }
          ];
          label = [
            {
              text = "$TIME";
              color = hyprRgba colors.fgBright "ff";
              font_size = 100;
              position = "0, 100";
              halign = "center";
              valign = "center";
            }
            {
              text = "cmd[update:60000] date +'%A, %d %B'";
              color = hyprRgba colors.muted "ff";
              font_size = 22;
              position = "0, 20";
              halign = "center";
              valign = "center";
            }
          ];
          input-field = [
            {
              size = "300, 52";
              position = "0, -70";
              halign = "center";
              valign = "center";
              outline_thickness = 2;
              outer_color = hyprRgba colors.fg "33";
              inner_color = hyprRgba colors.black "00";
              font_color = hyprRgba colors.fg "ff";
              fail_color = hyprRgba colors.accentRed "ff";
              rounding = 100;
              dots_center = true;
              dots_size = 0.4;
              dots_text_format = "*";
              animation = "fade, 1, 1.8, linear";
              blur_passes = 2;
              blur_size = 8;
            }
          ];
        };
      };
    };
  };
}
