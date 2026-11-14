{ lib, config, pkgs, ... }: let
  cfg = config.modules.software.ntfy;
  domain = "ntfy.lab.zerrox-sec.com";
in {
  options.modules.software.ntfy = {
    enable = lib.mkEnableOption "ntfy";
    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/secrets/ntfy-token";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://${domain}";
        listen-http = "127.0.0.1:2586";
        behind-proxy = true;
        auth-default-access = "deny-all";
        upstream-base-url = "https://ntfy.sh";
      };
    };

    services.caddy.virtualHosts.${domain} = {
      useACMEHost = "lab.zerrox-sec.com";
      extraConfig = "reverse_proxy 127.0.0.1:2586";
    };

    systemd.services."notify-failure@" = {
      serviceConfig.Type = "oneshot";
      scriptArgs = "%i";
      script = ''
        ${pkgs.curl}/bin/curl -fsS \
          -H "Authorization: Bearer $(cat ${cfg.tokenFile})" \
          -H "Title: $1 fehlgeschlagen" -H "Priority: high" -H "Tags: rotating_light" \
          -d "$(${pkgs.systemd}/bin/journalctl -u "$1" -n 15 --no-pager)" \
          https://${domain}/homelab
      '';
    };
  };
}