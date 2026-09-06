{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;

  inherit (lib.generators) mkLuaInline;

  monitors =
    lib.attrByPath ["hyprland" "monitors"] [
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      }
    ]
    hostVariables;

  mod = "SUPER";
  terminal = "alacritty";
  noctaliaEnabled = config.modules.gui.noctalia.enable;
  ipc = cmd: ''hl.dsp.exec_cmd("noctalia msg ${cmd}")'';

  mkBind = keys: dispatcher: {_args = [keys (mkLuaInline dispatcher)];};
  mkBindOpts = keys: dispatcher: opts: {_args = [keys (mkLuaInline dispatcher) opts];};

  locked = {locked = true;};
  lockedRepeat = {
    locked = true;
    repeating = true;
  };
  repeating = {repeating = true;};
  mouse = {mouse = true;};

  mediaBinds =
    if noctaliaEnabled
    then [
      (mkBindOpts "XF86AudioRaiseVolume" (ipc "volume-up") lockedRepeat)
      (mkBindOpts "XF86AudioLowerVolume" (ipc "volume-down") lockedRepeat)
      (mkBindOpts "XF86AudioMute" (ipc "volume-mute") locked)
      (mkBindOpts "XF86AudioMicMute" (ipc "mic-mute") locked)
      (mkBindOpts "XF86MonBrightnessUp" (ipc "brightness-up") lockedRepeat)
      (mkBindOpts "XF86MonBrightnessDown" (ipc "brightness-down") lockedRepeat)
      (mkBindOpts "XF86AudioNext" (ipc "media next") locked)
      (mkBindOpts "XF86AudioPrev" (ipc "media previous") locked)
      (mkBindOpts "XF86AudioPlay" (ipc "media toggle") locked)
      (mkBindOpts "XF86AudioPause" (ipc "media toggle") locked)
      (mkBindOpts "${mod} + SPACE" (ipc "media toggle") locked)
    ]
    else [
      (mkBindOpts "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")'' lockedRepeat)
      (mkBindOpts "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'' lockedRepeat)
      (mkBindOpts "XF86AudioMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'' locked)
      (mkBindOpts "XF86AudioMicMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'' locked)
      (mkBindOpts "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+")'' lockedRepeat)
      (mkBindOpts "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-")'' lockedRepeat)
      (mkBindOpts "XF86AudioNext" ''hl.dsp.exec_cmd("playerctl next")'' locked)
      (mkBindOpts "XF86AudioPrev" ''hl.dsp.exec_cmd("playerctl previous")'' locked)
      (mkBindOpts "XF86AudioPlay" ''hl.dsp.exec_cmd("playerctl play-pause")'' locked)
      (mkBindOpts "XF86AudioPause" ''hl.dsp.exec_cmd("playerctl play-pause")'' locked)
      (mkBindOpts "${mod} + SPACE" ''hl.dsp.exec_cmd("playerctl play-pause")'' locked)
    ];

  noctaliaBinds = lib.optionals noctaliaEnabled [
    (mkBindOpts "${mod} + Super_L" (ipc "panel-toggle launcher") {release = true;})
    (mkBindOpts "${mod} + Super_R" (ipc "panel-toggle launcher") {release = true;})
    (mkBind "${mod} + D" (ipc "panel-toggle launcher"))

    (mkBind "${mod} + C" (ipc "panel-toggle clipboard"))
    (mkBind "${mod} + W" (ipc "panel-toggle wallpaper"))
    (mkBind "${mod} + SHIFT + W" (ipc "wallpaper-random"))
    (mkBind "${mod} + S" (ipc "panel-toggle control-center"))
    (mkBind "${mod} + N" (ipc "panel-toggle control-center"))
    (mkBind "${mod} + Q" (ipc "panel-toggle control-center media"))
    (mkBind "${mod} + SHIFT + S" (ipc "settings-toggle"))
    (mkBind "ALT + TAB" (ipc "window-switcher"))

    (mkBindOpts "${mod} + L" (ipc "lock") locked)
    (mkBindOpts "XF86PowerOff" (ipc "lock") locked)

    (mkBindOpts "Insert" (ipc "screenshot-region") locked)
    (mkBindOpts "${mod} + Insert" (ipc "screenshot-fullscreen") locked)
  ];

  noctaliaRules = lib.optionals noctaliaEnabled [
    {
      name = "noctalia";
      match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
      no_anim = true;
      ignore_alpha = 0.5;
      blur = true;
      blur_popups = true;
    }
  ];

  noctaliaWindowRules = lib.optionals noctaliaEnabled [
    {
      name = "noctalia-settings";
      match.class = "dev.noctalia.Noctalia";
      float = true;
      size = [1080 920];
    }
  ];

  persistentWorkspaces = lib.optionals noctaliaEnabled (
    map (i: {
      workspace = toString i;
      persistent = true;
    }) (lib.range 1 5)
  );

  workspaceBinds = lib.concatMap (i: let
    key =
      if i == 10
      then "0"
      else toString i;
  in [
    (mkBind "${mod} + ${key}" "hl.dsp.focus({ workspace = ${toString i} })")
    (mkBind "${mod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${toString i} })")
  ]) (lib.range 1 10);

  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    size = "standard";
    tweaks = ["normal"];
    variant = "mocha";
  };
  catppuccinThemeName = "catppuccin-mocha-blue-standard+normal";

  # Colour definitions come from Noctalia's gtk templates, regenerated on
  # every palette change. Must stay first: GTK ignores @import once any other
  # rule has been seen.
  gtkFileManagerCss = ''
    ${lib.optionalString config.modules.gui.theming.enable ''
      @import url("noctalia.css");
    ''}
    window,
    dialog,
    filechooser,
    placessidebar,
    .nautilus-window {
      background-color: @window_bg_color;
      color: @window_fg_color;
    }

    headerbar,
    .titlebar {
      background-color: @headerbar_bg_color;
      color: @headerbar_fg_color;
      box-shadow: none;
      border-bottom: 1px solid alpha(#45475a, 0.65);
    }

    placessidebar,
    .sidebar {
      background-color: @sidebar_bg_color;
      color: @sidebar_fg_color;
    }

    placessidebar row {
      border-radius: 8px;
    }

    placessidebar row:selected {
      background-color: alpha(@accent_bg_color, 0.24);
      color: @window_fg_color;
    }

    pathbar button,
    button.path-bar,
    button.flat {
      border-radius: 8px;
    }

    button.suggested-action,
    button.default {
      background: @accent_bg_color;
      color: @accent_fg_color;
    }

    entry,
    searchbar,
    .view {
      background-color: @view_bg_color;
      color: @view_fg_color;
    }
  '';
in {
  options.modules.gui.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    services.displayManager.gdm.enable = lib.mkDefault true;
    services.displayManager.defaultSession = lib.mkDefault "hyprland";

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      bibata-cursors
      bluez
      brightnessctl
      curl
      ffmpeg
      gnome-console
      gpu-screen-recorder
      imagemagick
      iw
      jq
      libnotify
      lm_sensors
      playerctl
      socat
      wl-screenrec
      wl-clipboard
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    modules.gui.alacritty.enable = lib.mkDefault true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {lib, ...}: {
      wayland.systemd.target = "hyprland-session.target";

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        configType = "lua";

        # Border colours follow the wallpaper. Noctalia renders
        # ~/.config/hypr/noctalia.lua and, finding this require already
        # present, leaves the read-only hyprland.lua alone. pcall keeps a
        # missing module (fresh machine, before the first palette) from
        # taking the whole config down; the static col values above are the
        # fallback until then.
        extraConfig = ''
          pcall(function()
            require("noctalia").apply_theme()
          end)
        '';

        settings = {
          monitor = monitors;

          env = [
            {_args = ["XCURSOR_THEME" "Bibata-Modern-Ice"];}
            {_args = ["XCURSOR_SIZE" "24"];}
            {_args = ["HYPRCURSOR_THEME" "Bibata-Modern-Ice"];}
            {_args = ["HYPRCURSOR_SIZE" "24"];}
          ];

          config = {
            general = {
              border_size = 1;
              gaps_in = 4;
              gaps_out = 4;
              float_gaps = 6;
              resize_on_border = true;
              extend_border_grab_area = 30;
              layout = "dwindle";
              col = {
                active_border = "rgba(5c98cdee)";
                inactive_border = "rgba(2f3943aa)";
              };
            };

            decoration = {
              rounding = 8;
              rounding_power = 2;
              active_opacity = 1.0;
              inactive_opacity = 1.0;

              blur = {
                enabled = true;
                size = 8;
                passes = 2;
                new_optimizations = true;
              };

              shadow.enabled = false;
            };

            input = {
              kb_layout = "de";
              kb_variant = "";
              kb_model = "";
              kb_options = "";
              kb_rules = "";
              follow_mouse = 1;
              accel_profile = "flat";
              touchpad.natural_scroll = true;
            };

            misc = {
              focus_on_activate = true;
              font_family = "JetBrains Mono";
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              force_default_wallpaper = 0;
            };

            animations.enabled = true;
            dwindle.preserve_split = true;
          };

          curve = {
            _args = [
              "myBezier"
              {
                type = "bezier";
                points = [
                  [0.05 0.9]
                  [0.1 1.05]
                ];
              }
            ];
          };

          animation = [
            {
              leaf = "windows";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
              style = "popin 80%";
            }
            {
              leaf = "windowsOut";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
              style = "popin 80%";
            }
            {
              leaf = "layers";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
              style = "fade";
            }
            {
              leaf = "layersIn";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
              style = "fade";
            }
            {
              leaf = "layersOut";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
              style = "fade";
            }
            {
              leaf = "fade";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
            }
            {
              leaf = "workspaces";
              enabled = true;
              speed = 5;
              bezier = "myBezier";
              style = "slide";
            }
          ];

          gesture = {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          };

          bind =
            [
              # Applications
              (mkBind "${mod} + T" "hl.dsp.exec_cmd(\"${terminal}\")")
              (mkBind "${mod} + F" "hl.dsp.exec_cmd(\"brave\")")
              (mkBind "${mod} + E" "hl.dsp.exec_cmd(\"nautilus\")")

              # Window management
              (mkBind "ALT + F4" "hl.dsp.window.close()")
              (mkBind "${mod} + SHIFT + F" "hl.dsp.window.float({ action = \"toggle\" })")
              (mkBind "${mod} + left" "hl.dsp.focus({ direction = \"left\" })")
              (mkBind "${mod} + right" "hl.dsp.focus({ direction = \"right\" })")
              (mkBind "${mod} + up" "hl.dsp.focus({ direction = \"up\" })")
              (mkBind "${mod} + down" "hl.dsp.focus({ direction = \"down\" })")
              (mkBind "${mod} + CTRL + left" "hl.dsp.window.move({ direction = \"left\" })")
              (mkBind "${mod} + CTRL + right" "hl.dsp.window.move({ direction = \"right\" })")
              (mkBind "${mod} + CTRL + up" "hl.dsp.window.move({ direction = \"up\" })")
              (mkBind "${mod} + CTRL + down" "hl.dsp.window.move({ direction = \"down\" })")

              (mkBindOpts "${mod} + SHIFT + left" "hl.dsp.window.resize({ x = -50, y = 0, relative = true })" repeating)
              (mkBindOpts "${mod} + SHIFT + right" "hl.dsp.window.resize({ x = 50, y = 0, relative = true })" repeating)
              (mkBindOpts "${mod} + SHIFT + up" "hl.dsp.window.resize({ x = 0, y = -50, relative = true })" repeating)
              (mkBindOpts "${mod} + SHIFT + down" "hl.dsp.window.resize({ x = 0, y = 50, relative = true })" repeating)

              # Mouse
              (mkBindOpts "${mod} + mouse:272" "hl.dsp.window.drag()" mouse)
              (mkBindOpts "${mod} + mouse:273" "hl.dsp.window.resize()" mouse)
            ]
            ++ workspaceBinds
            ++ mediaBinds
            ++ noctaliaBinds;

          layer_rule = noctaliaRules;

          workspace_rule = persistentWorkspaces;

          window_rule =
            [
              {
                name = "cs2-immediate";
                match.class = "^(cs2)$";
                immediate = true;
                keep_aspect_ratio = true;
              }
            ]
            ++ noctaliaWindowRules;
        };
      };

      home.packages = with pkgs; [
        acpi
        alsa-utils
        bc
        catppuccinGtk
        fd
        gtk3
        pamixer
        pavucontrol
        papirus-icon-theme
        ripgrep
        tree
      ];

      gtk = {
        enable = true;
        theme = {
          package = lib.mkDefault catppuccinGtk;
          name = lib.mkDefault catppuccinThemeName;
        };
        iconTheme = {
          package = lib.mkDefault pkgs.papirus-icon-theme;
          name = lib.mkDefault "Papirus-Dark";
        };
        gtk3.extraCss = lib.mkDefault gtkFileManagerCss;
        gtk4.extraCss = lib.mkDefault gtkFileManagerCss;
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = lib.mkDefault "prefer-dark";
          gtk-theme = lib.mkDefault catppuccinThemeName;
          icon-theme = lib.mkDefault "Papirus-Dark";
        };
        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = lib.mkDefault true;
          sort-directories-first = lib.mkDefault true;
          view-type = lib.mkDefault "list";
        };
        "org/gtk/settings/file-chooser" = {
          show-hidden = lib.mkDefault true;
          sort-directories-first = lib.mkDefault true;
        };
        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = lib.mkDefault "list-view";
          migrated-gtk-settings = lib.mkDefault true;
          search-filter-time-type = lib.mkDefault "last_modified";
          show-create-link = lib.mkDefault true;
        };
        "org/gnome/nautilus/list-view" = {
          default-visible-columns = lib.mkDefault [
            "name"
            "size"
            "type"
            "date_modified"
          ];
          default-zoom-level = lib.mkDefault "small";
        };
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

      services.easyeffects.enable = true;
    };
  };
}
