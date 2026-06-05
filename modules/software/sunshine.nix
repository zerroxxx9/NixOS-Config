{
  lib,
  pkgs,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.sunshine;
in {
  options.modules.software.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming host for Moonlight";
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = true;

      settings = {
        sunshine_name = hostVariables.host or "nixos";
      };

      applications.apps = [
        {
          name = "Desktop";
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      moonlight-qt
      sunshine
    ];
  };
}
