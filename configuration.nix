{
  pkgs,
  hostVariables,
  lib,
  ...
}: {
  imports = [
    ./home.nix
  ];

  # Modules
  modules.console.fish.enable = lib.attrByPath ["modules" "console" "fish"] false hostVariables;
  modules.driver.amdgpu.enable = lib.attrByPath ["modules" "driver" "amdgpu"] false hostVariables;
  modules.driver.nvidia.enable = lib.attrByPath ["modules" "driver" "nvidia"] false hostVariables;
  modules.gui.gnome.enable = lib.attrByPath ["modules" "gui" "gnome"] false hostVariables;
  modules.software.displaylink.enable = lib.attrByPath ["modules" "software" "display-link"] false hostVariables;
  modules.software.docker.enable = lib.attrByPath ["modules" "software" "docker"] false hostVariables;
  modules.software.couchdb.enable = lib.attrByPath ["modules" "software" "couchdb"] false hostVariables;
  modules.software.fail2ban.enable = lib.attrByPath ["modules" "software" "fail2ban"] false hostVariables;
  modules.software.flatpak.enable = lib.attrByPath ["modules" "software" "flatpak"] false hostVariables;
  modules.software.git.enable = lib.attrByPath ["modules" "software" "git"] false hostVariables;
  modules.software.immich.enable = lib.attrByPath ["modules" "software" "immich"] false hostVariables;
  modules.software.noisetorch.enable = lib.attrByPath ["modules" "software" "noisetorch"] false hostVariables;
  modules.software.opencloud.enable = lib.attrByPath ["modules" "software" "opencloud"] false hostVariables;
  modules.software.tailscale.enable = lib.attrByPath ["modules" "software" "tailscale"] false hostVariables;
  modules.software.paperless-ngx.enable = lib.attrByPath ["modules" "software" "paperless-ngx"] false hostVariables;
  modules.system.bootanimation.enable = lib.attrByPath ["modules" "systemSettings" "bootanimation"] false hostVariables;
  modules.system.gaming.enable = lib.attrByPath ["modules" "systemSettings" "gaming"] false hostVariables;

  modules.security.yubikey.enable = lib.attrByPath ["modules" "security" "yubikey"] false hostVariables;
  modules.security.agenix.enable = lib.attrByPath ["modules" "security" "agenix"] false hostVariables;

  system.activationScripts.script.text = lib.optionalString (lib.attrByPath ["modules" "gui" "gnome"] false hostVariables) ''
    cp /home/${hostVariables.username}/.dotfiles/assets/profilePictures/kitty.jpg /var/lib/AccountsService/icons/${hostVariables.username}
  '';

  environment.systemPackages = with pkgs; [
    alejandra
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  programs.nh = {
    enable = true;
    flake = "/home/${hostVariables.username}/.dotfiles";
  };
}
