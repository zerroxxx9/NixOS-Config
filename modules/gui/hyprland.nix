{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  wallpaper = ../../assets/wallpaper/zvetru.jpg;
  wallpaperPath = "${wallpaper}";
in {
  imports = [
    ./hyprland/gtk.nix
    ./hyprland/hypridle.nix
    ./hyprland/hyprland.nix
    ./hyprland/hyprlock.nix
    ./hyprland/hyprpaper.nix
    ./hyprland/kitty.nix
    ./hyprland/mako.nix
    ./hyprland/scrolloverview.nix
    ./hyprland/waybar.nix
    ./hyprland/wofi.nix
  ];

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
    home-manager.users.${hostVariables.username} = {pkgs, ...}: {
      home.packages = with pkgs; [
        acpi
        alsa-utils
        bibata-cursors
        papirus-icon-theme
      ];

      home.sessionVariables = {
        WALLPAPER = wallpaperPath;
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
