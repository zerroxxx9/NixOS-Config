let
  default = import ../../variables/defaultVariables.nix;
in
  default
  // {
    username = "zerrox";
    host = "raspberry-pi";
    buildSystem = "x86_64-linux";
    system = "armv6l-linux";
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
            agenix = false;
          };
        software =
          default.modules.software
          // {
            collabora = false;
            display-link = false;
            docker = false;
            couchdb = false;
            flatpak = false;
            git = true;
            immich = false;
            noisetorch = false; #Kein Audio
            tailscale = true;
            opencloud = false;
            paperless-ngx = false;
            vscode = false;
            fail2ban = false;
          };
        systemSettings =
          default.modules.systemSettings
          // {
            bootanimation = false;
            gaming = false;
            virtualization = false;
          };
      };
  }
