# Declarative layout for the ZimaBlade system disk (eMMC only).
#
# Only hostVariables.diskDevice (/dev/mmcblk0) is managed here. The data disk
# /dev/sda1 is mounted in configuration.nix and is not part of disko, so
# nixos-anywhere / disko can never format it.
{hostVariables, ...}: {
  disko.devices.disk.main = {
    device = hostVariables.diskDevice;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "512M";
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
            # Fewer writes on eMMC.
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
