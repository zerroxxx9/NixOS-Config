{
  lib,
  config,
  ...
}: let
  cfg = config.modules.software.tor;
in {
  options.modules.software.tor = {
    enable = lib.mkEnableOption "Tor local SOCKS5 client proxy";
  };

  config = lib.mkIf cfg.enable {
    services.tor = {
      enable = true;
      client.enable = true; # SOCKS5 on 127.0.0.1:9050
    };
  };
}
