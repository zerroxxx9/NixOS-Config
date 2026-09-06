{
  lib,
  config,
  hostVariables,
  inputs,
  ...
}: let
  cfg = config.modules.gui.noctalia;
  noctaliaPackage = inputs.noctalia.packages.${hostVariables.system}.default;
  homeDir = "/home/${hostVariables.username}";
  palette = import ./palette.nix;
in {
  options.modules.gui.noctalia = {
    enable = lib.mkEnableOption "noctalia";
  };
  imports = [inputs.noctalia.nixosModules.default];

  config = lib.mkIf cfg.enable {
    nix.settings = {
      extra-substituters = ["https://noctalia.cachix.org"];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };

    programs.noctalia = {
      enable = true;
      package = noctaliaPackage;
      recommendedServices.enable = true;
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {
      imports = [inputs.noctalia.homeModules.default];

      programs.noctalia = {
        enable = true;
        package = noctaliaPackage;
        systemd.enable = true;
        checkConfig = true;

        customPalettes.Urban = {
          dark =
            palette.roles
            // {
              terminal = palette.terminal;
            };
        };

        settings = {
          shell = {
            font_family = "JetBrains Mono";
            settings_show_advanced = true;
            polkit_agent = true;
            clipboard_enabled = true;
            clipboard_history_max_entries = 100;
            launch_apps_as_systemd_services = true;

            panel.transparency_mode = "soft";

            animation = {
              enabled = true;
              speed = 1.0;
            };
            screen_corners = {
              enabled = true;
              size = 32;
            };
          };

          bar.main = {
            position = "top";
            thickness = 34;
            reserve_space = true;
            radius = 0;
            margin_ends = 0;
            margin_edge = 0;
            background_opacity = 0.85;
            concave_edge_corners = true;
            capsule = true;
            capsule_fill = "surface_variant";
            capsule_opacity = 0.9;
            capsule_padding = 8.0;
            widget_spacing = 6;

            start = ["launcher" "workspaces" "active_window"];
            center = ["clock" "group:nowplaying"];
            end = [
              "group:tray"
              "notifications"
              "clipboard"
              "network"
              "volume"
              "brightness"
              "control-center"
              "session"
            ];
            capsule_group = [
              {
                id = "nowplaying";
                members = ["media" "audio_visualizer"];
                fill = "surface_variant";
                padding = 8.0;
                opacity = 0.9;
                widget_spacing = 8;
              }
              {
                id = "tray";
                members = ["tray" "bluetooth"];
                fill = "surface_variant";
                padding = 8.0;
                opacity = 0.9;
                accordion = true;
                accordion_direction = "end";
              }
            ];
          };
          widget = {
            workspaces = {
              type = "workspaces";
              style = "focus_hint";
              show_icons = true;
              label_source = "id";
            };

            active_window = {
              type = "active_window";
              display = "icon_and_text";
              max_length = 200.0;
              title_scroll = "on_hover";
            };

            media = {
              type = "media";
              art_size = 16.0;
              max_length = 220.0;
              title_scroll = "on_hover";
              hide_when_no_media = true;
            };

            audio_visualizer = {
              type = "audio_visualizer";
              width = 56;
              bands = 16;
              mirrored = true;
              centered = true;
              show_when_idle = false;
              color_1 = "primary";
              color_2 = "secondary";
            };
          };

          dock = {
            enabled = true;
            position = "bottom";

            icon_size = 32;
            item_spacing = 8;
            main_axis_padding = 10;
            cross_axis_padding = 8;
            radius = 18;
            margin_edge = 6;
            margin_ends = 0;
            concave_edge_corners = false;
            background_opacity = 0.85;
            shadow = true;

            magnification = true;
            magnification_scale = 1.45;
            show_running = true;
            show_dots = true;
            show_instance_count = true;
            reserve_space = true;

            pinned = [
              "brave-browser"
              "vesktop"
              "Alacritty"
              "code"
              "dev.zed.Zed"
              "obsidian"
              "org.gnome.Nautilus"
              "spotify"
              "steam"
            ];
          };

          theme = {
            mode = "dark";
            source = "custom";
            custom_palette = "Urban";
            pure_black_dark = false;
          };
          theme.templates = {
            enable_builtin_templates = false;
            builtin_ids = [];
            enable_community_templates = false;
            community_ids = [];
          };

          wallpaper = {
            enabled = true;
            fill_mode = "crop";
            directory = "${homeDir}/.dotfiles/assets/wallpaper";
            default.path = "${homeDir}/.dotfiles/assets/wallpaper/1756527463892669.jpg";
          };
          idle.behavior = {
            lock = {
              enabled = true;
              timeout = 300;
              action = "lock";
            };
            "screen-off" = {
              enabled = true;
              timeout = 660;
              action = "screen_off";
            };
          };

          notification.enable_daemon = true;
          osd.position = "top_right";
        };
      };
    };
  };
}
