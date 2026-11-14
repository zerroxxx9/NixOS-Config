let
  default = import ../../variables/defaultVariables.nix;
in
  default
  // {
    username = "zerrox";
    host = "zimablade";
    system = "x86_64-linux";
    stateVersion = "26.05";
    # eMMC (28.9G) is the system disk. /dev/sda (3.6T data disk) is NEVER
    # touched by disko, it is only mounted in configuration.nix.
    diskDevice = "/dev/mmcblk0";
    permittedInsecurePackages = ["immich-2.7.5"];
    modules =
      default.modules
      // {
        console =
          default.modules.console
          // {
            fish = true;
            alacritty = false;
          };
        gui =
          default.modules.gui
          // {
            gnome = false; # headless
          };
        software =
          default.modules.software
          // {
            collabora = true;
            chessstack = false;
            display-link = false;
            docker = true;
            couchdb = true;
            flatpak = false;
            git = true;
            immich = true;
            nixvim = false;
            noisetorch = false;
            tailscale = true;
            opencloud = true;
            paperless-ngx = true;
            vscode = false;
            fail2ban = true;
            mealie = false;
            freshrss = true;
            pocket-id = true;
            learninghub = false; # offline until it has content
            smart-home = true;
            zellij = false;
            vaultwarden = true;
            ntfy = true;
            backup = true;
          };
        systemSettings =
          default.modules.systemSettings
          // {
            bootanimation = false;
            gaming = false;
            nas = false; # data disk is local now
            virtualization = false;
          };
      };
  }
