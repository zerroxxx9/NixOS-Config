let default = import ../../variables/defaultVariables.nix; in
default // {
  username = "zerrox";
  host = "homelab";
  system = "x86_64-linux";
  stateVersion = "25.11";
  modules = default.modules // {
    console = {
      fish = true;
    };
    driver = {
      nvidia = false;
      amdgpu = false;
    };
    gui = {
      gnome = false; #Kein GUI
    };
    software = {
      display-link = false;
      docker = true;
      couchdb = true;
      flatpak = false;
      git = true;
      immich = true;
      noisetorch = false; #Kein Audio
      tailscale = true;
      opencloud = true;
      paperless-ngx = true;
      vscode = false;
      fail2ban = true;
    };
    systemSettings = {
      bootanimation = true;
      gaming = false;
      virtualization = false;
    };
  };
}
