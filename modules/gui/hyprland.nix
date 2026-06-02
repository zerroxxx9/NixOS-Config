{
  pkgs,
  lib,
  config,
  hostVariables,
  inputs,
  ...
}: let
  cfg = config.modules.gui.hyprland;
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

    substituteInPlace $out/quickshell/Config.qml \
      --replace-fail 'readonly property string weatherEnvPath: qsScriptsDir + "/calendar/.env"' \
      'readonly property string weatherEnvPath: homeDir + "/.config/quickshell/hyprland-weather.env"'

    substituteInPlace $out/quickshell/calendar/weather.sh \
      --replace-fail 'ENV_FILE="$(dirname "$0")/.env"' \
      'ENV_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hyprland-weather.env"'

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
  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    size = "standard";
    tweaks = ["normal"];
    variant = "mocha";
  };
  catppuccinThemeName = "catppuccin-mocha-blue-standard+normal";
  gtkFileManagerCss = ''
    @define-color accent_color #89b4fa;
    @define-color accent_bg_color #89b4fa;
    @define-color accent_fg_color #11111b;
    @define-color window_bg_color #1e1e2e;
    @define-color window_fg_color #cdd6f4;
    @define-color view_bg_color #181825;
    @define-color view_fg_color #cdd6f4;
    @define-color headerbar_bg_color #181825;
    @define-color headerbar_fg_color #cdd6f4;
    @define-color sidebar_bg_color #11111b;
    @define-color sidebar_fg_color #bac2de;
    @define-color card_bg_color #313244;
    @define-color card_fg_color #cdd6f4;
    @define-color popover_bg_color #181825;
    @define-color popover_fg_color #cdd6f4;

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
      background-color: alpha(#45475a, 0.55);
    }

    placessidebar row:selected {
      background-color: alpha(#89b4fa, 0.24);
      color: #cdd6f4;
    }

    pathbar button,
    button.path-bar,
    button.flat {
      border-radius: 8px;
    }

    button.suggested-action,
    button.default {
      background: #89b4fa;
      color: #11111b;
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

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
    home-manager.users.${hostVariables.username} = {lib, ...}: {
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

      xdg.configFile."swayosd/style.css".text = ''
        window {
          border-radius: 10px;
          background: rgba(30, 30, 46, 0.92);
        }

        #container {
          margin: 16px;
        }

        image,
        label {
          color: #cdd6f4;
        }

        progressbar trough {
          min-height: 8px;
          border-radius: 999px;
          background: rgba(69, 71, 90, 0.9);
        }

        progressbar progress {
          min-height: 8px;
          border-radius: 999px;
          background: #89b4fa;
        }
      '';

      xdg.configFile."hypr/colors.conf".text = ''
        $active_border = rgba(89b4faff)
        $inactive_border = rgba(45475aff)
      '';

      services.easyeffects.enable = true;

      home.file.".config/hypr/scripts".source = hyprlandScripts;

      xdg.configFile."quickshell/qs-hyprview".source = inputs.qs-hyprview;
      xdg.configFile."hypr/config".source = ./hyprland/ilyamiro/config;
      xdg.configFile."hypr/templates".source =
        inputs.ilyamiro-dots + "/config/sessions/hyprland/templates";

      home.activation.removeLegacyIlyamiroCopies = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        rm -rf "$HOME/.config/hypr/config"
        rm -rf "$HOME/.config/hypr/templates"
      '';
    };
  };
}
