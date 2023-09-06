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
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("lazy").setup("plugins")
require("keyopts.keymaps")
require("keyopts.opts")

require("lualine").setup({
  options = {
    icons_enabled = true,
    theme = require("me.lualine").theme(),
    component_separators = "|",
    section_separators = "",
  },
})
-- Enable Comment.nvim
require("Comment").setup()

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help indent_blankline.txt`
require("indent_blankline").setup({
  char = "┊",
  show_trailing_blankline_indent = false,
})

-- Gitsigns
-- See `:help gitsigns.txt`
require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
  defaults = {
    winblend = 10, -- set the transparency level to 10%
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
        ["<C-p>"] = require("telescope.actions.layout").toggle_preview,
      },
    },
    preview = {
      hide_on_startup = false, -- hide previewer when picker starts
    },
  },
  prompt_prefix = " ",
  selection_caret = " ",
  color_devicons = true,
  sorting_strategy = "ascending",
})
-- vim.o.signcolumn = require("dap").session() == nil and "auto" or "yes:1"

-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")

-- See `:help telescope.builtin`
-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- debugger remaps
-- function compile_and_continue()
--   vim.cmd("w")
--   vim.cmd("!gcc -march=x86-64 -o %< % -g")
--   require("dap").continue()
-- end

--emmet remaps
vim.g.user_emmet_mode = "n"
vim.g.user_emmet_leader_key = ","
vim.g.mapleader = " "
-- harpoon setup

vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
