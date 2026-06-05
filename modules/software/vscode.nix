{
  pkgs,
  lib,
  inputs,
  config,
  hostVariables,
  system,
  ...
}: let
  inherit (lib) mkDefault;

  cfg = config.modules.software.vscode;

  pkgs-ext = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [inputs.nix-vscode-extensions.overlays.default];
  };

  my-vscode-extension-sets = with pkgs-ext;
    lib.foldl' (acc: set: pkgs.lib.recursiveUpdate acc set)
    {}
    [
      vscode-marketplace
      open-vsx
      vscode-marketplace-release
      open-vsx-release
    ];

  defaultExtensions = with my-vscode-extension-sets; [
    # general
    ms-azuretools.vscode-docker
    ms-vscode-remote.remote-ssh
    ms-vscode.hexeditor
    pkief.material-icon-theme
    github.github-vscode-theme

    # nix & flake support
    bbenoist.nix
    mkhl.direnv
  ];

  defaultSettings = {
    "editor.wordWrap" = "on";
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace', monospace";
    "terminal.integrated.fontSize" = 14;
    "markdown.preview.fontSize" = 20;
    "files.autoSave" = "onFocusChange";
    "git.blame.editorDecoration.enabled" = true;
    "task.allowAutomaticTasks" = "off";
    "workbench.colorTheme" = "GitHub Dark";
    "workbench.iconTheme" = "material-icon-theme";
  };
in {
  options.modules.software.vscode = {
    enable = lib.mkEnableOption "vscode";

    default-extensions.enable = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to install the default extensions.";
      default = true;
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "List of VS Code extensions to install.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "VS Code settings to merge with defaults.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (unstable.vscode-with-extensions.override {
        vscodeExtensions =
          lib.optionals cfg.default-extensions.enable defaultExtensions
          ++ cfg.extensions;
      })
    ];

    home-manager.users.${hostVariables.username}.home.file.".config/Code/User/settings.json".text = builtins.toJSON (lib.recursiveUpdate defaultSettings cfg.settings);
  };
}
