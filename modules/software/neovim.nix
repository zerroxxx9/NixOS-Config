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
          catppuccin-nvim
          bufferline-nvim
          gitsigns-nvim
          indent-blankline-nvim
          lualine-nvim
          nvim-treesitter.withAllGrammars
          nvim-web-devicons
          vim-sensible
          vim-nix
          which-key-nvim
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

          require("catppuccin").setup({
            flavour = "mocha",
            transparent_background = false,
            integrations = {
              bufferline = true,
              gitsigns = true,
              indent_blankline = {
                enabled = true,
              },
              native_lsp = {
                enabled = true,
              },
              treesitter = true,
              which_key = true,
            },
          })
          vim.cmd.colorscheme("catppuccin")

          require("nvim-treesitter.configs").setup({
            highlight = {
              enable = true,
            },
            indent = {
              enable = true,
            },
          })

          require("gitsigns").setup()
          require("ibl").setup()
          require("which-key").setup()

          require("lualine").setup({
            options = {
              component_separators = "",
              globalstatus = true,
              section_separators = "",
              theme = "catppuccin",
            },
          })

          require("bufferline").setup({
            options = {
              diagnostics = "nvim_lsp",
              separator_style = "thin",
              show_buffer_close_icons = false,
              show_close_icon = false,
            },
          })

          vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer" })
          vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
          vim.keymap.set("n", "<tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
          vim.keymap.set("n", "<s-tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })

          ${cfg.extraLuaConfig}
        '';
      };
    };
  };
}
