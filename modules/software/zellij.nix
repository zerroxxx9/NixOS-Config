{
  config,
  lib,
  hostVariables,
  pkgs,
  ...
}: {
  options.modules.software.zellij.enable = lib.mkEnableOption "zellij";

  config = lib.mkIf config.modules.software.zellij.enable {
    programs.nix-ld.enable = true;

    environment.systemPackages = with pkgs; [
      nil
      nixd
    ];

    home-manager.users.${hostVariables.username} = {
    programs.zellij = {
      enable = true;
    };
    };
  };
}