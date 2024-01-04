local theme = 'catppuccin-mocha'

-- LSP Server configurations
-- See: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- Schema: { serverName = { ...settings }}
local lspServers = {
  astro = {},
  rust_analyzer = {},
  tsserver = {},
  eslint = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      diagnostics = { globals = { 'vim', 'require' } },
    }
  }
}

-- Plugins to be run
-- After changing these, don't forget to run `:checkhealth lazy`
local plugins = {
  "williamboman/mason.nvim",           -- LSP Package Manager
  "williamboman/mason-lspconfig.nvim", -- bridges mason.nvim with lspconfig
  "neovim/nvim-lspconfig",             -- nvim native LSP
  "mfussenegger/nvim-lint",            -- linter, complementary to native lsp
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = 'all',
        auto_install = true,
        sync_install = false,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
        ignore_install = {},
      })
    end
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      'hrsh7th/cmp-nvim-lsp', -- Extract extra LSP capabilities
      'L3MON4D3/LuaSnip',     -- Snippets
      'saadparwaiz1/cmp_luasnip',
      'onsails/lspkind.nvim'
    }
  }, -- Completions
  {
    "folke/neodev.nvim",
    opts = {}
  }, -- Lua nvim stuff

  {  -- FileTree
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Deps lib
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",  -- UI Library????
      "3rd/image.nvim",        -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },

  -- Themes
  { 'projekt0n/github-nvim-theme', lazy = false, priority = 1000 },
  { "catppuccin/nvim",             lazy = false, name = "catppuccin", priority = 1000 },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "┊"
      },
      scope = {
        enabled = true,
      }
    }
  },
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {}
  },
  { 'github/copilot.vim' },
  { "wakatime/vim-wakatime" },
  {
    "j-hui/fidget.nvim",
    opts = {}
  },
  {
    "jiriks74/presence.nvim",
    event = "UIEnter",
    opts = {
      enable_line_number = false,
      blacklist          = {}
    }
  },
  { "dstein64/vim-startuptime" }
}


-- Neovide configurations
if vim.g.neovide then
  vim.o.guifont = 'Berkeley Mono:h15'
  vim.g.neovide_cursor_animation_length = 0.05
end

--
-- Don't modify the code below if unneeded
--

-- VIM Default options
-- See: https://neovim.io/doc/user/options.html

-- Enable mouse on all mode
vim.o.mouse = 'a'

-- Show line number on current line
vim.o.number = true
vim.o.relativenumber = true
-- Show insert / visual / select modes Bottom Right
vim.o.showmode = true
-- If file modified, auto-re-read
vim.o.autoread = true
-- Set nvim to use global clipboard by default
-- If this doesn't work on linux, you might need to install `xclip`
-- See: https://neovim.io/doc/user/provider.html#provider-clipboard
vim.o.clipboard = 'unnamedplus'
-- Wrap words (VSCode Alt + Z)
vim.o.breakindent = true
-- Set size of tabs to 2 chars
vim.o.tabstop = 2
-- Set `SHIFT + >` indents to 2 chars
vim.o.shiftwidth = 2
-- Use appropriate number of spaces to insert `<Tab>`s
vim.o.expandtab = true

-- When searching / completions, ignore case unless uppercase is inserted
vim.o.ignorecase = true
vim.o.smartcase = true

-- Max. items shown in popup menu
vim.o.pumheight = 25
-- Min. lines of cursor before scrolling
vim.o.scrolloff = 10

-- ms till scratchdisk is written
vim.o.updatetime = 500

-- Restart config
vim.keymap.set('n', '<Leader>sv', '<Cmd>source $MYVIMRC<CR>')

--
-- Install plugins and stuff
--

-- Installs lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Optional lazy.nvim options
-- https://github.com/folke/lazy.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
local lazyOpts = {}

-- Load lazy.nvim
require("lazy").setup(plugins, lazyOpts)

-- Set theme - Only available after lazy is setup
vim.cmd('colorscheme ' .. theme)

-- Setup Mason - package manager for languages
require("mason").setup()
local masonLspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")
local linter = require("lint")

-- Bridges mason with native LSP

-- Include capabilities for completions
local lspCapabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

local onLspAttach = function(_, bufnr)
  -- Utility function
  local nmap = function(key, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end
    vim.keymap.set('n', key, func, { buffer = bufnr, desc = desc })
  end

  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_) vim.lsp.buf.format() end,
    { desc = 'Format using LSP' })

  nmap('K', vim.lsp.buf.hover, 'Hover documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature help')

  nmap('<Leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<Leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
  nmap('<Leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')

  nmap('gd', vim.lsp.buf.definition, '[G]o to [D]efinition')
  nmap('gI', vim.lsp.buf.implementation, '[G]o to [I]mplementation')
end

masonLspconfig.setup()
masonLspconfig.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup {
      capabilities = lspCapabilities,
      on_attach = onLspAttach,
      settings = lspServers[server_name]
    }
  end
})

-- Setup completions
local luasnip = require('luasnip')
local cmp = require('cmp')
cmp.setup({
  snippet = {
    -- Snippet engine
    expand = function(args)
      luasnip.lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete({}),
    ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
    -- Apparently <C-n> and below are Up/Down/Left/Right arrows /shrug
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<S-Tab>'] = cmp.mapping(
      function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }
    )
  }),
  window = {
    completion = {
      winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
      col_offset = -3,
      side_padding = 0,
    },
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-get-types-on-the-left-and-offset-the-menu
    fields = { "kind", "abbr", "menu" },
    format = function(entry, vim_item)
      local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
      local strings = vim.split(kind.kind, "%s", { trimempty = true })
      kind.kind = " " .. (strings[1] or "") .. " "
      kind.menu = "    (" .. (strings[2] or "") .. ")"

      return kind
    end,
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' }, -- For luasnip users.
  }, {
    { name = 'buffer' },
  })
})


-- Setup filetree
vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticSignHint" })

require("neo-tree").setup({
  close_if_last_window = false,
  window = {
    position = "right",
  },
  default_component_configs = {
    git_status = {
      symbols = {
        -- Change type
        added     = "", -- or "✚", but this is redundant info if you use git_status_colors on the name
        modified  = "", -- or "", but this is redundant info if you use git_status_colors on the name
        deleted   = "✖", -- this can only be used in the git_status source
        renamed   = "󰁕", -- this can only be used in the git_status source
        -- Status type
        untracked = "",
        ignored   = "",
        unstaged  = "󰄱",
        staged    = "",
        conflict  = "",
      }
    }
  }
})

-- Mappings
vim.keymap.set('n', '<Leader>e', vim.diagnostic.open_float, { desc = 'Show errors' })
vim.keymap.set('n', '<Leader>q', vim.diagnostic.setloclist, { desc = 'Show diagnostics' })

-- Auto lint on save
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    linter.try_lint()
  end,
})
