{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  wallpaper = ../../../assets/wallpaper/zvetru.jpg;
  wallpaperPath = "${wallpaper}";
  setHyprpaperWallpapers = pkgs.writeShellApplication {
    name = "set-hyprpaper-wallpapers";
    runtimeInputs = [pkgs.hyprland];
    text = ''
      sleep 0.5
      hyprctl hyprpaper wallpaper "DP-1,${wallpaperPath}" || true
      hyprctl hyprpaper wallpaper "DP-2,${wallpaperPath}" || true
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      services.hyprpaper = {
        enable = true;
        settings = {
          preload = [wallpaperPath];
          wallpaper = [
            "DP-1,${wallpaperPath}"
            "DP-2,${wallpaperPath}"
          ];
          splash = false;
        };
      };
      systemd.user.services.hyprpaper.Service.ExecStartPost = "${lib.getExe setHyprpaperWallpapers}";
    };
  };
}
