{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.nixvim;
in {
  options.modules.software.nixvim = {
    enable = lib.mkEnableOption "nixvim";

    autoSave = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically save modified buffers after editing pauses or focus changes.";
    };

    copilot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GitHub Copilot integration for nvim-cmp.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      nixpkgs.source = inputs.nixpkgs;

      extraPackages = with pkgs; [
        alejandra
        fd
        nil
        nodejs_24
        prettierd
        ripgrep
        shellcheck
        shfmt
        stylua
      ];

      colorschemes.gruvbox.enable = true;

      opts = {
        number = true;
        relativenumber = true;
        signcolumn = "yes";
        cursorline = true;
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        smartindent = true;
        ignorecase = true;
        smartcase = true;
        termguicolors = true;
        undofile = true;
        updatetime = 250;
        hidden = true;
        showtabline = 2;
        laststatus = 3;
        splitbelow = true;
        splitright = true;
        scrolloff = 8;
        sidescrolloff = 8;
        completeopt = "menu,menuone,noselect";
        mouse = "a";
        clipboard = "unnamedplus";
        wrap = false;
        foldlevelstart = 99;
        swapfile = false;
        backup = false;
        writebackup = false;
        list = true;
        listchars = "tab:  ,trail:.,extends:>,precedes:<,nbsp:+";
      };

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      diagnostic.settings = {
        virtual_text = true;
        signs = true;
        underline = true;
        update_in_insert = false;
        severity_sort = true;
      };

      autoGroups.nixvim_ide_layout.clear = true;
      autoCmd = [
        {
          event = "VimEnter";
          group = "nixvim_ide_layout";
          desc = "Open file explorer on startup";
          command = "Neotree action=show source=filesystem position=left";
        }
      ];

      plugins = {
        web-devicons.enable = true;
        fidget.enable = true;
        auto-save = {
          enable = cfg.autoSave;
          settings = {
            trigger_events = {
              immediate_save = [
                "BufLeave"
                "FocusLost"
              ];
              defer_save = [
                "InsertLeave"
                "TextChanged"
              ];
              cancel_deferred_save = ["InsertEnter"];
            };
            debounce_delay = 1000;
            condition = ''
              function(buf)
                local filename = vim.api.nvim_buf_get_name(buf)
                local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = buf })
                local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })

                return filename ~= "" and modifiable and buftype == ""
              end
            '';
          };
        };

        lualine = {
          enable = true;
          settings = {
            options = {
              theme = "gruvbox";
              globalstatus = true;
              disabled_filetypes = {
                statusline = [
                  "neo-tree"
                  "Trouble"
                ];
              };
            };
            sections = {
              lualine_a = ["mode"];
              lualine_b = [
                "branch"
                "diff"
                "diagnostics"
              ];
              lualine_c = [
                {
                  __unkeyed-1 = "filename";
                  path = 1;
                }
              ];
              lualine_x = [
                "encoding"
                "fileformat"
                "filetype"
              ];
              lualine_y = ["progress"];
              lualine_z = ["location"];
            };
          };
        };

        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = false;
            signs = {
              add.text = "+";
              change.text = "~";
              delete.text = "_";
              topdelete.text = "^";
              changedelete.text = "~";
              untracked.text = "+";
            };
          };
        };

        which-key = {
          enable = true;
          settings = {
            delay = 300;
            preset = "modern";
          };
        };

        nvim-autopairs = {
          enable = true;
          settings = {
            check_ts = true;
            disable_filetype = [
              "TelescopePrompt"
              "vim"
            ];
          };
        };
        trouble.enable = true;

        bufferline = {
          enable = true;
          settings.options = {
            mode = "buffers";
            always_show_bufferline = true;
            show_buffer_icons = true;
            show_buffer_close_icons = true;
            show_close_icon = false;
            separator_style = "slant";
            diagnostics = "nvim_lsp";
            offsets = [
              {
                filetype = "neo-tree";
                text = "File Explorer";
                text_align = "center";
                separator = true;
              }
            ];
          };
        };

        neo-tree = {
          enable = true;
          settings = {
            close_if_last_window = true;
            enable_git_status = true;
            enable_diagnostics = true;
            default_component_configs = {
              indent.with_expanders = true;
              git_status.symbols = {
                added = "+";
                deleted = "-";
                modified = "~";
                renamed = "R";
                untracked = "?";
                ignored = "I";
                unstaged = "U";
                staged = "S";
                conflict = "!";
              };
            };
            filesystem = {
              follow_current_file.enabled = true;
              filtered_items.visible = true;
            };
            window = {
              position = "left";
              width = 32;
            };
          };
        };

        telescope = {
          enable = true;
          extensions = {
            fzf-native.enable = true;
            ui-select.enable = true;
          };
          settings.defaults = {
            file_ignore_patterns = [
              ".git/"
              "node_modules/"
              "result"
            ];
            layout_config.prompt_position = "top";
            sorting_strategy = "ascending";
          };
          keymaps = {
            "<leader>ff" = "find_files";
            "<leader>fg" = "live_grep";
            "<leader>fb" = "buffers";
            "<leader>fh" = "help_tags";
            "<leader>fr" = "oldfiles";
          };
        };

        treesitter = {
          enable = true;
          nixvimInjections = true;
          highlight.enable = true;
          indent.enable = true;
          folding.enable = true;
        };

        treesitter-context.enable = true;
        treesitter-textobjects = {
          enable = true;
          settings.select = {
            enable = true;
            lookahead = true;
          };
        };

        lsp = {
          enable = true;
          inlayHints = true;

          keymaps = {
            silent = true;
            diagnostic = {
              "[d" = "goto_prev";
              "]d" = "goto_next";
              "<leader>de" = "open_float";
              "<leader>dl" = "setloclist";
            };
            lspBuf = {
              "K" = "hover";
              "gd" = "definition";
              "gD" = "declaration";
              "gi" = "implementation";
              "gr" = "references";
              "<leader>rn" = "rename";
              "<leader>ca" = "code_action";
            };
          };

          servers = {
            nil_ls.enable = true;
            lua_ls.enable = true;
            bashls.enable = true;
            jsonls.enable = true;
            yamlls.enable = true;
            ts_ls.enable = true;
            pyright.enable = true;
            html.enable = true;
            cssls.enable = true;
          };
        };

        none-ls = {
          enable = true;
          sources = {
            code_actions.gitsigns.enable = true;
            diagnostics = {
              deadnix.enable = true;
              statix.enable = true;
            };
          };
        };

        luasnip.enable = true;
        friendly-snippets.enable = true;

        copilot-lua = lib.mkIf cfg.copilot {
          enable = true;
          settings = {
            panel.enabled = false;
            suggestion.enabled = false;
            filetypes = {
              markdown = true;
              yaml = true;
            };
          };
        };
        copilot-cmp.enable = cfg.copilot;

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            snippet.expand = ''
              function(args)
                require('luasnip').lsp_expand(args.body)
              end
            '';
            completion.completeopt = "menu,menuone,noinsert";
            window = {
              completion.border = "rounded";
              documentation.border = "rounded";
            };
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.abort()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            };
            sources =
              lib.optional cfg.copilot {name = "copilot";}
              ++ [
                {name = "nvim_lsp";}
                {name = "luasnip";}
                {name = "path";}
                {name = "buffer";}
              ];
          };
        };

        toggleterm = {
          enable = true;
          settings = {
            open_mapping = "[[<c-\\>]]";
            direction = "float";
            shade_terminals = true;
            float_opts = {
              border = "curved";
              width = ''
                function()
                  return math.floor(vim.o.columns * 0.85)
                end
              '';
              height = ''
                function()
                  return math.floor(vim.o.lines * 0.75)
                end
              '';
            };
          };
        };

        conform-nvim = {
          enable = true;
          autoInstall.enable = true;
          settings = {
            format_on_save = {
              timeout_ms = 1000;
              lsp_format = "fallback";
            };
            formatters_by_ft = {
              nix = ["alejandra"];
              lua = ["stylua"];
              sh = ["shfmt"];
              bash = ["shfmt"];
              javascript = ["prettier"];
              javascriptreact = ["prettier"];
              typescript = ["prettier"];
              typescriptreact = ["prettier"];
              json = ["prettier"];
              yaml = ["prettier"];
              markdown = ["prettier"];
            };
          };
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>w";
          action = "<cmd>write<cr>";
          options.desc = "Write buffer";
        }
        {
          mode = "n";
          key = "<leader>q";
          action = "<cmd>quit<cr>";
          options.desc = "Quit window";
        }
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>Neotree action=show source=filesystem position=left toggle=true<cr>";
          options.desc = "Toggle file explorer";
        }
        {
          mode = "n";
          key = "<S-h>";
          action = "<cmd>bprevious<cr>";
          options.desc = "Previous buffer";
        }
        {
          mode = "n";
          key = "<S-l>";
          action = "<cmd>bnext<cr>";
          options.desc = "Next buffer";
        }
        {
          mode = "n";
          key = "<leader>bn";
          action = "<cmd>bnext<cr>";
          options.desc = "Next buffer";
        }
        {
          mode = "n";
          key = "<leader>bp";
          action = "<cmd>bprevious<cr>";
          options.desc = "Previous buffer";
        }
        {
          mode = "n";
          key = "<leader>bd";
          action = "<cmd>bdelete<cr>";
          options.desc = "Close buffer";
        }
        {
          mode = "n";
          key = "<leader>bo";
          action = "<cmd>BufferLineCloseOthers<cr>";
          options.desc = "Close other buffers";
        }
        {
          mode = "n";
          key = "<leader>bb";
          action = "<cmd>BufferLinePick<cr>";
          options.desc = "Pick buffer";
        }
        {
          mode = "n";
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<cr>";
          options.desc = "Toggle diagnostics";
        }
        {
          mode = "n";
          key = "<leader>xf";
          action = "<cmd>lua require('conform').format({ async = true, lsp_format = 'fallback' })<cr>";
          options.desc = "Format buffer";
        }
      ];
    };
  };
}
