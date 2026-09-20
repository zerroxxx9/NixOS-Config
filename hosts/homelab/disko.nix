# Declarative disk layout for the homelab host.
#
# Apply from a NixOS installer ISO:
#   disko --mode destroy,format,mount --flake /path/to/dotfiles#homelab
#
# The device can be overridden at install time without editing this file:
#   disko-install --flake /path/to/dotfiles#homelab --disk main /dev/nvme0n1
{hostVariables, ...}: {
  disko.devices.disk.main = {
    device = hostVariables.diskDevice;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["fmask=0077" "dmask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
