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

            start = ["launcher" "wallpaper" "workspaces" "active_window"];
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

          # Colours follow the wallpaper. `Urban` stays defined above as a
          # fallback, selectable from Settings -> Color Scheme at any time.
          theme = {
            mode = "dark";
            source = "wallpaper";
            wallpaper_scheme = "m3-content";
            custom_palette = "Urban";
            pure_black_dark = false;
          };

          # Every app that follows the wallpaper is driven from here. Built-ins
          # ship with Noctalia; community templates are fetched once from
          # api.noctalia.dev and cached; user templates live in
          # modules/gui/theming.nix.
          theme.templates = {
            enable_builtin_templates = true;
            builtin_ids = [
              "alacritty"
              "gtk3"
              "gtk4"
              "qt"
              "hyprland"
            ];
            enable_community_templates = true;
            community_ids = [
              "discord"
              "obsidian"
              "vscode"
              "zed"
              "zellij"
            ];
            user = config.modules.gui.theming.userTemplates;
          };

          wallpaper = {
            enabled = true;
            fill_mode = "crop";
            directory = "${homeDir}/.dotfiles/assets/wallpaper";
            default.path = "${homeDir}/.dotfiles/assets/wallpaper/1756527463892669.jpg";
          };

          # Backdrop: the desktop wallpaper, blurred hard so the clock and the
          # password row are the only things with edges.
          lockscreen = {
            enabled = true;
            blurred_desktop = false;
            blur_intensity = 0.8;
            tint_intensity = 0.15;
          };

          # Widgets are placed on DP-1 only; DP-2 shows the blurred backdrop
          # with no chrome. Boxes are in DP-1 logical pixels (3840x2160 @ 1x)
          # and a widget scales its content to fill its box.
          lockscreen_widgets = {
            enabled = true;

            widget = {
              lock_clock = {
                type = "clock";
                output = "DP-1";
                cx = 1920.0;
                cy = 800.0;
                box_width = 1200.0;
                box_height = 240.0;
                rotation = 0.0;
                settings = {
                  clock_style = "digital";
                  format = "{:%H:%M}";
                  center_text = true;
                  color = "on_surface";
                  shadow = true;
                  background = false;
                };
              };

              lock_date = {
                type = "clock";
                output = "DP-1";
                cx = 1920.0;
                cy = 985.0;
                box_width = 1100.0;
                box_height = 80.0;
                rotation = 0.0;
                settings = {
                  clock_style = "digital";
                  format = "{:%A, %-d %B}";
                  center_text = true;
                  color = "on_surface_variant";
                  shadow = true;
                  background = false;
                };
              };

              # Fixed id; noctalia auto-creates one login box per output, so
              # both are declared here to keep placement and visibility ours.
              "lockscreen-login-box@DP-1" = {
                type = "login_box";
                output = "DP-1";
                enabled = true;
                cx = 1920.0;
                cy = 1230.0;
                box_width = 560.0;
                box_height = 70.0;
                settings = {
                  layout = "compact";
                  show_login_button = true;
                  show_unlock_hint = true;
                  show_caps_lock = true;
                  show_keyboard_layout = false;
                  center_password_text = true;
                  background_color = "surface_variant";
                  background_opacity = 0.55;
                  background_radius = 18.0;
                  input_opacity = 0.85;
                  input_radius = 12.0;
                };
              };

              "lockscreen-login-box@DP-2" = {
                type = "login_box";
                output = "DP-2";
                enabled = false;
                cx = 1280.0;
                cy = 1200.0;
                box_width = 560.0;
                box_height = 70.0;
              };
            };
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
