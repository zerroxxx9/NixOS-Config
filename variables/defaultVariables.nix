{
  username = "zerrox";
  host = "default";
  system = "x86_64-linux";
  osLanguage = "en_US.UTF-8";
  keyboardLayout = "de_DE.UTF-8";
  stateVersion = "25.11";
  modules = {
    console = {
      fish = true;
      zsh = false;
    };
    driver = {
      nvidia = false;
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
    };
  };
  git = {
    lfs = true;
    extraConfig = {
      defaultBranch = "main";
      credential-helper = "store";
    };
    credentials = {
      email = "190294721+zerroxxx9@users.noreply.github.com";
      name = "zerroxxx9";
    };
    includes = [];
  };
  gnome = {
    fav-icon = [
      "org.keepassxc.KeePassXC.desktop"
      "org.gnome.Console.desktop"
      "bruno.desktop"
      "idea.desktop"
      "brave-browser.desktop"
      "brave-pjibgclleladliembfgfagdaldikeohf-Default.desktop"
      "brave-cifhbcnohmdccbgoicgdjpfamggdegmo-Default.desktop"
      "brave-faolnafnngnfdaknnbpnkhgohbobgegn-Default.desktop"
      "code.desktop"
    ];
    idle-delay = 0;
  };
}
