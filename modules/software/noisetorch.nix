{
  pkgs,
  lib,
  config,
  ...
}: {
  options.modules.software.noisetorch = {
    enable = lib.mkEnableOption "noisetorch";
  };

  config = lib.mkIf config.modules.software.noisetorch.enable {
    environment.systemPackages = with pkgs; [
      noisetorch
      pavucontrol
      helvum
      qpwgraph
    ];
  };
}