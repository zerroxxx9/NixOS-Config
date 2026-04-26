{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: {
  options.modules.security.yubikey = {
    enable = lib.mkEnableOption "YubiKey support";

    enableSSH = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable FIDO2-backed SSH keys (ed25519-sk).";
    };

    enablePAM = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to require YubiKey for sudo/login (PAM U2F).";
    };
  };

  config = lib.mkIf config.modules.security.yubikey.enable {
    services.udev.packages = [pkgs.yubikey-personalization];
    services.pcscd.enable = true;

    environment.systemPackages = with pkgs; [
      yubikey-personalization
      yubikey-manager
      age
      age-plugin-yubikey
      yubioath-flutter
    ];

    # FIDO2-backed SSH keys are fine for Git/SSH, but agenix admin decrypt
    # should use age-plugin-yubikey with a dedicated age identity.
    programs.ssh.startAgent = lib.mkDefault (config.modules.security.yubikey.enableSSH && !config.services.gnome.gcr-ssh-agent.enable);

    security.pam.u2f = lib.mkIf config.modules.security.yubikey.enablePAM {
      enable = true;
      settings = {
        cue = true;
        authFile = "/etc/u2f_mappings";
      };
    };

    home-manager.users.${hostVariables.username} = {
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        enableSshSupport = false;
        pinentry.package = pkgs.pinentry-gnome3;
      };
    };
  };
}
