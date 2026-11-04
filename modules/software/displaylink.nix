{
  config,
  pkgs,
  lib,
  ...
}: {
  options.modules.software.displaylink = {
    enable = lib.mkEnableOption "displaylink";
  };

  config = lib.mkIf config.modules.software.displaylink.enable {
    services.xserver.videoDrivers = ["displaylink" "modesetting" "amdgpu"];
    services.xserver.displayManager.sessionCommands = ''
      ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
    '';

    # The upstream hook blocks forever while opening stale DisplayLink FIFOs
    # when the manager is not running.
    powerManagement.powerDownCommands = lib.mkForce ''
      if systemctl is-active --quiet dlm.service \
        && [ -p /tmp/PmMessagesPort_in ] \
        && [ -p /tmp/PmMessagesPort_out ]; then
        timeout 1 cat /tmp/PmMessagesPort_out >/dev/null || true
        if printf S | timeout 2 tee /tmp/PmMessagesPort_in >/dev/null; then
          timeout 10 head -c 1 /tmp/PmMessagesPort_out >/dev/null || true
        fi
      fi
    '';

    powerManagement.resumeCommands = lib.mkForce ''
      if systemctl is-active --quiet dlm.service \
        && [ -p /tmp/PmMessagesPort_in ]; then
        printf R | timeout 2 tee /tmp/PmMessagesPort_in >/dev/null || true
      fi
    '';
  };
}
