# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  hostVariables,
  ...
}: {
  imports = [
    ./home.nix
  ];
  # Modules
  modules.console.fish.enable = hostVariables.modules.console.fish;
  modules.driver.amdgpu.enable = hostVariables.modules.driver.amdgpu;
  modules.driver.nvidia.enable = hostVariables.modules.driver.nvidia;
  modules.gui.gnome.enable = hostVariables.modules.gui.gnome;
  modules.software.displaylink.enable = hostVariables.modules.software.display-link;
  modules.software.docker.enable = hostVariables.modules.software.docker;
  modules.software.flatpak.enable = hostVariables.modules.software.flatpak;
  modules.software.git.enable = hostVariables.modules.software.git;
  modules.software.noisetorch.enable = hostVariables.modules.software.noisetorch;
  modules.system.bootanimation.enable = hostVariables.modules.systemSettings.bootanimation;
  modules.system.gaming.enable = hostVariables.modules.systemSettings.gaming;

  system.activationScripts.script.text = ''
      cp /home/${hostVariables.username}/.dotfiles/assets/profilePictures/kitty.jpg /var/lib/AccountsService/icons/${hostVariables.username}
    ''; # requires to manually insert the picture via settings due to missing users config

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
