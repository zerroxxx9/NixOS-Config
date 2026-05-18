{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml";
        before_sleep_cmd = "quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
