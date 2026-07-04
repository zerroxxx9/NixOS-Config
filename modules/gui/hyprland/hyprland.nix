{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  radius = 8;
  stripHash = color: lib.removePrefix "#" color;
  hyprRgb = color: "rgb(${stripHash color})";
  hyprRgba = color: alpha: "rgba(${stripHash color}${alpha})";
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "hyprlang";
        systemd.enable = true;
        settings = {
          monitor = [",preferred,auto,1"];
          exec-once = [
            "mako"
          ];
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "${hyprRgb colors.accentBlue} ${hyprRgb colors.muted} 45deg";
            "col.inactive_border" = hyprRgb colors.bg2;
            resize_on_border = true;
            layout = "dwindle";
          };
          group = {
            "col.border_active" = "${hyprRgb colors.accentRed} ${hyprRgb colors.accentBlue} 45deg";
            "col.border_inactive" = hyprRgb colors.overlay;
          };
          decoration = {
            rounding = radius;
            active_opacity = 0.96;
            inactive_opacity = 0.92;
            shadow = {
              enabled = true;
              range = 18;
              render_power = 3;
              color = hyprRgba colors.black "99";
            };
            blur = {
              enabled = true;
              size = 6;
              passes = 2;
              vibrancy = 0.12;
            };
          };
          animations = {
            enabled = true;
            bezier = ["easeOut,0.16,1,0.3,1"];
            animation = [
              "windows,1,3,easeOut,popin 85%"
              "border,1,4,easeOut"
              "fade,1,3,easeOut"
              "workspaces,1,4,easeOut,slide"
            ];
          };
          misc = {
            background_color = hyprRgb colors.black;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };
          dwindle = {
            preserve_split = true;
          };
          input = {
            kb_layout = "de";
            follow_mouse = 1;
            touchpad.natural_scroll = true;
          };
          bind = [
            "SUPER, Return, exec, kitty"
            "SUPER, D, exec, wofi --show drun"
            "SUPER, Q, killactive"
            "SUPER, F, fullscreen"
            "SUPER SHIFT, L, exec, hyprlock"
          ];
        };
      };
    };
  };
}
