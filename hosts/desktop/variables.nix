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
            ctf-browser = true;
            noisetorch = true;
            obsidian = true;
            display-link = false;
            tailscale = true;
            tor = true;
            vpn = true;
            vesktop = true;
            spicetify = true;
            vscode = false;
            zed = true;
            librewolf = true;
          };
        gui =
          default.modules.gui
          // {
            gnome = true;
            hyprland = true;
            matugen = true;
            shell = true;
            kinetic-lyrics = true;
          };
        security =
          default.modules.security
          // {
            pentest = true;
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
