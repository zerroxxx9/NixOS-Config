{
  username = "erikp";
  host = "default";
  system = "x86_64-linux";
  osLanguage = "en_US.UTF-8";
  keyboardLayout = "de_DE.UTF-8";
  stateVersion = "25.11";
  modules = {
    console = {
      fish = false;
      zsh = true;
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
    };
  };
  git = {
    lfs = true;
    extraConfig = {
      defaultBranch = "main";
      credential-helper = "store";
    };
    credentials = {
      email = "159010501+kushyme@users.noreply.github.com";
      name = "kushyme";
    };
    includes = [];
  };
  gnome = {
    fav-icon = ["org.gnome.Nautilus.desktop" "discord.desktop"  "brave-browser.desktop" "brave-pjibgclleladliembfgfagdaldikeohf-Default.desktop" "brave-cifhbcnohmdccbgoicgdjpfamggdegmo-Default.desktop" "brave-faolnafnngnfdaknnbpnkhgohbobgegn-Default.desktop" "idea.desktop" "bruno.desktop" "org.keepassxc.KeePassXC.desktop" "obsidian.desktop"];
    idle-delay = 0;
  };
}
