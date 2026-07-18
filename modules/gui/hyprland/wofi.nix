{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  radius = 18;

  hexDigit = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    a = 10;
    b = 11;
    c = 12;
    d = 13;
    e = 14;
    f = 15;
  };

  hexPairToInt = pair:
    (hexDigit.${builtins.substring 0 1 pair} * 16)
    + hexDigit.${builtins.substring 1 1 pair};

  rgbComponent = color: offset:
    hexPairToInt (builtins.substring offset 2 (lib.removePrefix "#" color));

  gtkRgba = color: alpha:
    "rgba(${toString (rgbComponent color 0)}, ${toString (rgbComponent color 2)}, ${toString (rgbComponent color 4)}, ${alpha})";
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.wofi = {
        enable = true;

        settings = {
          show = "drun";

          allow_images = true;
          allow_markup = true;
          close_on_focus_loss = true;

          columns = 1;
          display_generic = true;

          filter_rate = 50;
          gtk_dark = true;
          hide_scroll = true;

          image_size = 36;

          insensitive = true;

          key_down = "Down";
          key_up = "Up";
          key_submit = "Return";
          key_exit = "Escape";
          key_forward = "Ctrl-Tab";

          location = "center";
          matching = "fuzzy";

          no_custom_entry = true;
          parse_search = true;

          prompt = "Search Applications...";

          sort_order = "default";
          use_search_box = true;

          width = 680;
          height = 470;
        };

        style = ''
          * {
            font-family: "Inter", "DejaVu Sans", sans-serif;
            font-size: 14px;
            color: ${colors.fg};
            outline: none;
            box-shadow: none;
          }

          window,
          #window {
            background: ${gtkRgba colors.bg1 "0.88"};
            border-radius: ${toString radius}px;
            border: 1px solid ${gtkRgba colors.overlay "0.20"};
          }

          #outer-box {
            background: transparent;
            padding: 24px;
          }

          #inner-box,
          #scroll {
            background: transparent;
            margin: 0;
            padding: 0;
          }

          #input {
            background: ${gtkRgba colors.bg2 "0.72"};
            color: ${colors.fgBright};

            border: none;
            border-radius: 14px;

            padding: 14px 18px;
            margin: 0 0 18px;

            min-height: 26px;
            caret-color: ${colors.fgBright};
          }

          #input:focus {
            background: ${gtkRgba colors.bg2 "0.82"};
          }

          #entry {
            background: transparent;

            border: 1px solid transparent;
            border-radius: 12px;

            padding: 11px 14px;
            margin: 4px 0;

            min-height: 42px;

            transition: all 150ms ease;
          }

          #entry:hover {
            background: ${gtkRgba colors.surface "0.30"};
          }

          #entry:selected {
            background: ${gtkRgba colors.surface "0.72"};
            border-color: ${gtkRgba colors.overlay "0.36"};
          }

          #entry #img {
            margin-right: 14px;
          }

          #text {
            color: ${colors.fg};
            margin-left: 6px;
          }

          #entry:selected #text {
            color: ${colors.fgBright};
            font-weight: 500;
          }

          scrollbar {
            opacity: 0;
          }
        '';
      };
    };
  };
}