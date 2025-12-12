{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: {
  options.modules.console.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf config.modules.console.zsh.enable {
    programs.zsh.enable = true;
    users.users.${hostVariables.username}.shell = pkgs.zsh;

    home-manager.users.${hostVariables.username} = {
      home.packages = with pkgs; [
        zsh-autosuggestions
        zsh-syntax-highlighting
      ];
      programs.zsh = {
        enable = true;
        enableCompletion = true;

        oh-my-zsh = {
          enable = true;
          plugins = ["git" "zsh-autosuggestions" "zsh-syntax-highlighting"];
          theme = "robbyrussell";
        };
      };
    };
  };
}
