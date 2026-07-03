{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  colors = config.modules.gui.palette;
  gtkTheme = pkgs.adw-gtk3;
  gtkThemeName = "adw-gtk3-dark";
  wallpaper = ../../assets/wallpaper/zvetru.jpg;
  gtkFileManagerCss = ''
    @define-color accent_color ${colors.accentBlue};
    @define-color accent_bg_color ${colors.accentBlue};
    @define-color accent_fg_color ${colors.black};
    @define-color window_bg_color ${colors.bg1};
    @define-color window_fg_color ${colors.fg};
    @define-color view_bg_color ${colors.bg2};
    @define-color view_fg_color ${colors.fg};
    @define-color headerbar_bg_color ${colors.bg1};
    @define-color headerbar_fg_color ${colors.fgBright};
    @define-color sidebar_bg_color ${colors.black};
    @define-color sidebar_fg_color ${colors.subtle};
    @define-color card_bg_color ${colors.surface};
    @define-color card_fg_color ${colors.fg};
    @define-color popover_bg_color ${colors.bg2};
    @define-color popover_fg_color ${colors.fg};
    @define-color outline_color ${colors.overlay};

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
      background-color: alpha(@outline_color, 0.55);
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
  options.modules.gui.gnome = {
    enable = lib.mkEnableOption "gnome";
  };
  config = lib.mkIf config.modules.gui.gnome.enable {
    modules.gui.alacritty.enable = lib.mkDefault true;

    services.displayManager.gdm = {
      enable = true;
    };
    services.desktopManager.gnome.enable = true;

    environment.systemPackages = with pkgs; [
      dconf-editor
      gnome-tweaks
      gnomeExtensions.dash-to-dock
      gnomeExtensions.user-themes
      gnomeExtensions.system-monitor
      gnomeExtensions.clipboard-history
      gtkTheme
      papirus-icon-theme
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${hostVariables.username} = {
      home.stateVersion = "26.05";

      dconf.settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          disabled-extensions = [];
          enabled-extensions = [
            pkgs.gnomeExtensions.dash-to-dock.extensionUuid
            pkgs.gnomeExtensions.user-themes.extensionUuid
            pkgs.gnomeExtensions.system-monitor.extensionUuid
            pkgs.gnomeExtensions.clipboard-history.extensionUuid
          ];
        };
        "org/gnome/desktop/interface" = {
          clock-show-seconds = true;
          clock-show-weekday = true;
          show-battery-percentage = true;
          color-scheme = "prefer-dark";
          gtk-theme = gtkThemeName;
          icon-theme = "Papirus-Dark";
        };
        "org/gnome/desktop/background" = {
          picture-uri = "file://${wallpaper}";
          picture-uri-dark = "file://${wallpaper}";
          picture-options = "zoom"; # scaled, none, centred, zoom, streched, wallpaper, spanned
        };
        "org/gnome/shell/extensions/user-theme" = {
          name = gtkThemeName;
        };
        "org/gnome/shell/extensions/dash-to-dock" = {
          dock-position = "BOTTOM";
          dock-fixed = true;
          extend-height = true;
          dash-max-icon-size = 38;
          click-action = "minimize-or-previews";
          multi-monitor = true;
          scroll-action = "cycle-windows";
          disable-overview-on-startup = true;
          running-indicator-style = "DOTS";
        };
        "org/gnome/shell" = {
          favorite-apps = hostVariables.gnome.fav-icon;
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = false;
          experimental-features = ["scale-monitor-framebuffer" "xwayland-native-scaling"];
        };
        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = true;
          sort-directories-first = true;
          view-type = "list";
        };
        "org/gtk/settings/file-chooser" = {
          location-mode = "path-bar";
          show-hidden = true;
          show-size-column = true;
          show-type-column = true;
          sort-column = "name";
          sort-directories-first = true;
          sort-order = "ascending";
          type-format = "category";
        };
        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "list-view";
          migrated-gtk-settings = true;
          search-filter-time-type = "last_modified";
          show-create-link = true;
        };
        "org/gnome/nautilus/list-view" = {
          default-visible-columns = [
            "name"
            "size"
            "type"
            "date_modified"
          ];
          default-zoom-level = "small";
        };
        "org/gnome/nautilus/window-state" = {
          maximized = true;
        };
        "org/gnome/settings-daemon/plugins/power" = {
          idle-dim = false;
          sleep-inactive-battery-timeout = 900; # 15min
          sleep-inactive-battery-type = "nothing";
          sleep-inactive-ac-timeout = 900; # 15min
          sleep-inactive-ac-type = "nothing";
          power-button-action = "interactive";
        };
        "org/gnome/desktop/session" = {
          idle-delay = hostVariables.gnome.idle-delay;
        };
        "org/gnome/desktop/screensaver" = {
          lock-enabled = true;
          lock-delay = 0; # 0sec
        };
        "org/gnome/desktop/notifications" = {
          show-in-lock-screen = false;
        };

        # keybindings
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/my-open-terminal/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/my-open-filemanager/"
          ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/my-open-terminal" = {
          name = "Open terminal";
          command = "alacritty";
          binding = "<Super>t";
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/my-open-filemanager" = {
          name = "Open file manager";
          command = "nautilus ./Downloads";
          binding = "<Super>e";
        };
      };

      gtk = {
        enable = true;
        theme = {
          package = gtkTheme;
          name = gtkThemeName;
        };
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus-Dark";
        };
        gtk3.extraCss = gtkFileManagerCss;
        gtk4.extraCss = gtkFileManagerCss;
      };
    };
  };
}
