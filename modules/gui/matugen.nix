{
  pkgs,
  lib,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.gui.matugen;
  home = "/home/${hostVariables.username}";
  state = "${home}/.local/state/matugen";
  templates = ./matugen/templates;

  obsidianCfg = config.modules.software.obsidian;
  optionalTemplate = cond: text: lib.optionalString cond text;

  matugenConfig = pkgs.writeText "matugen-config.toml" ''
    [config]

    [templates.gtk3]
    input_path = "${templates}/gtk.css"
    output_path = "${home}/.config/gtk-3.0/matugen.css"

    [templates.gtk4]
    input_path = "${templates}/gtk.css"
    output_path = "${home}/.config/gtk-4.0/matugen.css"

    [templates.kitty]
    input_path = "${templates}/kitty.conf"
    output_path = "${home}/.config/kitty/matugen.conf"

    [templates.rofi]
    input_path = "${templates}/rofi.rasi"
    output_path = "${home}/.config/rofi/matugen.rasi"

    [templates.shell]
    input_path = "${templates}/theme.json"
    output_path = "${state}/theme.json"

    [templates.hypr]
    input_path = "${templates}/hypr.lua"
    output_path = "${home}/.config/hypr/matugen.lua"

    [templates.zellij]
    input_path = "${templates}/zellij.kdl"
    output_path = "${home}/.config/zellij/themes/matugen.kdl"

    [templates.mako]
    input_path = "${templates}/mako.conf"
    output_path = "${home}/.config/mako/matugen"

    [templates.hyprlock]
    input_path = "${templates}/hyprlock.conf"
    output_path = "${home}/.config/hypr/hyprlock-colors.conf"

    [templates.alacritty]
    input_path = "${templates}/alacritty.toml"
    output_path = "${home}/.config/alacritty/themes/matugen.toml"

    [templates.zed]
    input_path = "${templates}/zed.json"
    output_path = "${home}/.config/zed/themes/matugen.json"

    [templates.vscode]
    input_path = "${templates}/vscode.json"
    output_path = "${state}/vscode-theme.json"

    [templates.vesktop]
    input_path = "${templates}/vesktop.css"
    output_path = "${home}/.config/vesktop/themes/matugen.theme.css"

    ${optionalTemplate obsidianCfg.enable ''
      [templates.obsidian]
      input_path = "${templates}/obsidian.css"
      output_path = "${home}/${obsidianCfg.vaultPath}/.obsidian/snippets/matugen.css"
    ''}
    ${optionalTemplate config.modules.software.spicetify.enable ''
      [templates.spotify]
      input_path = "${templates}/spotify.json"
      output_path = "${state}/spotify/colors.json"
    ''}
    ${optionalTemplate config.modules.software.librewolf.enable ''
      [templates.librewolf]
      input_path = "${templates}/librewolf.css"
      output_path = "${home}/.librewolf/default/chrome/matugen.css"
    ''}
  '';

  # The theme JSON is rendered into the state dir; the extension only links to
  # it, so VS Code picks up a new palette on "Developer: Reload Window".
  vscodeExtension = pkgs.runCommand "matugen-vscode-theme" {} ''
    dir=$out/share/vscode/extensions/local.matugen-theme
    mkdir -p $dir/themes
    ln -s ${state}/vscode-theme.json $dir/themes/matugen.json
    cat > $dir/package.json <<'EOF'
    {
      "name": "matugen-theme",
      "displayName": "Matugen",
      "publisher": "local",
      "version": "1.0.0",
      "engines": {"vscode": "*"},
      "contributes": {
        "themes": [{"label": "Matugen", "uiTheme": "vs-dark", "path": "./themes/matugen.json"}]
      }
    }
    EOF
  '';

  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [pkgs.matugen pkgs.imagemagick pkgs.python3 pkgs.procps pkgs.awww pkgs.hyprland pkgs.mako];
    text = ''
      export MATUGEN_CONFIG=${matugenConfig}
      export MATUGEN_PALETTE=${./matugen/palette.toml}
      exec python3 -I ${./matugen/set-wallpaper.py} "$@"
    '';
  };
in {
  options.modules.gui.matugen = {
    enable = lib.mkEnableOption "matugen wallpaper theming";
  };

  config = lib.mkIf cfg.enable {
    modules.gui.kitty.enable = lib.mkDefault true;
    modules.software.vscode.extensions = [
      (vscodeExtension // {
        version = "1.0.0";
        vscodeExtUniqueId = "local.matugen-theme";
        vscodeExtPublisher = "local";
        vscodeExtName = "matugen-theme";
      })
    ];
    environment.systemPackages = [setWallpaper pkgs.matugen pkgs.rofi];

    home-manager.users.${hostVariables.username} = {
      home.packages = [pkgs.awww];

      # Wallpaper daemon; `awww restore` brings back the last image on login.
      systemd.user.services.awww-daemon = {
        Unit = {
          Description = "awww wallpaper daemon";
          PartOf = ["hyprland-session.target"];
          After = ["hyprland-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          ExecStartPost = "${pkgs.bash}/bin/bash -c 'sleep 1; ${pkgs.awww}/bin/awww restore'";
          Restart = "on-failure";
        };
        Install.WantedBy = ["hyprland-session.target"];
      };

      programs.kitty.extraConfig = ''
        include matugen.conf
      '';

      programs.starship = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          add_newline = false;
          format = "[╭](bright-black) $directory$python$nix_shell$git_branch$git_status$fill$time\n[╰](bright-black)$character";
          fill.symbol = " ";
          directory = {
            style = "blue";
            format = "[$path]($style) ";
            truncation_length = 3;
          };
          python = {
            symbol = "🐍 ";
            format = "[$symbol($version)]($style) ";
            style = "yellow";
          };
          nix_shell = {
            symbol = " ";
            format = "[$symbol$state]($style) ";
            style = "cyan";
          };
          git_branch = {
            symbol = " ";
            format = "[$symbol$branch]($style) ";
            style = "magenta";
          };
          git_status = {
            format = "[$all_status$ahead_behind]($style) ";
            style = "red";
          };
          time = {
            disabled = false;
            format = "[$time]($style)";
            style = "bright-black";
            time_format = "%H:%M";
          };
          character = {
            success_symbol = "[❯](green) ";
            error_symbol = "[❯](red) ";
          };
        };
      };

      programs.fastfetch = {
        enable = true;
        settings = {
          logo = {
            source = "nixos";
            padding = {
              right = 3;
            };
          };
          display = {
            separator = "  ";
            color.keys = "blue";
          };
          modules = [
            {
              type = "custom";
              format = "╭─ ${hostVariables.username}";
            }
            {
              type = "os";
              key = "│ os ";
            }
            {
              type = "kernel";
              key = "│ ker";
            }
            {
              type = "wm";
              key = "│ wm ";
            }
            {
              type = "cpu";
              key = "│ cpu";
            }
            {
              type = "gpu";
              key = "│ gpu";
            }
            {
              type = "memory";
              key = "│ ram";
            }
            {
              type = "disk";
              key = "│ ssd";
            }
            {
              type = "packages";
              key = "│ pkg";
            }
            {
              type = "custom";
              format = "╰──────";
            }
            "break"
            {
              type = "colors";
              symbol = "circle";
              paddingLeft = 0;
            }
          ];
        };
      };

      xdg.configFile."rofi/config.rasi".text = ''
        configuration {
          modes: "drun,window";
          show-icons: true;
          drun-display-format: "{name}\n<span size='small' alpha='65%'>{comment}</span>";
          font: "JetBrainsMono Nerd Font 11";
        }
        @theme "matugen"
      '';

    };
  };
}
