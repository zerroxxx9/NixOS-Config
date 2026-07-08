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
            tailscale = true;
            vscode = true;
            zed = true;
          };
        gui =
          default.modules.gui
          // {
            hyprland = false;
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
    gnome =
      default.gnome
      // {
        idle-delay = 300;
      };
  }
