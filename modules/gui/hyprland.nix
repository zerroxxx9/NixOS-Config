{
  pkgs,
  lib,
  config,
  hostVariables,
  inputs,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  homeDir = "/home/${hostVariables.username}";
  wallpaperDir = "/home/${hostVariables.username}/.dotfiles/assets/wallpaper";
  matugenCacheDir = "${homeDir}/.cache/matugen";
  matugenAlacritty = "${matugenCacheDir}/alacritty.toml";
  matugenGtkCss = "${matugenCacheDir}/gtk.css";
  matugenHyprColors = "${matugenCacheDir}/hypr/colors.conf";
  matugenQsColors = "${matugenCacheDir}/qs_colors.json";
  matugenSwayosdCss = "${matugenCacheDir}/swayosd.css";
  matugenCavaColors = "${homeDir}/.config/cava/colors";
  quickshellWithQtModules = pkgs.symlinkJoin {
    name = "quickshell-with-qt-modules";
    paths = [pkgs.quickshell];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = let
      qtQmlModules = lib.makeSearchPath "lib/qt-6/qml" [
        pkgs.qt6.qt5compat
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qtwebengine
        pkgs.qt6.qtwebsockets
      ];
      qtPlugins = lib.makeSearchPath "lib/qt-6/plugins" [
        pkgs.qt6.qt5compat
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qtwebengine
        pkgs.qt6.qtwebsockets
      ];
    in ''
      wrapProgram $out/bin/quickshell \
        --prefix QML2_IMPORT_PATH : ${qtQmlModules} \
        --prefix QT_PLUGIN_PATH : ${qtPlugins}
      wrapProgram $out/bin/qs \
        --prefix QML2_IMPORT_PATH : ${qtQmlModules} \
        --prefix QT_PLUGIN_PATH : ${qtPlugins}
    '';
  };
  hyprlandScripts = pkgs.runCommand "hyprland-scripts" {nativeBuildInputs = [pkgs.perl];} ''
        cp -R ${inputs.ilyamiro-dots}/config/sessions/hyprland/scripts $out
        chmod -R u+w $out
        cp ${./hyprland/ilyamiro/scripts/quickshell/applauncher/app_fetcher.py} $out/quickshell/applauncher/app_fetcher.py
        cp ${./hyprland/ilyamiro/scripts/quickshell/applauncher/appLauncher.qml} $out/quickshell/applauncher/appLauncher.qml

        perl -0pi -e 's|\$HOME/Pictures/Wallpapers|\$HOME/.dotfiles/assets/wallpaper|g; s|\$HOME/\.dotfiles/assets/wallpapers|\$HOME/.dotfiles/assets/wallpaper|g' $out/qs_manager.sh

        substituteInPlace $out/quickshell/Config.qml \
          --replace-fail 'readonly property string weatherEnvPath: qsScriptsDir + "/calendar/.env"' \
          'readonly property string weatherEnvPath: homeDir + "/.config/quickshell/hyprland-weather.env"'

        perl -0pi -e 's|homeDir \+ "/Pictures/Wallpapers"|homeDir + "/.dotfiles/assets/wallpaper"|g' $out/quickshell/Config.qml

        substituteInPlace $out/quickshell/calendar/weather.sh \
          --replace-fail 'ENV_FILE="$(dirname "$0")/.env"' \
          'ENV_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hyprland-weather.env"'

        perl -0pi -e 's|Quickshell\.env\("HOME"\) \+ "/Pictures/Wallpapers"|Quickshell.env("HOME") + "/.dotfiles/assets/wallpaper"|g' $out/quickshell/wallpaper/WallpaperPicker.qml

        substituteInPlace $out/quickshell/MatugenColors.qml \
          --replace-fail 'command: ["cat", "/tmp/qs_colors.json"]' \
          'command: ["cat", Quickshell.env("HOME") + "/.cache/matugen/qs_colors.json"]'

        cat >> $out/quickshell/wallpaper/matugen_reload.sh <<'EOF'

    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
    EOF

        perl -0pi -e '
          s/\n\s*Rectangle \{\n\s*property bool isHovered: helpMouse\.containsMouse.*?\n\s*\}\n(?=\s*Rectangle \{\n\s*property bool isHovered: searchMouse\.containsMouse)//s;
          s/\n\s*Rectangle \{\n\s*property bool isHovered: settingsMouse\.containsMouse.*?\n\s*\}\n(?=\s*Rectangle \{\n\s*id: updateButton)//s;
          s/\n\s*Rectangle \{\n\s*id: updateButton.*?\n\s*\}\n(?=\s*\}\n\s*\}\n\s*Rectangle \{\n\s*id: workspacesBox)/\n/s;
        ' $out/quickshell/TopBar.qml

        rm -rf $out/quickshell/calendar/schedule
        rm -f $out/quickshell/wallpaper/ddg_search.sh
        rm -f $out/quickshell/wallpaper/get_ddg_links.py

        perl -0pi -e '
          s/property real targetMasterHeight: window\.scheduleModuleExists \? Math\.round\(750 \* window\.sf\) : Math\.round\(510 \* window\.sf\)/property real targetMasterHeight: Math.round(510 * window.sf)/;
          s/property real centerOffset: window\.scheduleModuleExists \? Math\.round\(-100 \* window\.sf\) : 0/property real centerOffset: 0/;
          s/command: \["bash", "-c", "\[ -f .*?schedule_manager\.sh.*?\|\| echo 0"\]/command: ["bash", "-c", "echo 0"]/;
          s/command: \["bash", window\.scriptsDir \+ "\/schedule\/schedule_manager\.sh"\]/command: ["bash", "-c", "true"]/;
          s/running: window\.scheduleModuleExists; repeat: true/running: false; repeat: false/;
        ' $out/quickshell/calendar/CalendarPopup.qml

        perl -0pi -e '
          s/,\n\s*\{ name: "Search", hex: "", label: "Search" \}\s*//;
          s/\n\s*if \(window\.currentFilter === "Search" && window\.hasSearched\) \{.*?\n\s*const originalFile/\n        const originalFile/s;
          s/function triggerOnlineSearch\(\) \{.*?\n    \}\n\n    readonly property string homeDir/function triggerOnlineSearch() {\n        window.currentFilter = "All";\n        window.hasSearched = false;\n        window.isOnlineSearch = false;\n    }\n\n    readonly property string homeDir/s;
          s/onIsSearchPausedChanged: \{.*?\n    \}/onIsSearchPausedChanged: {}/s;
          s/visible: window\.currentFilter === "Search" && window\.hasSearched/visible: false/g;
          s/width: window\.currentFilter === "Search" \? window\.s\(360\) : window\.s\(44\)/width: 0/g;
          s/Component\.onCompleted: \{.*?\n    \}\n\n    Component\.onDestruction: \{.*?\n    \}/Component.onCompleted: {\n        window.currentFilter = "All";\n        window.hasSearched = false;\n        window.isOnlineSearch = false;\n        window.loadMonitors();\n        view.forceActiveFocus();\n        window.processMarkers();\n        window.triggerColorExtraction();\n    }\n\n    Component.onDestruction: {\n        window.hasSearched = false;\n    }/s;
        ' $out/quickshell/wallpaper/WallpaperPicker.qml

        perl -0pi -e '
          s/command: \["bash", "-c", "c[u]rl -m 5 -s (?:\\.|[^"])*"\]/command: ["bash", "-c", "true"]/g;
          s/command: \["bash", "-c", "c[u]rl -m 60 .*?window\.videoUrl\]/command: ["bash", "-c", "true"]/s;
          s/property string videoResolveScript: `.*?`\n\n    Process \{\n        id: videoResolveProcess/property string videoResolveScript: `\nprint("")\n`\n\n    Process {\n        id: videoResolveProcess/s;
          s/property string fetchScript: `.*?`\n\n    Process \{\n        id: commitFetchProcess/property string fetchScript: `\nprint("Remote update checks disabled. Use nix flake update and rebuild.")\n`\n\n    Process {\n        id: commitFetchProcess/s;
          s/\n\s*let cmd = "if command -v kitty.*?curl.*?";\n\s*Quickshell\.execDetached\(\["bash", "-c", cmd\]\);/\n                            Quickshell.execDetached(["notify-send", "Updater disabled", "Use nix flake update and rebuild from your dotfiles."]);/sg;
         ' $out/quickshell/updater/UpdaterPopup.qml $out/quickshell/guide/GuidePopup.qml
  '';
  hyprlandConfig = pkgs.runCommand "hyprland-config" {} ''
    cp -R ${./hyprland/ilyamiro/config} $out
    chmod -R u+w $out
    if ! grep -q '^env = WALLPAPER_DIR,' "$out/env.conf"; then
      printf '\nenv = WALLPAPER_DIR,${wallpaperDir}\n' >> "$out/env.conf"
    fi
  '';
  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    size = "standard";
    tweaks = ["normal"];
    variant = "mocha";
  };
  catppuccinThemeName = "catppuccin-mocha-blue-standard+normal";
  gtkFileManagerCss = ''
    @import url("file://${matugenGtkCss}");

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
      border-bottom: 1px solid alpha(@outline_color, 0.65);
    }

    placessidebar,
    placessidebar list,
    .sidebar {
      background-color: @sidebar_bg_color;
      color: @sidebar_fg_color;
    }

    placessidebar row {
      border-radius: 8px;
      margin: 2px 6px;
      padding: 4px 8px;
    }

    placessidebar row:hover {
      background-color: alpha(@card_bg_color, 0.55);
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

    services.displayManager.gdm = {
      enable = lib.mkDefault true;
      wayland = lib.mkDefault true;
    };
    services.displayManager.defaultSession = lib.mkDefault "hyprland";

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WALLPAPER_DIR = wallpaperDir;
    };

    environment.systemPackages = with pkgs; [
      bibata-cursors
      bluez
      brightnessctl
      cliphist
      curl
      ffmpeg
      gnome-console
      gpu-screen-recorder
      grim
      hypridle
      imagemagick
      inotify-tools
      iw
      jq
      libnotify
      lm_sensors
      matugen
      mpvpaper
      networkmanager_dmenu
      playerctl
      python3
      quickshellWithQtModules
      rofi
      satty
      slurp
      socat
      swww
      swayosd
      wl-screenrec
      wl-clipboard
      zbar
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {
      lib,
      config,
      ...
    }: {
      imports = [
        ./hyprland/ilyamiro/hypridle.nix
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        extraConfig = ''
          source = ${./hyprland/ilyamiro/hyprland.conf}
        '';
      };
      xdg.configFile."hypr/hyprland.conf".force = true;

      home.packages = with pkgs; [
        acpi
        alsa-utils
        bc
        cava
        fd
        fortune
        catppuccinGtk
        gtk3
        ladspaPlugins
        ladspa-sdk
        pamixer
        pavucontrol
        pulseaudio
        qt6.qt5compat
        qt6.qtmultimedia
        qt6.qtwebengine
        qt6.qtwebsockets
        papirus-icon-theme
        ripgrep
        tree
      ];

      programs.alacritty.settings = {
        import = [matugenAlacritty];
        colors = lib.mkForce {};
      };

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

      services.swayosd = {
        enable = true;
        topMargin = 0.9;
        stylePath = "/home/${hostVariables.username}/.config/swayosd/style.css";
      };

      services.gnome-keyring = {
        enable = true;
        components = ["secrets"];
      };

      xdg.configFile."hypr/colors.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink matugenHyprColors;
        force = true;
      };
      xdg.configFile."matugen/config.toml".text = ''
        [config]
        reload_apps = false

        [templates.quickshell]
        input_path = "${homeDir}/.config/matugen/templates/qs_colors.json.template"
        output_path = "${matugenQsColors}"

        [templates.alacritty]
        input_path = "${homeDir}/.config/matugen/templates/alacritty.toml.template"
        output_path = "${matugenAlacritty}"

        [templates.cava]
        input_path = "${homeDir}/.config/matugen/templates/cava-colors.ini.template"
        output_path = "${matugenCavaColors}"

        [templates.gtk]
        input_path = "${homeDir}/.config/matugen/templates/gtk.css.template"
        output_path = "${matugenGtkCss}"

        [templates.hyprland]
        input_path = "${homeDir}/.config/matugen/templates/hyprland.conf.template"
        output_path = "${matugenHyprColors}"

        [templates.swayosd]
        input_path = "${homeDir}/.config/matugen/templates/swayosd.css.template"
        output_path = "${matugenSwayosdCss}"
      '';
      xdg.configFile."matugen/templates/alacritty.toml.template".source = ./matugen/templates/alacritty.toml.template;
      xdg.configFile."matugen/templates/cava-colors.ini.template".source = ./matugen/templates/cava-colors.ini.template;
      xdg.configFile."matugen/templates/gtk.css.template".source = ./matugen/templates/gtk.css.template;
      xdg.configFile."matugen/templates/hyprland.conf.template".source = ./matugen/templates/hyprland.conf.template;
      xdg.configFile."matugen/templates/qs_colors.json.template".source = ./matugen/templates/qs_colors.json.template;
      xdg.configFile."matugen/templates/swayosd.css.template".source = ./matugen/templates/swayosd.css.template;
      xdg.configFile."swayosd/style.css" = {
        source = config.lib.file.mkOutOfStoreSymlink matugenSwayosdCss;
        force = true;
      };

      services.easyeffects.enable = true;

      home.sessionVariables.WALLPAPER_DIR = wallpaperDir;

      home.file.".config/hypr/scripts".source = hyprlandScripts;

      xdg.configFile."quickshell/qs-hyprview".source = inputs.qs-hyprview;
      xdg.configFile."hypr/config".source = hyprlandConfig;
      xdg.configFile."hypr/templates".source =
        inputs.ilyamiro-dots + "/config/sessions/hyprland/templates";

      home.activation.ensureMatugenFallbacks = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        install_if_missing() {
          if [ ! -s "$2" ]; then
            install -Dm0644 "$1" "$2"
          fi
        }

        install_if_missing ${./matugen/fallback/alacritty.toml} "${matugenAlacritty}"
        install_if_missing ${./matugen/fallback/cava-colors.ini} "${matugenCavaColors}"
        install_if_missing ${./matugen/fallback/gtk.css} "${matugenGtkCss}"
        install_if_missing ${./matugen/fallback/hyprland.conf} "${matugenHyprColors}"
        install_if_missing ${./matugen/fallback/qs_colors.json} "${matugenQsColors}"
        install_if_missing ${./matugen/fallback/swayosd.css} "${matugenSwayosdCss}"
      '';

      home.activation.removeLegacyIlyamiroCopies = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        rm -rf "$HOME/.config/hypr/config"
        rm -rf "$HOME/.config/hypr/templates"
      '';
    };
  };
}
