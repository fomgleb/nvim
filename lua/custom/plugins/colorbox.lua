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

---------------------------------------------------------------------------
-- Shared state (synced across all nvim instances through a JSON file)
---------------------------------------------------------------------------
local state_dir = vim.fn.stdpath 'state'
local state_file = state_dir .. '/theme.json'
local state = { colorscheme = nil, background = 'dark', allow_light = false } -- flip to true for old behaviour

local function read_state()
  local f = io.open(state_file, 'r')
  if not f then return nil end
  local s = f:read '*a'
  f:close()
  local ok, t = pcall(vim.json.decode, s)
  return (ok and type(t) == 'table') and t or nil
end

local function write_state()
  vim.fn.mkdir(state_dir, 'p')
  local tmp = state_file .. '.' .. vim.uv.os_getpid() .. '.tmp'
  local f = io.open(tmp, 'w')
  if not f then return end
  f:write(vim.json.encode(state))
  f:close()
  os.rename(tmp, state_file) -- atomic, so other instances never read a half-written file
end

-- Apply state to THIS instance only (never writes, so no feedback loops)
local function apply(s)
  state = vim.tbl_extend('force', state, s)
  local bg = state.allow_light and state.background or 'dark'
  if bg == vim.o.background and state.colorscheme == vim.g.colors_name then return end
  vim.o.background = bg
  if state.colorscheme then pcall(vim.cmd.colorscheme, state.colorscheme) end
end

---------------------------------------------------------------------------
-- Picking themes
---------------------------------------------------------------------------
local function shuffle()
  local bg = state.allow_light and vim.o.background or 'dark'
  vim.o.background = bg
  local pool = themes[bg]
  for _ = 1, 10 do -- retry in case a theme is missing or errors
    local choice = pool[math.random(#pool)]
    if #pool == 1 or choice ~= vim.g.colors_name then
      if pcall(vim.cmd.colorscheme, choice) then
        state.colorscheme, state.background = choice, bg
        write_state() -- other instances pick this up via the watcher
        vim.notify(('%s (%s)'):format(choice, bg))
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
  if mode == 'light' and not state.allow_light then
    vim.notify('Light themes are disabled (:Light on to enable)', vim.log.levels.WARN)
    return
  end
  vim.o.background = mode
  shuffle()
end, {
  nargs = '?',
  complete = function() return { 'light', 'dark', 'toggle' } end,
  desc = 'Set or toggle background and pick a matching theme',
})

-- :Light on | off | toggle  -- allow or forbid light themes (synced everywhere)
vim.api.nvim_create_user_command('Light', function(opts)
  local a = opts.args
  if a == 'on' then state.allow_light = true
  elseif a == 'off' then state.allow_light = false
  else state.allow_light = not state.allow_light end

  if not state.allow_light and vim.o.background == 'light' then
    shuffle() -- currently light: switch to a dark theme (this also saves state)
  else
    write_state()
  end
  vim.notify('Light themes: ' .. (state.allow_light and 'ON' or 'OFF'))
end, {
  nargs = '?',
  complete = function() return { 'on', 'off', 'toggle' } end,
  desc = 'Allow or forbid light themes',
})

vim.keymap.set('n', '<leader>tB', '<cmd>Bg toggle<CR>', { desc = '[T]oggle [B]ackground' })
vim.keymap.set('n', '<leader>ts', '<cmd>Shuffle<CR>', { desc = '[T]heme [S]huffle' })
vim.keymap.set('n', '<leader>tl', '<cmd>Light toggle<CR>', { desc = '[T]oggle [L]ight themes allowed' })

---------------------------------------------------------------------------
-- Startup + live sync
---------------------------------------------------------------------------
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function() -- run after colorbox's own startup pick
      local s = read_state()
      if s then apply(s) else shuffle() end -- first ever run: pick one and save it
    end)
  end,
})

vim.fn.mkdir(state_dir, 'p')
local watcher = vim.uv.new_fs_event()
local debounce = vim.uv.new_timer()
watcher:start(state_dir, {}, function(_, fname)
  if fname ~= 'theme.json' then return end
  debounce:stop()
  debounce:start(50, 0, vim.schedule_wrap(function()
    local s = read_state()
    if s then apply(s) end
  end))
end)
