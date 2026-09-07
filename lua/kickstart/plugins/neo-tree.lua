-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
    filtered_items = {
      visible = true,          -- Always show filtered items
      hide_dotfiles = false,   -- Show files starting with .
      hide_gitignored = false, -- Show files in .gitignore
      hide_by_name = {},       -- Clear any specific name exclusions
      never_show = {},         -- Clear items that are never shown
    },
  },
}
