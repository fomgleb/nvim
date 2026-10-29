-- vim.pack.add { 'https://github.com/linrongbin16/colorbox.nvim' }
-- require('colorbox').setup {
--   policy = { seconds = 1, implement = 'shuffle' },
--   timing = 'interval',
--   background = 'light',
-- }

local notify = vim.notify
vim.notify = function(...)
  local args = { ... }
  vim.schedule(function() notify(unpack(args)) end)
end

vim.pack.add {
  'https://github.com/rktjmp/lush.nvim',
  'https://github.com/linrongbin16/colorbox.nvim',
}

vim.o.termguicolors = true

-- Colorbox only makes the themes available; we pick them ourselves below
require('colorbox').setup {
  timing = 'startup',
  policy = 'shuffle',
}

local themes = {
  light = {
    'catppuccin', 'edge', 'everforest', 'gruvbox', 'gruvbox-material',
    'iceberg', 'kanagawa', 'melange', 'one', 'oxocarbon', 'PaperColor',
    'rose-pine', 'seoul256', 'solarized8', 'tokyonight', 'vscode', 'zenbones',
  },
  dark = {
    'apprentice', 'ayu', 'catppuccin', 'codedark', 'cyberdream', 'deus',
    'dracula', 'edge', 'everforest', 'falcon', 'github_dark', 'gotham',
    'gruvbox', 'gruvbox-material', 'iceberg', 'jellybeans', 'kanagawa',
    'material', 'melange', 'moonfly', 'nightfly', 'nightfox', 'nord',
    'nordic', 'OceanicNext', 'one', 'onedark', 'oxocarbon', 'PaperColor',
    'rose-pine', 'seoul256', 'solarized-osaka', 'solarized8', 'sonokai',
    'tender', 'tokyonight', 'vague', 'vscode', 'zenbones',
  },
}

math.randomseed(vim.uv.hrtime())

local function shuffle()
  local pool = themes[vim.o.background] or themes.dark
  for _ = 1, 10 do -- retry in case a theme is missing or errors
    local choice = pool[math.random(#pool)]
    if #pool == 1 or choice ~= vim.g.colors_name then
      if pcall(vim.cmd.colorscheme, choice) then
        vim.notify(('%s (%s)'):format(choice, vim.o.background))
        return
      end
    end
  end
end

vim.api.nvim_create_user_command('Shuffle', shuffle, { desc = 'Random theme for current background' })

vim.api.nvim_create_user_command('Bg', function(opts)
  local mode = opts.args
  if mode == '' or mode == 'toggle' then
    mode = vim.o.background == 'light' and 'dark' or 'light'
  end
  vim.o.background = mode
  shuffle() -- new background, new theme from the matching list
end, {
  nargs = '?',
  complete = function() return { 'light', 'dark', 'toggle' } end,
  desc = 'Set or toggle background and pick a matching theme',
})

vim.keymap.set('n', '<leader>tB', '<cmd>Bg toggle<CR>', { desc = '[T]oggle [B]ackground' })
vim.keymap.set('n', '<leader>ts', '<cmd>Shuffle<CR>', { desc = '[T]heme [S]huffle' })

-- Pick a theme matching your preferred background at startup
vim.o.background = 'light'
vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = shuffle })
