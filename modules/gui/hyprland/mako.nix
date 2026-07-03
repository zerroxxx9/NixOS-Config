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
      services.mako = {
        enable = true;
        settings = {
          background-color = hexA colors.bg2 "f2";
          text-color = colors.fg;
          border-color = colors.accentBlue;
          border-size = 1;
          border-radius = radius;
          padding = "10,12";
          margin = "10";
          default-timeout = 6000;
          "urgency=low" = {
            background-color = hexA colors.bg2 "cc";
            text-color = colors.muted;
            border-color = colors.overlay;
          };
          "urgency=critical" = {
            text-color = colors.fgBright;
            border-color = colors.accentRed;
            default-timeout = 0;
          };
        };
      };
    };
  };
}
