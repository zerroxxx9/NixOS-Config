{
  username = "erik";
  host = "default";
  system = "x86_64-linux";
  location = "de_DE.UTF-8";
  stateVersion = "25.11";
  modules = {
    console = {
      fish = false;
    };
    driver = {
      nvidia = true;
      amdgpu = false;
    };
    gui = {
      gnome = true;
    };
    software = {
      display-link = true;
      docker = true;
      flatpak = false;
      git = true;
      noisetorch = true;
      wine = false;
      ollama = false;
    };
    systemSettings = {
      bootanimation = true;
      gaming = false;
      printer = false;
      scanner = false;
    };
  };
  git = {
    lfs = true;
    extraConfig = {
      defaultBranch = "main";
      credential-helper = "store";
    };
    credentials = {
      email = "31123359+Sandbox-Freddy@users.noreply.github.com";
      name = "kushyme";
    };
    includes = [];
  };
  gnome = {
    fav-icon = [
    ];
    idle-delay = 0;
    left-handed = false;
  };
}
