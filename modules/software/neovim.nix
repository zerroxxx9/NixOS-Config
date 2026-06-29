{
  config,
  pkgs,
  lib,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.neovim;
in {
  options.modules.software.neovim = {
    enable = lib.mkEnableOption "neovim";

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        alejandra
        fd
        nil
        ripgrep
        stylua
      ];
      description = "Extra packages available to Neovim.";
    };

    extraLuaConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Lua configuration appended to the base Neovim config.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        withNodeJs = true;
        withPython3 = true;
        extraPackages = cfg.extraPackages;

        plugins = with pkgs.vimPlugins; [
          vim-sensible
          vim-nix
        ];

        extraLuaConfig = ''
          vim.g.mapleader = " "
          vim.g.maplocalleader = " "

          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.signcolumn = "yes"
          vim.opt.cursorline = true

          vim.opt.expandtab = true
          vim.opt.shiftwidth = 2
          vim.opt.tabstop = 2
          vim.opt.smartindent = true

          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.termguicolors = true
          vim.opt.undofile = true
          vim.opt.updatetime = 250

          vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer" })
          vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })

          ${cfg.extraLuaConfig}
        '';
      };
    };
  };
}
