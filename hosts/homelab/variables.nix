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
      flatpak = false;
      git = true;
      noisetorch = false; #Kein Audio
      vscode = false;
    };
    systemSettings = {
      bootanimation = true;
      gaming = false;
      virtualization = false;
    };
  };
}
