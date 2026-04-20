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
          { id = "jpmkfafbacpgapdghgdpembnojdlgkdl"; } # AWS Extend Switch Roles
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
          { id = "gppongmhjkpfnbhagpmjfkannfbllamg"; } # Wappalyzer
          { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React Dev Tools
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
          { id = "gcknhkkoolaabfmlnjonogaaifnjlfnp"; } # FoxyProxy
        ];
      };
    };
  };
}