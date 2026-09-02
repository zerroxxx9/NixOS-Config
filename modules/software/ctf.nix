{
  config,
  lib,
  pkgs,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.ctf;
  containerHome = "/home/${hostVariables.username}";
  # Your actual nvim config/plugins, baked into one self-contained wrapper by
  # the system-level nixvim module — dropping it into the image gets you the
  # exact same editor inside ctf-shell, no extra mounts needed.
  nixvimPackage = config.programs.nixvim.build.package;

  gatewayUpScript = pkgs.writeShellScriptBin "up.sh" ''
    : > /etc/resolv.conf
    for optionvar in $(env | grep -o '^foreign_option_[0-9]*' || true); do
      option="$(eval echo \$$optionvar)"
      case "$option" in
        "dhcp-option DNS "*)
          echo "nameserver ''${option#dhcp-option DNS }" >> /etc/resolv.conf
          ;;
      esac
    done
  '';

  gatewayEntrypoint = pkgs.writeShellScriptBin "entrypoint.sh" ''
    set -e
    config="/vpn/current.ovpn"
    if [ ! -f "$config" ]; then
      echo "ctf-gateway: no VPN config mounted at $config" >&2
      exit 1
    fi
    exec ${pkgs.openvpn}/bin/openvpn --config "$config" --script-security 2 --up ${gatewayUpScript}/bin/up.sh
  '';

  ctfGatewayImage = pkgs.dockerTools.buildLayeredImage {
    name = "ctf-gateway";
    tag = "latest";
    contents = with pkgs; [
      openvpn
      iproute2
      iptables
      procps
      bashInteractive
      coreutils
      cacert
      gatewayUpScript
      gatewayEntrypoint
    ];
    extraCommands = ''
      mkdir -p tmp
      chmod 1777 tmp
      mkdir -p etc root
      cat > etc/passwd <<'EOF'
      root:x:0:0:root:/root:/bin/bash
      EOF
      cat > etc/group <<'EOF'
      root:x:0:
      EOF
      cat > etc/nsswitch.conf <<'EOF'
      hosts: files dns
      EOF
    '';
    config = {
      Entrypoint = ["/bin/entrypoint.sh"];
    };
  };

  ctfToolsImage = pkgs.dockerTools.buildLayeredImage {
    name = "ctf-tools";
    tag = "latest";
    contents = with pkgs; [
      busybox
      bashInteractive
      coreutils
      cacert
      fontconfig
      dejavu_fonts
      glibcLocales
      ncurses
      iproute2
      net-tools
      util-linux
      kmod
      fish
      atuin
      oh-my-posh
      ranger
      tmux
      nixvimPackage
      nmap
      wireshark
      burpsuite
      aircrack-ng
      ghidra
      gdb
      (python3.withPackages (ps: [ps.pwntools]))
      netcat-openbsd
      tcpdump
      john
      hashcat
      feroxbuster
      gobuster
      ffuf
      sqlmap
      thc-hydra
      socat
      openvpn
      wireguard-tools
      proxychains-ng
      subfinder
      httpx
      rustscan
      nikto
      wpscan
      bloodhound
      bloodhound-py
      hashcat-utils
      wordlists
      binwalk
      exiftool
      steghide
      yara
      gitleaks
      syft
      grype
      metasploit
      exploitdb
    ];
    extraCommands = ''
      mkdir -p tmp
      chmod 1777 tmp
      mkdir -p etc root
      cat > etc/passwd <<'EOF'
      root:x:0:0:root:/root:/bin/bash
      EOF
      cat > etc/group <<'EOF'
      root:x:0:
      EOF
      cat > etc/nsswitch.conf <<'EOF'
      hosts: files dns
      EOF
    '';
    config = {
      Cmd = ["/bin/bash"];
      WorkingDir = "/root";
      Env = [
        "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
        "LANG=en_US.UTF-8"
      ];
    };
  };
in {
  options.modules.software.ctf = {
    enable = lib.mkEnableOption "CTF/security tooling containers (rootless podman gateway pattern)";

    vpnConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${hostVariables.username}/ctf/current.ovpn";
      description = "Path to the .ovpn file mounted into the gateway container. `ctf-up` copies the given config here.";
    };

    enableGpu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether ctf-shell should pass /dev/dri into the tools container when present.";
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${hostVariables.username}/ctf/home";
      description = "Host directory mounted as /home/<username> inside ctf-shell: a persistent, writable home for the tools container (loot, downloads, atuin's history db) that's kept separate from your real $HOME.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = ["tun"];
    services.udev.extraRules = ''
      KERNEL=="tun", MODE="0666"
    '';

    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
      extraPackages = [pkgs.slirp4netns pkgs.passt];
    };
    virtualisation.containers.enable = true;

    users.users.${hostVariables.username} = {
      subUidRanges = lib.mkDefault [
        {
          startUid = 100000;
          count = 65536;
        }
      ];
      subGidRanges = lib.mkDefault [
        {
          startGid = 100000;
          count = 65536;
        }
      ];
    };

    home-manager.users.${hostVariables.username} = {
      systemd.user.services.ctf-gateway = {
        Unit = {
          Description = "CTF VPN gateway (OpenVPN via rootless podman)";
        };
        Service = {
          Type = "simple";
          ExecStartPre = [
            "-${pkgs.podman}/bin/podman rm -f ctf-gateway"
            "${pkgs.podman}/bin/podman load -i ${ctfGatewayImage}"
          ];
          ExecStart = ''${pkgs.podman}/bin/podman run --rm --name ctf-gateway --cap-add=NET_ADMIN --device /dev/net/tun -v ${cfg.vpnConfigPath}:/vpn/current.ovpn:ro localhost/ctf-gateway:latest'';
          ExecStop = "${pkgs.podman}/bin/podman stop -t 10 ctf-gateway";
        };
      };

      programs.fish.functions = {
        ctf-up = ''
          set -l ovpn $argv[1]
          if test -z "$ovpn"
            echo "usage: ctf-up <path-to-ovpn>" >&2
            return 1
          end
          if not test -f "$ovpn"
            echo "ctf-up: no such file: $ovpn" >&2
            return 1
          end
          mkdir -p (dirname ${cfg.vpnConfigPath})
          cp -f -- "$ovpn" ${cfg.vpnConfigPath}
          systemctl --user restart ctf-gateway.service
          and echo "ctf-gateway starting with $ovpn"
        '';

        ctf-down = ''
          ${pkgs.podman}/bin/podman rm -f ctf-tools >/dev/null 2>&1
          systemctl --user stop ctf-gateway.service
        '';

        ctf-shell = ''
          if not systemctl --user is-active --quiet ctf-gateway.service
            echo "ctf-gateway is not running — run 'ctf-up <path-to-ovpn>' first" >&2
            return 1
          end
          ${pkgs.podman}/bin/podman load -i ${ctfToolsImage} >/dev/null
          mkdir -p ${cfg.homeDir}

          set -l gpu_args
          ${lib.optionalString cfg.enableGpu ''
            if test -e /dev/dri
              set gpu_args --device /dev/dri
            end
          ''}

          set -l xauth $XAUTHORITY
          if test -z "$xauth"
            set xauth $HOME/.Xauthority
          end
          set -l xauth_args
          if test -f "$xauth"
            set xauth_args -v $xauth:${containerHome}/.Xauthority:ro -e XAUTHORITY=${containerHome}/.Xauthority
          else
            echo "ctf-shell: warning: no Xauthority file found at $xauth, GUI apps may fail to connect to the display" >&2
          end

          # Reuse the host's actual fish config (functions, abbreviations, prompt,
          # atuin integration). fish and everything its config references
          # (atuin, oh-my-posh, ranger, tmux, nixvim) are baked directly into
          # ctf-tools's own image closure, so no /nix/store bind mount is
          # needed — that mount would shadow the image's self-contained
          # /nix/store with the host's, breaking every tool whose store path
          # isn't independently GC-rooted on the host. Layered over the
          # writable ${cfg.homeDir} mount below, so atuin's db (and anything
          # else fish/atuin write) lands there instead of your real $HOME.
          set -l fish_args
          set -l shell_cmd /bin/bash
          if test -d $HOME/.config/fish
            set fish_args -v $HOME/.config/fish:${containerHome}/.config/fish:ro
            if test -d $HOME/.config/atuin
              set fish_args $fish_args -v $HOME/.config/atuin:${containerHome}/.config/atuin:ro
            end
            set shell_cmd ${pkgs.fish}/bin/fish
          else
            echo "ctf-shell: warning: no fish config found at $HOME/.config/fish, falling back to bash" >&2
          end

          # No --userns=keep-id here: rootless podman already maps container
          # root to your own host uid by default (verified — files written
          # to ${cfg.homeDir} still land owned by you), and keep-id would
          # put ctf-tools in its own user namespace, unrelated to
          # ctf-gateway's. Tools like tcpdump/nmap that need CAP_NET_RAW on
          # the shared --network=container:ctf-gateway namespace only get it
          # if they're capable *in the user namespace that owns that netns*
          # — keep-id broke that, silently requiring what looked like sudo.
          ${pkgs.podman}/bin/podman run --rm -it \
            --name ctf-tools \
            --network=container:ctf-gateway \
            --cap-add=NET_RAW --cap-add=NET_ADMIN \
            -e DISPLAY=$DISPLAY \
            -e HOME=${containerHome} \
            -e TERM=$TERM \
            -e TERMINFO_DIRS=${pkgs.ncurses}/share/terminfo \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
            -v ${cfg.homeDir}:${containerHome} \
            $xauth_args \
            $gpu_args \
            $fish_args \
            localhost/ctf-tools:latest \
            $shell_cmd
        '';
      };
    };
  };
}
