-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
vim.keymap.set('n', '<Leader>y', ':%y+<CR>', { noremap = true, silent = true })
-- Add any additional keymaps here
vim.keymap.set('n', '<leader>r', ':RunCode<CR>', {
    noremap = true,
    silent = false
})
vim.keymap.set('n', '<leader>rf', ':RunFile<CR>', {
    noremap = true,
    silent = false
})
vim.keymap.set('n', '<leader>rft', ':RunFile tab<CR>', {
    noremap = true,
    silent = false
})
vim.keymap.set('n', '<leader>rp', ':RunProject<CR>', {
    noremap = true,
    silent = false
})
vim.keymap.set('n', '<leader>rc', ':RunClose<CR>', {
    noremap = true,
    silent = false
})
vim.keymap.set('n', '<leader>crf', ':CRFiletype<CR>', {
    noremap = true,
    silent = false
})
vim.keymap.set('n', '<leader>crp', ':CRProjects<CR>', {
    noremap = true,
    silent = false
})

local hop = require('hop')
local directions = require('hop.hint').HintDirection
local wk = require("which-key")

wk.add({{
    "<leader>h",
    group = "hop"
}, -- group
{
    mode = {"n", "v"}, -- NORMAL and VISUAL mode
    {
        "<leader>hf",
        function()
            hop.hint_char1({
                direction = directions.AFTER_CURSOR,
                current_line_only = true
            })
        end,
        desc = "下一个字符"
    },
    {
        "<leader>hF",
        function()
            hop.hint_char1({
                direction = directions.BEFORE_CURSOR,
                current_line_only = true
            })
        end,
        desc = "前一个字符"
    },
    {
        "<leader>hw",
        ":HopWord<CR>",
        desc = "跳转到单词"
    },
    {
        "<leader>hl",
        ":HopLine<CR>",
        desc = "跳转到行"
    },
    {
        "<leader>hp",
        ":HopPattern<CR>",
        desc = "跳转到匹配"
    }
}})