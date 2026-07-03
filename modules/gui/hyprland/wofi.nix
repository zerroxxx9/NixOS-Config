{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  radius = 8;
  hexA = color: alpha: "${color}${alpha}";
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

          window {
            background: ${hexA colors.bg1 "e6"};
            border: 1px solid ${colors.surface};
            border-radius: ${toString radius}px;
          }

          #input {
            background: ${colors.bg2};
            color: ${colors.fg};
            border: 1px solid ${colors.accentBlue};
            border-radius: ${toString radius}px;
            margin: 12px;
            padding: 8px 10px;
          }

          #inner-box {
            margin: 0 12px 12px;
          }

          #entry {
            background: transparent;
            border-left: 3px solid transparent;
            border-radius: ${toString radius}px;
            padding: 8px;
          }

          #entry:selected {
            background: ${colors.surface};
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
