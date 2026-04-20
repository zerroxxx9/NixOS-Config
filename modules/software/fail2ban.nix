{ lib, config, ... }:
{
  options.modules.software.fail2ban = {
    enable = lib.mkEnableOption "fail2ban";
  };

  config = lib.mkIf config.modules.software.fail2ban.enable {
    services.fail2ban = {
      enable = true;
      bantime = "1h";
      maxretry = 5;
      bantime-increment = {
        enable = true;
        maxtime = "7d";
        rndtime = "10m";
      };
      ignoreIP = [
        "127.0.0.1/8"
        "::1"
      ];
      jails = lib.mkIf config.services.openssh.enable {
        sshd.settings = {
          mode = "aggressive";
          backend = "systemd";
          findtime = "10m";
          maxretry = 4;
          bantime = "1h";
        };
      };
    };
  };
}
