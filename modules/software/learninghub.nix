{
  lib,
  config,
  ...
}: let
  learninghubPort = 8450;
  contentDir = "/srv/learninghub";
in {
  options.modules.software.learninghub = {
    enable = lib.mkEnableOption "learninghub";
  };

  config = lib.mkIf config.modules.software.learninghub.enable {
    systemd.tmpfiles.rules = ["d ${contentDir} 0755 ${config.users.users.zerrox.name or "zerrox"} users -"];

    modules.software.tailscale.serve.learninghub = {
      port = learninghubPort;
      target = contentDir;
    };
  };
}
