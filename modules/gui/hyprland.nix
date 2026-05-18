{
  pkgs,
  lib,
  config,
  hostVariables,
  inputs,
  ...
}: let
  cfg = config.modules.gui.hyprland;
in {
  options.modules.gui.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      bluez
      brightnessctl
      cliphist
      ffmpeg
      grim
      hypridle
      imagemagick
      jq
      kitty
      libnotify
      lm_sensors
      matugen
      mpvpaper
      networkmanager_dmenu
      playerctl
      quickshell
      rofi-wayland
      satty
      slurp
      socat
      swww
      swayosd
      wl-screenrec
      wl-clipboard
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

      home.packages = with pkgs; [
        acpi
        alsa-utils
        bc
        cava
        fd
        fortune
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
        ripgrep
        tree
      ];

      services.swayosd = {
        enable = true;
        topMargin = 0.9;
        stylePath = "/home/${hostVariables.username}/.config/swayosd/style.css";
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

      home.file.".config/hypr/scripts".source =
        inputs.ilyamiro-dots + "/config/sessions/hyprland/scripts";

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
