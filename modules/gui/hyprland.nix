{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
in {
  options.modules.gui.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      dunst
      grim
      hyprpaper
      kitty
      rofi-wayland
      slurp
      waybar
      wl-clipboard
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        settings = {
          "$mod" = "SUPER";

          monitor = ",preferred,auto,1";

          exec-once = [
            "waybar"
            "hyprpaper"
          ];

          input = {
            kb_layout = "de";
            follow_mouse = 1;
            sensitivity = 0;
          };

          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            layout = "dwindle";
          };

          decoration = {
            rounding = 6;
          };

          bind = [
            "$mod, Return, exec, kitty"
            "$mod, D, exec, rofi -show drun"
            "$mod SHIFT, Q, killactive"
            "$mod, F, fullscreen"
            "$mod, V, togglefloating"
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod SHIFT, 1, movetoworkspace, 1"
            "$mod SHIFT, 2, movetoworkspace, 2"
            "$mod SHIFT, 3, movetoworkspace, 3"
            "$mod SHIFT, 4, movetoworkspace, 4"
            "$mod SHIFT, 5, movetoworkspace, 5"
          ];

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
        };
      };

      xdg.configFile."hypr/hyprpaper.conf".text = ''
        preload = /home/${hostVariables.username}/.dotfiles/assets/wallpaper/2.jpg
        wallpaper = ,/home/${hostVariables.username}/.dotfiles/assets/wallpaper/2.jpg
      '';
    };
  };
}
