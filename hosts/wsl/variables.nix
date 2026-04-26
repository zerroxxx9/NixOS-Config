let
  default = import ../../variables/defaultVariables.nix;
in
  default
  // {
    username = "zerrox";
    host = "wsl";
    system = "x86_64-linux";
    stateVersion = "25.11";
    modules =
      default.modules
      // {
        console =
          default.modules.console
          // {
            fish = true;
          };
        driver =
          default.modules.driver
          // {
            nvidia = false;
            amdgpu = false;
          };
        gui =
          default.modules.gui
          // {
            gnome = false; #Kein GUI
          };
        security =
          default.modules.security
          // {
            yubikey = true;
            agenix = true;
          };
        software =
          default.modules.software
          // {
            display-link = false;
            docker = true;
            flatpak = false;
            git = true;
            noisetorch = false; #Kein Audio
            vscode = false;
          };
        systemSettings =
          default.modules.systemSettings
          // {
            bootanimation = false; #Kein Bootloader
            gaming = false;
            virtualization = false;
          };
      };
  }
