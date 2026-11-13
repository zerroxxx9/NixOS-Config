{
  lib,
  config,
  ...
}: let
  tsCfg = config.modules.software.tailscale;
  domain = tsCfg.domain;

  proxyConfig = target:
    if lib.hasPrefix "https+insecure://" target
    then ''
      reverse_proxy https://${lib.removePrefix "https+insecure://" target} {
        transport http {
          tls_insecure_skip_verify
        }
      }
    ''
    else "reverse_proxy ${target}";
in {
  config = lib.mkIf (domain != null) {
    security.acme = {
      acceptTerms = true;
      defaults.email = "acme@zerrox-sec.com";
      certs.${domain} = {
        domain = "*.${domain}";
        dnsProvider = "cloudflare";
        environmentFile = "/var/lib/secrets/cloudflare-dns-token.env";
        group = config.services.caddy.group;
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts =
        lib.mapAttrs' (
          _: entry:
            lib.nameValuePair "${entry.subdomain}.${domain}" {
              useACMEHost = domain;
              extraConfig = proxyConfig entry.target;
            }
        )
        tsCfg.serve;
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
