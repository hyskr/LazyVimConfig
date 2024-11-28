-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd("FileType", {
    pattern = "go", -- 只针对 Go 文件生效
    callback = function()
        vim.opt.tabstop = 4 -- 设置 Tab 长度为 4
        vim.opt.shiftwidth = 4 -- 设置缩进时每个层级为 4 个空格
        vim.opt.softtabstop = 4 -- 在插入模式下，Tab 和退格行为为 4 个空格
        vim.opt.expandtab = true -- 使用空格代替 Tab
    end
})