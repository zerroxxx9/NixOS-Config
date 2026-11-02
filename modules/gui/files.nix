{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.files;
  home = "/home/${hostVariables.username}";

  settingsQml = ''
    import QtQuick

    QtObject {
        property string font: "Geist"
        property string themeFile: ${builtins.toJSON "${home}/.local/state/matugen/theme.json"}
        property string home: ${builtins.toJSON home}
        property string trashDir: ${builtins.toJSON "${home}/.local/share/Trash/files"}
    }
  '';

  # File operations the QML side shells out to. Pastes never overwrite: a
  # clash becomes "name (copy).ext", "name (copy 2).ext", ...
  filesOp = pkgs.writeShellApplication {
    name = "files-op";
    runtimeInputs = [pkgs.coreutils pkgs.glib pkgs.ffmpegthumbnailer pkgs.libnotify];
    text = ''
      op="''${1:-}"
      [ $# -gt 0 ] && shift

      fail() {
        notify-send -a Files -u critical "Files" "$1"
        exit 1
      }

      free_name() {
        local dest="$1" name="$2" base ext n=1 candidate
        if [ ! -e "$dest/$name" ] && [ ! -L "$dest/$name" ]; then
          echo "$dest/$name"
          return
        fi
        if [[ "$name" == .* ]] || [[ "$name" != *.* ]]; then
          base="$name"
          ext=""
        else
          base="''${name%.*}"
          ext=".''${name##*.}"
        fi
        candidate="$dest/$base (copy)$ext"
        while [ -e "$candidate" ] || [ -L "$candidate" ]; do
          n=$((n + 1))
          candidate="$dest/$base (copy $n)$ext"
        done
        echo "$candidate"
      }

      case "$op" in
        copy | move)
          dest="$1"
          shift
          failed=0
          for src in "$@"; do
            name=$(basename -- "$src")
            if [ "$op" = move ] && [ "$(dirname -- "$src")" = "$dest" ]; then
              continue
            fi
            target=$(free_name "$dest" "$name")
            if [ "$op" = copy ]; then
              cp -a -- "$src" "$target" || failed=1
            else
              mv -- "$src" "$target" || failed=1
            fi
          done
          [ "$failed" = 0 ] || fail "Some items could not be ''${op}d"
          ;;
        trash)
          gio trash -- "$@" || fail "Could not move to trash"
          ;;
        rename)
          [ -e "$2" ] && fail "\"$(basename -- "$2")\" already exists"
          mv -- "$1" "$2" || fail "Could not rename"
          ;;
        mkdir)
          [ -e "$1" ] && fail "\"$(basename -- "$1")\" already exists"
          mkdir -- "$1" || fail "Could not create folder"
          ;;
        thumb)
          dir="''${XDG_CACHE_HOME:-$HOME/.cache}/files-thumbs"
          mkdir -p "$dir"
          key=$(printf '%s' "$1$(stat -c %Y -- "$1")" | md5sum | cut -d' ' -f1)
          out="$dir/$key.jpg"
          [ -s "$out" ] || ffmpegthumbnailer -i "$1" -o "$out" -s 512 >/dev/null 2>&1 || exit 1
          echo "$out"
          ;;
        *)
          echo "usage: files-op copy|move DEST SRC... | trash PATH... | rename OLD NEW | mkdir PATH | thumb FILE" >&2
          exit 2
          ;;
      esac
    '';
  };

  # `files [DIR]` opens a new window, defaulting to $HOME.
  files = pkgs.writeShellApplication {
    name = "files";
    runtimeInputs = [pkgs.quickshell pkgs.coreutils];
    text = ''
      dir="$(realpath -- "''${1:-$HOME}")"
      [ -d "$dir" ] || dir="$(dirname -- "$dir")"
      FILES_START="$dir" exec quickshell -c files
    '';
  };
in {
  options.modules.gui.files = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.modules.gui.shell.enable;
      description = "Self-built Quickshell file manager (`files`). Follows the shell module by default.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [files filesOp];

    home-manager.users.${hostVariables.username} = {
      home.packages = [pkgs.quickshell];

      xdg.configFile = {
        "quickshell/files" = {
          source = ./files;
          recursive = true;
        };
        "quickshell/files/Theme.qml".source = ./shell/Theme.qml;
        "quickshell/files/Settings.qml".text = settingsQml;
      };
    };
  };
}
