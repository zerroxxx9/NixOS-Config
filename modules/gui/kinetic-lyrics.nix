{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.kinetic-lyrics;

  primaryOutput = let
    monitors = lib.attrByPath ["hyprland" "monitors"] [] hostVariables;
  in
    if monitors == []
    then ""
    else (builtins.head monitors).output;

  defaults = {
    output = primaryOutput; # "" = every monitor
    providers = ["apple-music" "binilyrics" "lrclib"];

    capsFont = "";
    scriptFont = "";
    uppercase = true;
    scriptMaxLetters = 2;
    color = "#e8962c";
    colorSource = "lyrics";
    colorsFile = "/home/${hostVariables.username}/.local/state/matugen/theme.json";
    shadow = true;
    heroSize = 150;
    bigSize = 108;
    midSize = 88;
    scriptSize = 78;
    wordGap = 18;

    position = "right";
    horizontalMargin = 90;
    verticalOffset = 0;
    columnWidth = 40;
    maxWidth = 780;
    rowAlign = "end";

    wordByWord = true;
    wordInMs = 280;
    wordSpread = 60;
    lineFadeMs = 250;
    wobble = true;
    offsetMs = 0;
    tickMs = 100;
  };
  settings = defaults // cfg.settings;

  settingsQml = ''
    import QtQuick

    QtObject {
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "    property var ${k}: ${builtins.toJSON v}") settings)}
    }
  '';
in {
  options.modules.gui.kinetic-lyrics = {
    enable = lib.mkEnableOption "kinetic-lyrics";
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Overrides for the `defaults` set at the top of this module.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      home.packages = [pkgs.quickshell];

      xdg.configFile = {
        "quickshell/kinetic-lyrics" = {
          source = ./kinetic-lyrics;
          recursive = true;
        };
        "quickshell/kinetic-lyrics/Settings.qml".text = settingsQml;
      };

      systemd.user.services.kinetic-lyrics = {
        Unit = {
          Description = "Kinetic Lyrics desktop overlay";
          PartOf = ["hyprland-session.target"];
          After = ["hyprland-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.quickshell}/bin/quickshell -c kinetic-lyrics";
          Restart = "on-failure";
          NoNewPrivileges = true;
          RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        };
        Install.WantedBy = ["hyprland-session.target"];
      };
    };
  };
}
