{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  radius = 8;
  hexDigit = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    a = 10;
    b = 11;
    c = 12;
    d = 13;
    e = 14;
    f = 15;
  };
  hexPairToInt = pair: (hexDigit.${builtins.substring 0 1 pair} * 16) + hexDigit.${builtins.substring 1 1 pair};
  rgbComponent = color: offset: hexPairToInt (builtins.substring offset 2 (lib.removePrefix "#" color));
  gtkRgba = color: alpha: "rgba(${toString (rgbComponent color 0)}, ${toString (rgbComponent color 2)}, ${toString (rgbComponent color 4)}, ${alpha})";
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.wofi = {
        enable = true;
        settings = {
          show = "drun";
          allow_images = true;
          insensitive = true;
          width = 560;
          height = 420;
          prompt = "";
        };
        style = ''
          * {
            font-family: "Inter", "DejaVu Sans", sans-serif;
            font-size: 14px;
            color: ${colors.fg};
          }

          window,
          #window {
            background-color: ${gtkRgba colors.bg1 "0.72"};
            border: 1px solid ${colors.surface};
            border-radius: ${toString radius}px;
          }

          #outer-box,
          #inner-box,
          #scroll {
            background-color: transparent;
          }

          #input {
            background-color: ${gtkRgba colors.bg2 "0.78"};
            color: ${colors.fg};
            border: 1px solid ${colors.accentBlue};
            border-radius: ${toString radius}px;
            margin-top: 35px;
            margin-left: 35px;
            margin-right: 35px;
            margin-bottom: 10px;
            padding: 8px 10px;
          }

          #inner-box {
            margin: 5px 35px 35px;
          }

          #entry {
            background-color: transparent;
            border-left: 3px solid transparent;
            border-radius: ${toString radius}px;
            padding: 8px;
          }

          #entry:selected {
            background-color: ${gtkRgba colors.surface "0.78"};
            border-left-color: ${colors.accentBlue};
          }

          #entry:selected #text {
            color: ${colors.fgBright};
          }

          #text {
            color: ${colors.fg};
          }
        '';
      };
    };
  };
}
