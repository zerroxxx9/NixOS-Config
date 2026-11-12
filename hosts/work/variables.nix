let
  default = import ./../../variables/defaultVariables.nix;
in
  default
  // {
    host = "work";
    modules =
      default.modules
      // {
        driver =
          default.modules.driver
          // {
            amdgpu = true;
          };
        software =
          default.modules.software
          // {
            noisetorch = false;
            obsidian = true;
            display-link = true;
            zed = true;
            opencloud = true;
            collabora = true;
          };
        gui =
          default.modules.gui
          // {
            gnome = false;
            hyprland = true;
            matugen = true;
            shell = true;
          };
        security =
          default.modules.security
          // {
            yubikey = true;
            agenix = true;
          };
      };
    git =
      default.git
      // {
        includes = [
          {
            path = "~/Dev/.gitconfig";
            condition = "gitdir:~/Dev/";
          }
        ];
      };
    hyprland =
      default.hyprland
      // {
        kbLayout = "eu";
        hotplugUsbResetDevices = ["3434:0810"];
        dockDisplay = {
          laptop = "eDP-1";
          dockOutputs = ["DP-8" "DP-9"];
          undockedPosition = "0x0";
          undockedScale = 1;
        };
        monitors = [
          {
            output = "HDMI-A-1";
            mode = "3840x2160@60.00";
            position = "4480x0";
            scale = 1.5;
          }
          {
            output = "DP-1";
            mode = "2560x1440@59.95";
            position = "1920x0";
            scale = 1;
          }
          {
            output = "eDP-1";
            mode = "1920x1200@60.01";
            position = "0x0";
            scale = 1;
          }
          {
            output = "DP-8";
            mode = "preferred";
            position = "0x0";
            scale = 1.5;
          }
          {
            output = "DP-9";
            mode = "preferred";
            position = "2560x0";
            scale = 1.5;
          }
        ];
      };
    gnome =
      default.gnome
      // {
        idle-delay = 300;
      };
  }
