{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.vpn;
  user = hostVariables.username;
  platforms = ["htb" "thm"];
in {
  options.modules.software.vpn.enable = lib.mkEnableOption "CTF VPN services";

  config = lib.mkIf cfg.enable {
    services.openvpn.servers = lib.genAttrs platforms (name: {
      autoStart = false;
      config = "config /home/${user}/vpn/${name}.ovpn";
    });

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${user}" &&
            /^openvpn-.*\.service$/.test(action.lookup("unit"))) {
          return polkit.Result.YES;
        }
      });
    '';

    home-manager.users.${user}.programs.fish.functions.vpn = ''
      set -l platforms ${lib.concatStringsSep " " platforms}
      switch "$argv[1]"
        case status
          for p in $platforms
            printf '%s: %s\n' $p (systemctl is-active openvpn-$p.service)
          end
        case ${lib.concatStringsSep " " platforms}
          switch "$argv[2]"
            case up
              systemctl start openvpn-$argv[1].service
            case down
              systemctl stop openvpn-$argv[1].service
            case '*'
              echo "usage: vpn <${lib.concatStringsSep "|" platforms}> <up|down>" >&2
              return 2
          end
        case '*'
          echo "usage: vpn <${lib.concatStringsSep "|" platforms}> <up|down> | vpn status" >&2
          return 2
      end
    '';
  };
}
