{ lib, config, ... }: let
  cfg = config.modules.software.adguard;
in {
  options.modules.software.adguard = {
    enable = lib.mkEnableOption "AdGuard Home";
    tailnetIP = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

    modules.software.tailscale.acceptDNS = false;

    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "127.0.0.1";
      port = 3080;
      settings = {
        users = [{ name = "zerrox"; password = "$2y$05$jCTgucE/kuVs/yV3y8shF.6NB4PjUb.FomoJumdQztaJikHqO8G6i"; }];
        dns = {
          bind_hosts = [cfg.tailnetIP];
          port = 53;
          upstream_dns = [
            "https://dns.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
          ];
          upstream_mode = "parallel";
          bootstrap_dns = ["9.9.9.9" "1.1.1.1"];
          fallback_dns = ["9.9.9.9" "1.1.1.1"];
          enable_dnssec = true;
        };
        filtering.rewrites = [
          { domain = "*.lab.zerrox-sec.com"; answer = cfg.tailnetIP; }
        ];
        filters = [
          { enabled = true; name = "HaGeZi Pro";
            id = 1;
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt"; }
        ];
      };
    };

    services.caddy.virtualHosts."adguard.lab.zerrox-sec.com" = {
      useACMEHost = "lab.zerrox-sec.com";
      extraConfig = "reverse_proxy 127.0.0.1:3080";
    };
  };
}