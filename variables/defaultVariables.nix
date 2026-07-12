{
  username = "zerrox";
  host = "default";
  system = "x86_64-linux";
  osLanguage = "en_US.UTF-8";
  keyboardLayout = "de_DE.UTF-8";
  stateVersion = "26.05";
  modules = {
    console = {
      fish = true;
      alacritty = true;
    };
    driver = {
      nvidia = false;
      amdgpu = false;
    };
    gui = {
      gnome = true;
      hyprland = false;
    };
    software = {
      collabora = false;
      chessstack = false;
      display-link = true;
      docker = true;
      couchdb = false;
      fail2ban = false;
      flatpak = false;
      git = true;
      immich = false;
      librewolf = false;
      lmstudio = false;
      nixvim = true;
      noisetorch = true;
      obsidian = false;
      osu = false;
      vscode = false;
      vencord = false;
      tailscale = false;
      opencloud = false;
      paperless-ngx = false;
      spicetify = false;
      sunshine = false;
      mealie = false;
      freshrss = false;
      zed = false;
    };
    security = {
      yubikey = false;
      agenix = false;
    };
    systemSettings = {
      bootanimation = true;
      gaming = false;
      virtualization = false;
    };
  };
  git = {
    lfs = true;
    extraConfig = {
      defaultBranch = "main";
      credential-helper = null;
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
      "obsidian.desktop"
      "vesktop.desktop"
      "spotify.desktop"
      "virtualbox.desktop"
      "dev.zed.Zed.desktop"
    ];
    idle-delay = 0;
  };
}
