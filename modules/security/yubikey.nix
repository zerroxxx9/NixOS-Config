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
    # YubiKey Hardware-Erkennung (udev rules, smartcard daemon)
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.pcscd.enable = true;

    # Tools
    environment.systemPackages = with pkgs; [
      yubikey-personalization  # ykman CLI
      yubikey-manager          # YubiKey Manager GUI + CLI
      age-plugin-yubikey       # Age-Verschlüsselung direkt mit YubiKey PIV
      yubioath-flutter         # Yubico Authenticator (TOTP)
    ];

    # SSH: FIDO2-backed Keys (ed25519-sk)
    programs.ssh.startAgent = lib.mkIf config.modules.security.yubikey.enableSSH true;

    # Optional: PAM U2F — YubiKey für sudo/Login voraussetzen
    security.pam.u2f = lib.mkIf config.modules.security.yubikey.enablePAM {
      enable = true;
      settings = {
        cue = true;          # "Bitte YubiKey berühren" Hinweis
        authFile = "/etc/u2f_mappings"; # Mapping-Datei (siehe Setup-Anleitung unten)
      };
    };

    # GnuPG-Agent mit Smartcard-Support (falls du GPG auf dem YubiKey nutzt)
    home-manager.users.${hostVariables.username} = {
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        enableSshSupport = false; # true setzen falls du GPG statt FIDO2 für SSH nutzt
        pinentryPackage = pkgs.pinentry-gnome3;
      };
    };
  };
}