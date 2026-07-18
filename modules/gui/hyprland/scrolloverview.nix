{
  lib,
  pkgs,
  config,
  hostVariables,
  inputs,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  scrollOverview = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "scrolloverview";
    version = "0-unstable";
    src = inputs.hyprland-scroll-overview;

    nativeBuildInputs = with pkgs; [
      meson
      ninja
    ];

    buildInputs = with pkgs; [
      libdrm
      libinput
      libxkbcommon
      lua5_4
      pango
      pixman
      systemd
      wayland
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib
      install -Dm755 libscrolloverview.so $out/lib/libscrolloverview.so

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
      description = "Scrollable overview plugin for Hyprland";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
  };
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      wayland.windowManager.hyprland = {
        plugins = [
          scrollOverview
        ];
        settings = {
          plugin.scrolloverview = {
            gesture_distance = 300;
            scale = 0.5;
            workspace_gap = 100;
            layout = "horizontal";
            wallpaper = 0;
            blur = false;

            shadow = {
              enabled = false;
              range = 50;
              render_power = 3;
              color = "0xee1a1a1a";
            };
          };

          "scrolloverview-gesture" = "3, up, overview";
          bind = [
            "SUPER, G, scrolloverview:overview, toggle"
          ];
        };
      };
    };
  };
}
