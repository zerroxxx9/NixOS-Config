{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.software.lmstudio.enable = lib.mkEnableOption "LM Studio";

  config = lib.mkIf config.modules.software.lmstudio.enable {
    environment.systemPackages = [
      pkgs.unstable.lmstudio
    ];
  };
}
