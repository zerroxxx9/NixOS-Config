let
  default = import ./../../variables/defaultVariables.nix;
in
  default
  // {
    host = "home-pc";
    modules =
      default.modules
      // {
        driver =
          default.modules.driver
          // {
            nvidia = true;
          };
        software =
          default.modules.software
          // {
            display-link = true;
          };
          systemSettings =
          default.modules.systemSettings
          // {
            gaming = true;
          };
      };
    git =
      default.git
      // {
        includes = [
          {
            path = "~/Dev/.gitconfig";
            condition = "gitdir:~/Dev/";
          }
        ];
      };
    gnome =
      default.gnome
      // {
        idle-delay = 300;
      };
  }
