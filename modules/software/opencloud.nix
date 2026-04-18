{ config, lib, ... }:

{
  services.opencloud = {
    enable = true;
    address = "127.0.0.1";
    port = 9200;
    url = "https://homelab.zerrox.ts.net";
    environmentFile = "/run/secrets/opencloud.env";
  };
}