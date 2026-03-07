-- =============================================================================
-- init.lua — Full IDE Neovim Config (Rust, Go, C++, Python, Writing)
-- Bootstrap: place at ~/.config/nvim/init.lua
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BOOTSTRAP lazy.nvim
-- -----------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- -----------------------------------------------------------------------------
-- CORE OPTIONS
-- -----------------------------------------------------------------------------
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
opt.signcolumn     = "yes"
opt.scrolloff      = 8
opt.sidescrolloff  = 8

opt.tabstop        = 4
opt.shiftwidth     = 4
opt.expandtab      = true
opt.smartindent    = true

opt.wrap           = false
opt.linebreak      = true       -- soft-wrap for prose (toggled per filetype)

opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = false
opt.incsearch      = true

opt.splitright     = true
opt.splitbelow     = true

opt.termguicolors  = true
opt.pumheight      = 10
opt.updatetime     = 200
opt.timeoutlen     = 300

opt.undofile       = true       -- persistent undo
opt.swapfile       = false
opt.backup         = false

opt.completeopt    = { "menu", "menuone", "noselect" }
opt.fileencoding   = "utf-8"
opt.clipboard      = "unnamedplus"

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})

-- Prose mode for markdown/text files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    opt.wrap      = true
    opt.spell     = true
    opt.spelllang = "en_us"
  end,
})

-- -----------------------------------------------------------------------------
-- PLUGINS via lazy.nvim
-- -----------------------------------------------------------------------------
require("lazy").setup({

  -- ── Colorscheme ─────────────────────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
    config   = function()
      require("catppuccin").setup({ flavour = "mocha", integrations = {
        nvimtree = true, telescope = true, cmp = true, gitsigns = true,
      }})
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- ── Icons ────────────────────────────────────────────────────────────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- ── Status Line ─────────────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = { theme = "catppuccin", globalstatus = true },
        sections = {
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "diagnostics", "encoding", "filetype" },
        },
      })
    end,
  },

  -- ── File Tree ───────────────────────────────────────────────────────────────
  {
    "nvim-tree/nvim-tree.lua",
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File Tree" } },
    config = function()
      require("nvim-tree").setup({
        view          = { width = 35 },
        renderer      = { group_empty = true },
        filters       = { dotfiles = false },
        git           = { enable = true },
        actions       = { open_file = { quit_on_open = true } },
      })
    end,
  },

  -- ── Fuzzy Finder ────────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    branch       = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Help" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>fr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
    },
    config = function()
      local ts = require("telescope")
      ts.setup({ defaults = { path_display = { "smart" }, layout_strategy = "horizontal" } })
      ts.load_extension("fzf")
    end,
  },

  -- ── Treesitter ───────────────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc",
          "rust", "go", "cpp", "c", "python",
          "markdown", "markdown_inline", "json", "yaml", "toml", "bash",
        },
        highlight    = { enable = true },
        indent       = { enable = true },
        textobjects  = {
          select = {
            enable    = true,
            lookahead = true,
            keymaps   = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          move = {
            enable              = true,
            goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          },
        },
      })
    end,
  },

  -- ── LSP ──────────────────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      { "j-hui/fidget.nvim", opts = {} },   -- LSP progress UI
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Mason: auto-install LSP servers
      require("mason").setup({ ui = { border = "rounded" } })
      require("mason-lspconfig").setup({
        ensure_installed = {
          "rust_analyzer", "gopls", "clangd", "pyright", "lua_ls",
        },
        automatic_installation = true,
      })

      local lspconfig = require("lspconfig")
      local caps      = require("cmp_nvim_lsp").default_capabilities()

      -- Shared on_attach: keymaps available once LSP attaches
      local on_attach = function(_, buf)
        local map = function(k, f, d)
          vim.keymap.set("n", k, f, { buffer = buf, desc = d })
        end
        map("gd",         vim.lsp.buf.definition,       "Go to Definition")
        map("gD",         vim.lsp.buf.declaration,      "Go to Declaration")
        map("gi",         vim.lsp.buf.implementation,   "Go to Implementation")
        map("gt",         vim.lsp.buf.type_definition,  "Type Definition")
        map("K",          vim.lsp.buf.hover,            "Hover Docs")
        map("<leader>rn", vim.lsp.buf.rename,           "Rename Symbol")
        map("<leader>ca", vim.lsp.buf.code_action,      "Code Action")
        map("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")
        map("[d",         vim.diagnostic.goto_prev,     "Prev Diagnostic")
        map("]d",         vim.diagnostic.goto_next,     "Next Diagnostic")
        map("<leader>dl", vim.diagnostic.open_float,    "Line Diagnostics")
      end

      -- Per-server setup
      local servers = {
        rust_analyzer = {
          settings = { ["rust-analyzer"] = {
            checkOnSave  = { command = "clippy" },
            inlayHints   = { enable = true },
          }},
        },
        gopls = {
          settings = { gopls = {
            analyses    = { unusedparams = true },
            staticcheck = true,
            gofumpt     = true,
          }},
        },
        clangd = {
          cmd = { "clangd", "--background-index", "--clang-tidy",
                  "--header-insertion=iwyu", "--completion-style=detailed" },
        },
        pyright = {
          settings = { python = { analysis = {
            typeCheckingMode = "basic",
            autoImportCompletions = true,
          }}},
        },
        lua_ls = {
          settings = { Lua = {
            runtime     = { version = "LuaJIT" },
            workspace   = { checkThirdParty = false },
            diagnostics = { globals = { "vim" } },
            telemetry   = { enable = false },
          }},
        },
      }

      for server, cfg in pairs(servers) do
        cfg.on_attach    = on_attach
        cfg.capabilities = caps
        lspconfig[server].setup(cfg)
      end

      -- Diagnostic signs
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end
      vim.diagnostic.config({
        virtual_text  = { prefix = "●" },
        update_in_insert = false,
        severity_sort = true,
        float         = { border = "rounded" },
      })
    end,
  },

  -- ── Autocompletion ───────────────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        window  = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"]   = cmp.mapping.select_prev_item(),
          ["<C-j>"]   = cmp.mapping.select_next_item(),
          ["<C-b>"]   = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]   = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]   = cmp.mapping.abort(),
          ["<CR>"]    = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip",  priority = 750 },
          { name = "buffer",   priority = 500 },
          { name = "path",     priority = 250 },
        }),
        formatting = {
          format = function(entry, item)
            local icons = {
              Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
              Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
              Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
              Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
              File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
              Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
              TypeParameter = "",
            }
            item.kind = string.format("%s %s", icons[item.kind] or "", item.kind)
            item.menu = ({ nvim_lsp = "[LSP]", luasnip = "[Snip]",
                           buffer = "[Buf]", path = "[Path]" })[entry.source.name]
            return item
          end,
        },
      })
    end,
  },

  -- ── Formatting ───────────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys  = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format" },
    },
    opts = {
      formatters_by_ft = {
        rust   = { "rustfmt" },
        go     = { "gofmt", "goimports" },
        cpp    = { "clang_format" },
        c      = { "clang_format" },
        python = { "black", "isort" },
        lua    = { "stylua" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  -- ── Git ──────────────────────────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts  = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buf)
        local gs  = require("gitsigns")
        local map = function(k, f, d)
          vim.keymap.set("n", k, f, { buffer = buf, desc = d })
        end
        map("]h", gs.next_hunk,              "Next Hunk")
        map("[h", gs.prev_hunk,              "Prev Hunk")
        map("<leader>hs", gs.stage_hunk,     "Stage Hunk")
        map("<leader>hr", gs.reset_hunk,     "Reset Hunk")
        map("<leader>hb", gs.blame_line,     "Blame Line")
        map("<leader>hd", gs.diffthis,       "Diff This")
        map("<leader>hp", gs.preview_hunk,   "Preview Hunk")
      end,
    },
  },

  -- ── Buffers / Tabs ───────────────────────────────────────────────────────────
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys  = {
      { "<S-h>",      "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>",      "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "<leader>bd", "<cmd>bdelete<cr>",             desc = "Delete Buffer" },
    },
    opts = {
      options = {
        diagnostics           = "nvim_lsp",
        offsets               = {{ filetype = "NvimTree", text = "Files", padding = 1 }},
        show_buffer_close_icons = true,
      },
    },
  },

  -- ── Terminal ─────────────────────────────────────────────────────────────────
  {
    "akinsho/toggleterm.nvim",
    keys = { { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal" } },
    opts = { direction = "horizontal", size = 15, shade_terminals = true },
  },

  -- ── Pairs & Surround ─────────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local ap  = require("nvim-autopairs")
      local cmp = require("cmp")
      ap.setup({ check_ts = true })
      cmp.event:on("confirm_done",
        require("nvim-autopairs.completion.cmp").on_confirm_done())
    end,
  },
  {
    "kylechui/nvim-surround",
    event   = "VeryLazy",
    version = "*",
    opts    = {},
  },

  -- ── Comments ─────────────────────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    opts  = {},
  },

  -- ── Which-key (keymap helper) ─────────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
      require("which-key").register({
        ["<leader>f"] = { name = "Find" },
        ["<leader>c"] = { name = "Code" },
        ["<leader>h"] = { name = "Git Hunks" },
        ["<leader>b"] = { name = "Buffer" },
        ["<leader>d"] = { name = "Diagnostics" },
      })
    end,
  },

  -- ── Indent guides ─────────────────────────────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    event   = { "BufReadPost", "BufNewFile" },
    main    = "ibl",
    opts    = { indent = { char = "│" }, scope = { enabled = true } },
  },

  -- ── Rust extras ──────────────────────────────────────────────────────────────
  {
    "mrcjkb/rustaceanvim",
    ft      = "rust",
    version = "^4",
  },

  -- ── Go extras ────────────────────────────────────────────────────────────────
  {
    "ray-x/go.nvim",
    dependencies = { "ray-x/guihua.lua", "neovim/nvim-lspconfig", "nvim-treesitter/nvim-treesitter" },
    ft           = { "go", "gomod" },
    build        = ":GoInstallBinaries",
    opts         = { lsp_inlay_hints = { enable = true } },
  },

  -- ── Markdown preview ─────────────────────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft           = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts         = {},
  },

  -- ── Trouble (diagnostics panel) ──────────────────────────────────────────────
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle<cr>",                        desc = "Toggle Trouble" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",  desc = "Workspace Diagnostics" },
      { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",   desc = "Document Diagnostics" },
    },
    opts = { use_diagnostic_signs = true },
  },

}, {
  -- lazy.nvim UI options
  ui = { border = "rounded" },
  checker = { enabled = true, notify = false },
})

-- -----------------------------------------------------------------------------
-- EXTRA KEYMAPS
-- -----------------------------------------------------------------------------
local map = vim.keymap.set

-- Better window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Resize windows
map("n", "<C-Up>",    "<cmd>resize +2<cr>")
map("n", "<C-Down>",  "<cmd>resize -2<cr>")
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>")
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>")

-- Stay in visual mode after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered when jumping
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")

-- Paste without losing register
map("x", "<leader>p", '"_dP', { desc = "Paste without losing register" })

-- Save & quit shortcuts
map("n", "<leader>w", "<cmd>w<cr>",  { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>",  { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>")