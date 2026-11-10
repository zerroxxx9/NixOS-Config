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
        dockDisplay = {
          laptop = "eDP-1";
          dockOutputs = ["DP-8" "DP-9"];
        };
        monitors = [
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
          {
            output = "eDP-1";
            mode = "preferred";
            position = "5120x0";
            scale = 1;
          }
        ];
      };
    gnome =
      default.gnome
      // {
        idle-delay = 300;
      };
  }
