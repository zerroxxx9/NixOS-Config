let
  default = import ./../../variables/defaultVariables.nix;
in
  default
  // {
    host = "desktop";
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
            noisetorch = true;
            obsidian = true;
            osu = true;
            display-link = false;
            lmstudio = true;
            tailscale = true;
            vencord = true;
            spicetify = true;
            sunshine = true;
            vscode = true;
            zed = true;
            librewolf = true;
          };
        gui =
          default.modules.gui
          // {
            gnome = true;
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
