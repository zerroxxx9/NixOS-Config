{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
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
    };
  };
}
