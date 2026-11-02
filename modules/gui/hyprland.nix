{
  pkgs,
  lib,
  config,
  hostVariables,
  inputs,
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

  # Disables the laptop panel while any docking-station output is present,
  # and re-enables it otherwise. Hyprland's declarative `monitor` block only
  # runs once at config load, so this watches socket2 for monitoradded/
  # monitorremoved and re-applies the state live via `hyprctl eval`.
  dockDisplay = lib.attrByPath ["hyprland" "dockDisplay"] null hostVariables;
  synchronizedWorkspaces = lib.attrByPath ["hyprland" "synchronizedWorkspaces"] null hostVariables;
  kbLayout = lib.attrByPath ["hyprland" "kbLayout"] "de" hostVariables;

  dockDisplayScript =
    if dockDisplay == null
    then null
    else
      pkgs.writeShellScript "hypr-dock-display" ''
        set -euo pipefail

        laptop_output=${lib.escapeShellArg dockDisplay.laptop}
        dock_outputs=(${lib.concatMapStringsSep " " lib.escapeShellArg dockDisplay.dockOutputs})

        dock_connected() {
          local names
          names=$(hyprctl monitors -j | jq -r '.[].name')
          for output in "''${dock_outputs[@]}"; do
            if grep -qx "$output" <<<"$names"; then
              return 0
            fi
          done
          return 1
        }

        apply_state() {
          if dock_connected; then
            hyprctl eval "hl.monitor({ output = \"$laptop_output\", disabled = true })" >/dev/null
          else
            hyprctl eval "hl.monitor({ output = \"$laptop_output\", mode = \"preferred\", position = \"auto\", scale = 1 })" >/dev/null
          fi
        }

        apply_state

        socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        socat -U UNIX-CONNECT:"$socket" - | while read -r line; do
          case "$line" in
          monitoraddedv2* | monitorremovedv2*)
            apply_state
            ;;
          esac
        done
      '';

  synchronizedWorkspaceScript =
    if synchronizedWorkspaces == null
    then null
    else
      pkgs.writeShellScript "hypr-synchronized-workspace" ''
        set -euo pipefail

        mode="''${1:?expected switch or move}"
        number="''${2:?expected workspace number}"
        left=${lib.escapeShellArg synchronizedWorkspaces.left}
        right=${lib.escapeShellArg synchronizedWorkspaces.right}
        count=${toString synchronizedWorkspaces.count}
        current=$(hyprctl activeworkspace -j | jq -r '.monitor')

        case "$mode" in
          migrate)
            hyprctl workspaces -j |
              jq -r --argjson count "$count" '
                .[]
                | select(.name | test("^[0-9]+$"))
                | select((.name | tonumber) <= $count)
                | [.name, .monitor]
                | @tsv
              ' |
              while IFS=$'\t' read -r workspace monitor; do
                case "$monitor" in
                  "$left")
                    target="name:$workspace-left"
                    ;;
                  "$right")
                    target="name:$workspace-right"
                    ;;
                  *)
                    continue
                    ;;
                esac

                hyprctl clients -j |
                  jq -r --arg workspace "$workspace" '.[] | select(.workspace.name == $workspace) | .address' |
                  while read -r address; do
                    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$target\", silent = true, window = \"address:$address\" })" >/dev/null
                  done
              done
            ;;
          switch)
            "$0" migrate
            hyprctl dispatch "hl.dsp.focus({ monitor = \"$left\" })" >/dev/null
            hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$number-left\" })" >/dev/null
            hyprctl dispatch "hl.dsp.focus({ monitor = \"$right\" })" >/dev/null
            hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$number-right\" })" >/dev/null
            hyprctl dispatch "hl.dsp.focus({ monitor = \"$current\" })" >/dev/null
            ;;
          move)
            case "$current" in
              "$left")
                target="name:$number-left"
                ;;
              "$right")
                target="name:$number-right"
                ;;
              *)
                hyprctl dispatch "hl.dsp.window.move({ workspace = $number, silent = true })" >/dev/null
                "$0" switch "$number"
                exit
                ;;
            esac
            hyprctl dispatch "hl.dsp.window.move({ workspace = \"$target\", silent = true })" >/dev/null
            "$0" switch "$number"
            ;;
          *)
            echo "unknown mode: $mode" >&2
            exit 2
            ;;
        esac
      '';

  mod = "SUPER";
  terminal =
    if config.modules.gui.matugen.enable
    then "kitty"
    else "alacritty";
  shellEnabled = config.modules.gui.shell.enable;
  hyprexpo = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "hyprexpo";
    version = "0.1-${builtins.substring 0 7 inputs.hyprexpo.rev}";
    src = inputs.hyprexpo;
    inherit (pkgs.hyprland) nativeBuildInputs;
    meta = {};
  };
  hyprexpoLoadScript = pkgs.writeShellScript "load-hyprexpo" ''
    set -euo pipefail

    if ! hyprctl plugin list | grep -q '^Plugin hyprexpo '; then
      hyprctl plugin load "${hyprexpo}/lib/libhyprexpo.so"
    fi
    hyprctl reload
  '';
  mkBind = keys: dispatcher: {_args = [keys (mkLuaInline dispatcher)];};
  mkBindOpts = keys: dispatcher: opts: {_args = [keys (mkLuaInline dispatcher) opts];};

  locked = {locked = true;};
  lockedRepeat = {
    locked = true;
    repeating = true;
  };
  repeating = {repeating = true;};
  mouse = {mouse = true;};

  mediaBinds = [
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

  # Binds for the self-built Quickshell shell (modules/gui/shell.nix).
  qs = sub: ''hl.dsp.exec_cmd("quickshell -c shell ipc call ${sub}")'';
  run = cmd: ''hl.dsp.exec_cmd("${cmd}")'';

  shellBinds = lib.optionals shellEnabled [
    (mkBindOpts "${mod} + Super_L" (qs "launcher toggle") {release = true;})
    (mkBindOpts "${mod} + Super_R" (qs "launcher toggle") {release = true;})
    (mkBind "${mod} + D" (qs "launcher toggle"))

    (mkBind "${mod} + S" (qs "panel toggle"))
    (mkBind "${mod} + N" (qs "panel toggle"))

    (mkBind "${mod} + C" (qs "clipboard toggle"))
    (mkBind "${mod} + W" (qs "wallpapers toggle"))
    (mkBind "${mod} + I" (qs "settings toggle"))
    (mkBind "${mod} + CTRL + W" (qs "wallpaperbar toggle"))
    (mkBind "${mod} + SHIFT + W" (run "random-wallpaper"))
    (mkBind "ALT + TAB" (qs "switcher next"))
    (mkBind "ALT + SHIFT + TAB" (qs "switcher prev"))
    (mkBindOpts "ALT + Alt_L" (qs "switcher commit") {release = true;})

    (mkBindOpts "${mod} + L" (run "loginctl lock-session") locked)
    (mkBindOpts "XF86PowerOff" (run "loginctl lock-session") locked)

    (mkBindOpts "Prior" (run "shell-screenshot region") locked)
    (mkBindOpts "${mod} + Prior" (run "shell-screenshot full") locked)
  ];

  overviewBinds = [
    (mkBind "${mod} + TAB" ''function() hl.plugin.hyprexpo.expo("toggle") end'')
  ];

  shellRules = lib.optionals shellEnabled [
    {
      name = "shell";
      match.namespace = "^(pill-(bar|panel|launcher)|notifications)$";
      no_anim = true;
      ignore_alpha = 0.3;
      blur = true;
      blur_popups = true;
    }
  ];

  persistentWorkspaces =
    if synchronizedWorkspaces != null
    then
      lib.concatMap (
        i:
          map (side: {
            workspace = "name:${toString i}-${side.name}";
            monitor = side.monitor;
            persistent = true;
          }) [
            {
              name = "left";
              monitor = synchronizedWorkspaces.left;
            }
            {
              name = "right";
              monitor = synchronizedWorkspaces.right;
            }
          ]
      ) (lib.range 1 synchronizedWorkspaces.count)
    else
      lib.optionals shellEnabled (
        map (i: {
          workspace = toString i;
          persistent = true;
        }) (lib.range 1 10)
      );

  workspaceBinds =
    lib.concatMap (i: let
      key =
        if i == 10
        then "0"
        else toString i;
    in [
      (
        if synchronizedWorkspaces != null
        then (mkBind "${mod} + ${key}" ''hl.dsp.exec_cmd("${synchronizedWorkspaceScript} switch ${toString i}")'')
        else (mkBind "${mod} + ${key}" "hl.dsp.focus({ workspace = ${toString i} })")
      )
      (
        if synchronizedWorkspaces != null
        then (mkBind "${mod} + SHIFT + ${key}" ''hl.dsp.exec_cmd("${synchronizedWorkspaceScript} move ${toString i}")'')
        else (mkBind "${mod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${toString i} })")
      )
    ]) (lib.range 1 (
      if synchronizedWorkspaces != null
      then synchronizedWorkspaces.count
      else 10
    ));

  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    size = "standard";
    tweaks = ["normal"];
    variant = "mocha";
  };
  catppuccinThemeName = "catppuccin-mocha-blue-standard+normal";

  gtkFileManagerCss = ''
    ${lib.optionalString config.modules.gui.matugen.enable ''
      @import url("matugen.css");
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
      extraPortals = [pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk];
      config.hyprland = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
    };

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    modules.gui.alacritty.enable = lib.mkDefault true;
    modules.gui.kitty.enable = lib.mkDefault true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {lib, ...}: {
      wayland.systemd.target = "hyprland-session.target";

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        configType = "lua";
        # The system-level xdg.portal already provides hyprland + gtk. HM's own
        # portal would set NIX_XDG_DESKTOP_PORTAL_DIR to a per-user profile
        # holding only the hyprland portal, hiding the gtk FileChooser.
        portalPackage = null;

        extraConfig =
          ''
            pcall(function()
              require("matugen").apply_theme()
            end)
          ''
          + lib.optionalString (synchronizedWorkspaceScript != null) ''
            hl.dsp.exec_cmd("${synchronizedWorkspaceScript} migrate")
          ''
          + lib.optionalString shellEnabled ''
            hl.dsp.exec_cmd("monitors-layout restore")
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
              gaps_in = 6;
              gaps_out = 10;
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
              rounding = 14;
              rounding_power = 2;
              active_opacity = 1.0;
              inactive_opacity = 1.0;

              blur = {
                enabled = true;
                size = 8;
                passes = 2;
                new_optimizations = true;
              };

              shadow =
                if config.modules.gui.matugen.enable
                then {
                  enabled = true;
                  range = 28;
                  render_power = 3;
                  color = "rgba(00000066)";
                }
                else {enabled = false;};
            };

            input = {
              kb_layout = kbLayout;
              kb_variant = "";
              kb_model = "";
              kb_options = "";
              kb_rules = "";
              follow_mouse = 1;
              accel_profile = "flat";
              sensitivity = 1;
              touchpad.natural_scroll = true;
            };

            misc = {
              focus_on_activate = true;
              font_family = "JetBrains Mono";
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              force_default_wallpaper = 0;
            };

            plugin.hyprexpo = {
              columns = 3;
              gaps_in = 8;
              bg_col = "rgb(1e1e2e)";
              workspace_method = "center current";
            };

            cursor.no_hardware_cursors = true;
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
              (mkBind "${mod} + SHIFT + T" "hl.dsp.exec_cmd(\"kitty\")")
              (mkBind "${mod} + F" "hl.dsp.exec_cmd(\"brave\")")
              (mkBind "${mod} + E" "hl.dsp.exec_cmd(\"nautilus\")")
              (mkBind "${mod} + SHIFT + E" "hl.dsp.exec_cmd(\"files\")")

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
            ++ shellBinds
            ++ overviewBinds;

          layer_rule = shellRules;

          workspace_rule = persistentWorkspaces;

          window_rule = [
            {
              name = "shell-settings";
              match.title = "^(Settings)$";
              float = true;
              center = true;
            }
            {
              name = "shell-files";
              match.title = "^(Files)$";
              float = true;
              center = true;
              size = "1100 700";
            }
            {
              name = "cs2-immediate";
              match.class = "^(cs2)$";
              immediate = true;
              keep_aspect_ratio = true;
            }
          ];
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

      systemd.user.services =
        (lib.optionalAttrs (dockDisplay != null) {
          hypr-dock-display = {
            Unit = {
              Description = "Disable the laptop display while docked, enable it when undocked";
              PartOf = ["hyprland-session.target"];
              After = ["hyprland-session.target"];
            };
            Service = {
              Type = "simple";
              ExecStart = "${dockDisplayScript}";
              Restart = "on-failure";
            };
            Install = {
              WantedBy = ["hyprland-session.target"];
            };
          };
        })
        // {
          hyprexpo = {
            Unit = {
              Description = "Load the hyprexpo plugin";
              PartOf = ["hyprland-session.target"];
              After = ["hyprland-session.target"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${hyprexpoLoadScript}";
              RemainAfterExit = true;
            };
            Install = {
              WantedBy = ["hyprland-session.target"];
            };
          };
        };
    };
  };
}
