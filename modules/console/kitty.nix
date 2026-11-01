{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: {
  options.modules.gui.kitty = {
    enable = lib.mkEnableOption "kitty";
  };

  config = lib.mkIf config.modules.gui.kitty.enable {
    home-manager.users.${hostVariables.username} = {
      programs.kitty = {
        enable = true;
        font = {
          name = "Geist Mono";
          size = 11;
        };
        settings = {
          shell = "${pkgs.fish}/bin/fish";
          background_opacity = "0.5";
          window_padding_width = 8;
          cursor_trail = 3;
          cursor_trail_decay = "0.1 0.4";
          cursor_trail_start_threshold = 2;
          confirm_os_window_close = 0;
        };
      };
    };
  };
}
