{
  config,
  lib,
  pkgs,
  hostVariables,
  ...
}: {
  options.modules.software.distrobox = {
    enable = lib.mkEnableOption "distrobox with rootless podman";
  };

  config = lib.mkIf config.modules.software.distrobox.enable {
    virtualisation.containers.enable = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = !config.virtualisation.docker.enable;
      defaultNetwork.settings.dns_enabled = true;
    };

    environment.systemPackages = with pkgs; [
      distrobox
      podman-compose
    ];

    # Rootless containers need lingering so they survive logout
    users.users.${hostVariables.username}.linger = true;
  };
}
