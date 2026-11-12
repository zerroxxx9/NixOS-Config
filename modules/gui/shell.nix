{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.shell;
  home = "/home/${hostVariables.username}";

  primaryOutput = let
    monitors = lib.attrByPath ["hyprland" "monitors"] [] hostVariables;
  in
    if monitors == []
    then ""
    else (builtins.head monitors).output;

  settingsQml = ''
    import QtQuick

    QtObject {
        property string output: ${builtins.toJSON cfg.output}
        property string font: "Geist"
        property string themeFile: ${builtins.toJSON "${home}/.local/state/matugen/theme.json"}
        property string bin: "/run/current-system/sw/bin"
        property string userBin: ${builtins.toJSON "${home}/.local/state/nix/profiles/home-manager/home-path/bin"}
        property string stateDir: ${builtins.toJSON "${home}/.local/state/matugen"}
        property string wallpaperDir: ${builtins.toJSON "${home}/.dotfiles/assets/wallpaper"}
        property int height: 30
    }
  '';

  lockSettingsQml = ''
    import QtQuick

    QtObject {
        property string font: "Geist"
        property string themeFile: ${builtins.toJSON "${home}/.local/state/matugen/theme.json"}
        property string stateDir: ${builtins.toJSON "${home}/.local/state/matugen"}
        property string username: ${builtins.toJSON hostVariables.username}
        property string avatar: ${builtins.toJSON "${home}/.dotfiles/assets/profilePictures/kitty.jpg"}
    }
  '';

  lockScreen = pkgs.writeShellApplication {
    name = "lock-screen";
    runtimeInputs = [pkgs.quickshell pkgs.procps];
    text = ''
      pgrep -f "quickshell -c lock" >/dev/null && exit 0
      exec quickshell -c lock
    '';
  };

  wallpaperDir = "${home}/.dotfiles/assets/wallpaper";

  screenshot = pkgs.writeShellApplication {
    name = "shell-screenshot";
    runtimeInputs = [pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.libnotify pkgs.coreutils];
    text = ''
      mode="''${1:-full}"
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%F_%H-%M-%S).png"
      case "$mode" in
        region)
          geometry=$(slurp </dev/null) || exit 0
          grim -g "$geometry" "$file"
          ;;
        full) grim "$file" ;;
        *)
          echo "usage: shell-screenshot region|full" >&2
          exit 2
          ;;
      esac
      wl-copy < "$file"
      notify-send -i "$file" "Screenshot" "Saved $(basename "$file")"
    '';
  };

  record = pkgs.writeShellApplication {
    name = "shell-record";
    excludeShellChecks = ["SC2016"]; # the sh -c '...$$...' string is meant to expand in the child shell
    runtimeInputs = [pkgs.wl-screenrec pkgs.slurp pkgs.jq pkgs.libnotify pkgs.coreutils pkgs.util-linux pkgs.quickshell];
    text = ''
      pidfile="''${XDG_RUNTIME_DIR:-/tmp}/shell-record.pid"
      dir="$HOME/Videos/Recordings"

      recording() {
        [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null
      }

      stop() {
        recording || { rm -f "$pidfile"; return 0; }
        pid=$(cat "$pidfile")
        kill -INT "$pid"
        while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
        rm -f "$pidfile"
        notify-send -i media-record "Recording saved" "$(basename "$(cat "$pidfile.file")")"
      }

      case "''${1:-menu}" in
        menu)
          if recording; then stop; else quickshell -c shell ipc call record open; fi
          ;;
        start)
          recording && exit 0
          mkdir -p "$dir"
          file="$dir/$(date +%F_%H-%M-%S).mp4"
          case "''${2:-full}" in
            region)
              geometry=$(slurp </dev/null) || exit 0
              target=(-g "$geometry")
              ;;
            full)
              target=(-o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')")
              ;;
            *)
              echo "usage: shell-record start region|full" >&2
              exit 2
              ;;
          esac
          printf '%s' "$file" >"$pidfile.file"
          # shellcheck disable=SC2016
          setsid sh -c 'echo $$ >"$1"; shift; exec wl-screenrec "$@"' sh "$pidfile" "''${target[@]}" -f "$file" >/dev/null 2>&1 &
          sleep 0.3
          notify-send -i media-record "Recording started" "Press Super+Shift+R to stop"
          ;;
        stop) stop ;;
        *)
          echo "usage: shell-record menu|start region|full|stop" >&2
          exit 2
          ;;
      esac
    '';
  };

  randomWallpaper = pkgs.writeShellApplication {
    name = "random-wallpaper";
    runtimeInputs = [pkgs.findutils pkgs.coreutils];
    text = ''
      image=$(find ${wallpaperDir} -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)
      exec set-wallpaper "$image"
    '';
  };

  # Monitor layout chosen in Settings → Display. `save JSON` merges it into
  # ~/.local/state/shell/monitors.json and applies it; `restore` re-applies the
  # saved file (run on every Hyprland config load, since the declarative
  # monitor block would otherwise reset it).
  monitorsLayout = pkgs.writeShellApplication {
    name = "monitors-layout";
    runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.awww];
    text = ''
      file="''${XDG_STATE_HOME:-$HOME/.local/state}/shell/monitors.json"

      refresh_wallpaper() {
        sleep 0.5
        image=$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n1 || true)
        if [ -n "$image" ]; then
          awww img "$image" --transition-type none
        fi
      }

      apply() {
        [ -f "$file" ] || return 0
        connected=$(hyprctl monitors all -j | jq -r '.[].name')
        jq -r 'to_entries[] | [.key, .value.mode, (.value.x | tostring), (.value.y | tostring), (.value.scale | tostring), (.value.transform | tostring)] | @tsv' "$file" |
          while IFS=$'\t' read -r name mode x y scale transform; do
            grep -qx "$name" <<<"$connected" || continue
            hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"''${x}x''${y}\", scale = $scale, transform = $transform })" >/dev/null
          done
        refresh_wallpaper
      }

      case "''${1:-restore}" in
        save)
          mkdir -p "$(dirname "$file")"
          if [ -f "$file" ]; then
            printf '%s' "$2" | jq -s '.[0] * .[1]' "$file" - >"$file.new"
            mv "$file.new" "$file"
          else
            printf '%s' "$2" | jq . >"$file"
          fi
          apply
          ;;
        restore)
          # Hyprland applies declarative monitor rules asynchronously during
          # startup/reload; wait until they settle before restoring the saved layout.
          sleep 1
          apply
          ;;
        *)
          echo "usage: monitors-layout save JSON|restore" >&2
          exit 2
          ;;
      esac
    '';
  };

  nightlight = pkgs.writeShellApplication {
    name = "nightlight";
    runtimeInputs = [pkgs.hyprsunset pkgs.procps pkgs.util-linux];
    text = ''
      case "''${1:-status}" in
        status) pgrep -x hyprsunset >/dev/null ;;
        toggle)
          if pgrep -x hyprsunset >/dev/null; then
            pkill -x hyprsunset
          else
            setsid hyprsunset -t 3800 >/dev/null 2>&1 &
          fi
          ;;
        *)
          echo "usage: nightlight status|toggle" >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  options.modules.gui.shell = {
    enable = lib.mkEnableOption "self-built Quickshell desktop shell";
    output = lib.mkOption {
      type = lib.types.str;
      default = primaryOutput;
      description = "Monitor the bar appears on; only this one gets a bar.";
    };
  };

  config = lib.mkIf cfg.enable {
    modules.gui.matugen.enable = lib.mkDefault true;

    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    networking.networkmanager.enable = lib.mkDefault true;
    services.gvfs.enable = lib.mkDefault true;
    services.udisks2.enable = lib.mkDefault true;

    security.pam.services.hyprlock = {};
    security.pam.services.quickshell-lock = {};

    environment.systemPackages = [
      screenshot
      record
      randomWallpaper
      lockScreen
      monitorsLayout
      nightlight
      pkgs.mako
      pkgs.cliphist
      pkgs.grim
      pkgs.slurp
      pkgs.hyprsunset
      pkgs.libnotify
      pkgs.wl-clipboard
    ];

    home-manager.users.${hostVariables.username} = {
      home.packages = [pkgs.quickshell monitorsLayout];

      xdg.configFile = {
        "quickshell/shell" = {
          source = ./shell;
          recursive = true;
        };
        "quickshell/shell/Settings.qml".text = settingsQml;
        "quickshell/lock" = {
          source = ./lock;
          recursive = true;
        };
        "quickshell/lock/Theme.qml".source = ./shell/Theme.qml;
        "quickshell/lock/Settings.qml".text = lockSettingsQml;
      };

      systemd.user.services.shell = {
        Unit = {
          Description = "Quickshell desktop shell";
          PartOf = ["hyprland-session.target"];
          After = ["hyprland-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.quickshell}/bin/quickshell -c shell";
          Restart = "on-failure";
          Environment = ["PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${hostVariables.username}/bin"];
        };
        Install.WantedBy = ["hyprland-session.target"];
      };

      services.mako = {
        enable = true;
        settings = {
          include = "${home}/.config/mako/matugen";
          font = "Geist 11";
          anchor = "bottom-right";
          margin = "0,12,12,0";
          outer-margin = "0,12,28,0";
          padding = "14,18";
          border-size = 1;
          border-radius = 20;
          default-timeout = 6000;
          max-visible = 4;
          "mode=do-not-disturb".invisible = 1;
        };
      };

      programs.hyprlock = {
        enable = true;
        extraConfig = ''
          source = ${home}/.config/hypr/hyprlock-colors.conf

          general {
            hide_cursor = true
          }

          background {
            monitor =
            path = screenshot
            blur_passes = 3
            blur_size = 8
            brightness = 0.6
          }

          label {
            monitor =
            text = $TIME
            color = $text
            font_size = 96
            font_family = Geist
            position = 0, 140
            halign = center
            valign = center
          }

          input-field {
            monitor =
            size = 320, 54
            rounding = 27
            outline_thickness = 2
            outer_color = $accent
            inner_color = $surface
            font_color = $text
            check_color = $accent
            fail_color = $error
            fade_on_empty = true
            placeholder_text = <span foreground="##888888">Password</span>
            position = 0, -60
            halign = center
            valign = center
          }
        '';
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "lock-screen";
            before_sleep_cmd = "loginctl lock-session";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 660;
              on-timeout = ''hyprctl dispatch 'hl.dsp.dpms({ action = "off" })' '';
              on-resume = ''hyprctl dispatch 'hl.dsp.dpms({ action = "on" })' '';
            }
          ];
        };
      };

      services.hyprpolkitagent.enable = true;

      systemd.user.services.cliphist = {
        Unit = {
          Description = "Clipboard history";
          PartOf = ["hyprland-session.target"];
          After = ["hyprland-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
        };
        Install.WantedBy = ["hyprland-session.target"];
      };
    };
  };
}
