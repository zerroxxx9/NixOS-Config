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
            display-link = false;
            distrobox = true;
            tailscale = true;
            vscode = true;
            zed = true;
          };
        gui =
          default.modules.gui
          // {
            gnome = false;
            hyprland = true;
            noctalia = true;
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
        monitors = [
          {
            output = "eDP-1";
            mode = "preferred";
            position = "auto";
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
