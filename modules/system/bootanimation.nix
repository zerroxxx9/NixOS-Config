{
  config,
  lib,
  hostVariables,
  ...
}: {
  options.modules.system.bootanimation = {
    enable = lib.mkEnableOption "bootanimation";
  };

  config = lib.mkIf config.modules.system.bootanimation.enable {
    # Plymouth aktivieren
    boot.plymouth.enable = true;

    # Optional: Theme auswählen
    boot.plymouth.theme = "spinner"; # oder "spinner", "fade-in", "text", "tribar" …

    boot.initrd.systemd.enable = true;
  };
}
