{hostVariables, pkgs, ...}: {
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "hm-backup";
  home-manager.overwriteBackup = true;
  home-manager.useUserPackages = true;
  home-manager.users.${hostVariables.username} = {
    # basic home-manager config
    home.username = "${hostVariables.username}";
    home.homeDirectory = "/home/${hostVariables.username}";
    home.stateVersion = hostVariables.stateVersion;
    home.packages = [pkgs.uv];
    programs.home-manager.enable = true;
  };
}
