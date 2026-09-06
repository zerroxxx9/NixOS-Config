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
            distrobox = true;
            ctf = true;
            noisetorch = true;
            obsidian = true;
            osu = true;
            display-link = false;
            lmstudio = true;
            tailscale = true;
            tor = true;
            vesktop = true;
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
            output = "DP-2";
            mode = "2560x1440@239.97";
            position = "0x0";
            scale = 1;
          }
          {
            output = "DP-1";
            mode = "3840x2160@60.00";
            position = "2560x0";
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
