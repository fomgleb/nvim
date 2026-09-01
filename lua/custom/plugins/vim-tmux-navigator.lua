vim.pack.add({ "https://github.com/christoomey/vim-tmux-navigator.git" })

local map = vim.keymap.set
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Go to left split or tmux pane" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Go to bottom split or tmux pane" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Go to top split or tmux pane" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Go to right split or tmux pane" })
map("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Go to previous window or tmux pane" })
