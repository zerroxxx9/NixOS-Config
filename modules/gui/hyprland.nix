{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  wallpaper = ../../assets/wallpaper/zvetru.jpg;
  wallpaperPath = "${wallpaper}";
  radius = 8;
  stripHash = color: lib.removePrefix "#" color;
  hyprRgb = color: "rgb(${stripHash color})";
  hyprRgba = color: alpha: "rgba(${stripHash color}${alpha})";
  hexA = color: alpha: "${color}${alpha}";
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
  options.modules.gui.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    services.displayManager.gdm = {
      enable = lib.mkDefault true;
    };
    services.displayManager.defaultSession = lib.mkDefault "hyprland";

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WALLPAPER = wallpaperPath;
    };

    environment.systemPackages = with pkgs; [
      bibata-cursors
      brightnessctl
      cliphist
      grim
      hypridle
      hyprlock
      hyprpaper
      kitty
      libnotify
      mako
      networkmanagerapplet
      pamixer
      pavucontrol
      playerctl
      slurp
      waybar
      wl-clipboard
      wofi
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {lib, ...}: {
      home.packages = with pkgs; [
        acpi
        alsa-utils
        bibata-cursors
        papirus-icon-theme
      ];

      home.sessionVariables = {
        WALLPAPER = wallpaperPath;
      };

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
            kb_layout = "us";
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

      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 34;
          spacing = 8;
          modules-left = ["hyprland/workspaces"];
          modules-center = ["clock"];
          modules-right = ["tray" "network" "pulseaudio" "battery"];
          "hyprland/workspaces" = {
            format = "{icon}";
            persistent-workspaces."*" = 5;
          };
          clock = {
            format = "{:%a %d %b  %H:%M}";
            tooltip-format = "{:%A, %d %B %Y}";
          };
          network = {
            format-wifi = "{essid}";
            format-ethernet = "wired";
            format-disconnected = "offline";
            tooltip-format = "{ifname}: {ipaddr}";
          };
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "muted";
            format-icons.default = ["vol"];
            on-click = "pavucontrol";
          };
          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}%";
            format-charging = "{capacity}%";
          };
          tray = {
            icon-size = 16;
            spacing = 8;
          };
        };
        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: "Inter", "DejaVu Sans", sans-serif;
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background: ${colors.bg1};
            color: ${colors.fg};
            border-bottom: 1px solid ${colors.surface};
          }

          #workspaces button {
            color: ${colors.muted};
            background: transparent;
            padding: 0 10px;
            margin: 5px 1px 4px;
            border-radius: ${toString radius}px;
            border-bottom: 2px solid transparent;
          }

          #workspaces button.active {
            color: ${colors.fgBright};
            background: ${colors.bg2};
            border-bottom-color: ${colors.accentBlue};
          }

          #workspaces button.urgent {
            color: ${colors.fgBright};
            background: ${colors.accentRed};
          }

          #clock,
          #battery,
          #network,
          #pulseaudio,
          #tray {
            color: ${colors.fg};
            background: ${colors.bg2};
            margin: 5px 0 4px;
            padding: 0 10px;
            border-radius: ${toString radius}px;
          }

          #clock {
            color: ${colors.fgBright};
            background: ${colors.surface};
          }

          #battery.warning {
            color: ${colors.accentYellow};
          }

          #battery.critical {
            color: ${colors.fgBright};
            background: ${colors.accentRed};
          }

          #network.disconnected {
            color: ${colors.accentRed};
          }

          #pulseaudio.muted {
            color: ${colors.overlay};
          }

          #tray > .needs-attention {
            color: ${colors.accentRed};
          }
        '';
      };

      programs.kitty = {
        enable = true;
        settings = {
          background = colors.black;
          foreground = colors.fg;
          cursor = colors.accentBlue;
          selection_background = colors.surface;
          selection_foreground = colors.fgBright;
          active_tab_background = colors.bg2;
          active_tab_foreground = colors.fgBright;
          inactive_tab_background = colors.bg1;
          inactive_tab_foreground = colors.muted;
          tab_bar_background = colors.black;
          tab_bar_style = "powerline";
          window_padding_width = 8;
          confirm_os_window_close = 0;
          color0 = colors.black;
          color1 = colors.accentRed;
          color2 = colors.green;
          color3 = colors.accentYellow;
          color4 = colors.accentBlue;
          color5 = colors.magenta;
          color6 = colors.cyan;
          color7 = colors.subtle;
          color8 = colors.bg2;
          color9 = colors.accentRed;
          color10 = colors.green;
          color11 = colors.accentYellow;
          color12 = colors.accentBlue;
          color13 = colors.magenta;
          color14 = colors.cyan;
          color15 = colors.fgBright;
        };
      };

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
              font_size = 72;
              position = "0, 80";
              halign = "center";
              valign = "center";
            }
            {
              text = "cmd[update:60000] date +'%A, %d %B'";
              color = hyprRgba colors.muted "ff";
              font_size = 18;
              position = "0, 20";
              halign = "center";
              valign = "center";
            }
          ];
          input-field = [
            {
              size = "280, 48";
              position = "0, -70";
              halign = "center";
              valign = "center";
              outer_color = hyprRgba colors.accentBlue "ff";
              inner_color = hyprRgba colors.bg2 "e6";
              font_color = hyprRgba colors.fg "ff";
              fail_color = hyprRgba colors.accentRed "ff";
              placeholder_text = "<span foreground='${colors.subtle}'>Password</span>";
              rounding = radius;
            }
          ];
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 420;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };

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

      gtk = {
        enable = true;
        theme = {
          package = lib.mkDefault pkgs.adw-gtk3;
          name = lib.mkDefault "adw-gtk3-dark";
        };
        iconTheme = {
          package = lib.mkDefault pkgs.papirus-icon-theme;
          name = lib.mkDefault "Papirus-Dark";
        };
        gtk3.extraCss = lib.mkDefault ''
          @define-color accent_color ${colors.accentBlue};
          @define-color window_bg_color ${colors.bg1};
          @define-color window_fg_color ${colors.fg};
          @define-color view_bg_color ${colors.bg2};
          @define-color view_fg_color ${colors.fg};
          @define-color headerbar_bg_color ${colors.bg1};
          @define-color headerbar_fg_color ${colors.fgBright};
        '';
        gtk4.extraCss = lib.mkDefault ''
          @define-color accent_color ${colors.accentBlue};
          @define-color window_bg_color ${colors.bg1};
          @define-color window_fg_color ${colors.fg};
          @define-color view_bg_color ${colors.bg2};
          @define-color view_fg_color ${colors.fg};
          @define-color headerbar_bg_color ${colors.bg1};
          @define-color headerbar_fg_color ${colors.fgBright};
        '';
      };

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = lib.mkDefault "prefer-dark";
        gtk-theme = lib.mkDefault "adw-gtk3-dark";
        icon-theme = lib.mkDefault "Papirus-Dark";
        cursor-theme = lib.mkDefault "Bibata-Modern-Ice";
      };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      services.gnome-keyring = {
        enable = true;
        components = ["secrets"];
      };

      xdg.configFile."hypr/source-wallpaper.jpg".source = wallpaper;
    };
  };
}
