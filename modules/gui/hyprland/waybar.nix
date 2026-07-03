{
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  colors = config.modules.gui.palette;
  radius = 8;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 34;
          spacing = 8;
          modules-left = ["hyprland/workspaces"];
          modules-center = ["clock"];
          modules-right = ["tray" "network" "pulseaudio" "battery"];
          "hyprland/workspaces" = {
            format = "{icon}";
            persistent-workspaces."*" = 5;
          };
          clock = {
            format = "{:%a %d %b  %H:%M}";
            tooltip-format = "{:%A, %d %B %Y}";
          };
          network = {
            format-wifi = "{essid}";
            format-ethernet = "wired";
            format-disconnected = "offline";
            tooltip-format = "{ifname}: {ipaddr}";
          };
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "muted";
            format-icons.default = ["vol"];
            on-click = "pavucontrol";
          };
          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}%";
            format-charging = "{capacity}%";
          };
          tray = {
            icon-size = 16;
            spacing = 8;
          };
        };
        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: "Inter", "DejaVu Sans", sans-serif;
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background: ${colors.bg1};
            color: ${colors.fg};
            border-bottom: 1px solid ${colors.surface};
          }

          #workspaces button {
            color: ${colors.muted};
            background: transparent;
            padding: 0 10px;
            margin: 5px 1px 4px;
            border-radius: ${toString radius}px;
            border-bottom: 2px solid transparent;
          }

          #workspaces button.active {
            color: ${colors.fgBright};
            background: ${colors.bg2};
            border-bottom-color: ${colors.accentBlue};
          }

          #workspaces button.urgent {
            color: ${colors.fgBright};
            background: ${colors.accentRed};
          }

          #clock,
          #battery,
          #network,
          #pulseaudio,
          #tray {
            color: ${colors.fg};
            background: ${colors.bg2};
            margin: 5px 0 4px;
            padding: 0 10px;
            border-radius: ${toString radius}px;
          }

          #clock {
            color: ${colors.fgBright};
            background: ${colors.surface};
          }

          #battery.warning {
            color: ${colors.accentYellow};
          }

          #battery.critical {
            color: ${colors.fgBright};
            background: ${colors.accentRed};
          }

          #network.disconnected {
            color: ${colors.accentRed};
          }

          #pulseaudio.muted {
            color: ${colors.overlay};
          }

          #tray > .needs-attention {
            color: ${colors.accentRed};
          }
        '';
      };
    };
  };
}
