{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: {
  options.modules.software.chromium = {
    enable = lib.mkEnableOption "chromium";
  };

  config = lib.mkIf config.modules.software.chromium.enable {
    home-manager.users.${hostVariables.username} = {
      programs.chromium = {
        enable = true;
        package = pkgs.brave.override {
          commandLineArgs = [
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
          ];
        };
        extensions = [
          "jpmkfafbacpgapdghgdpembnojdlgkdl" # AWS Extend Switch Roles
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
          "gppongmhjkpfnbhagpmjfkannfbllamg" # Wappalyzer
          "fmkadmapgofadopljbjfkapdkoienihi" # React Dev Tools
          "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
          "gcknhkkoolaabfmlnjonogaaifnjlfnp" # FoxyProxy
        ];
      };
    };
  };
}