#WSL benötigt eigentlich keine klassische hardware-configuration.nix.
{ lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  boot.initrd.enable = false;
  boot.loader.grub.enable = lib.mkForce false;

  #Virtuelles Dateisystem
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=3G" "mode=755" ];
  };
}
