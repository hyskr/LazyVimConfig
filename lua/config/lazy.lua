local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({"git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath})
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({{"Failed to clone lazy.nvim:\n", "ErrorMsg"}, {out, "WarningMsg"},
                           {"\nPress any key to exit..."}}, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = { -- add LazyVim and import its plugins
    {
        "LazyVim/LazyVim",
        import = "lazyvim.plugins"
    }, -- import/override with your plugins
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = not vim.g.ai_cmp,
                auto_trigger = true,
                keymap = {
                    accept = false, -- handled by nvim-cmp / blink.cmp
                    next = "<M-]>",
                    prev = "<M-[>"
                }
            },
            panel = {
                enabled = false
            },
            filetypes = {
                markdown = true,
                help = true
            }
        }
    }, {
        "CRAG666/code_runner.nvim",
        config = true
    }, {
        'smoka7/hop.nvim',
        version = "*",
        opts = {
            keys = 'etovxqpdygfblzhckisuran'
        }
    }, {
        'akinsho/toggleterm.nvim',
        config = function()
            require('toggleterm').setup {
                size = 20,
                open_mapping = [[<c-\>]],
                direction = 'float',
                float_opts = {
                    border = 'curved'
                }
            }

            function _G.set_terminal_keymaps()
                local opts = {
                    buffer = 0
                }
                vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
            end

            -- if you only want these mappings for toggle term use term://*toggleterm#* instead
            vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'
        end,
        keys = [[<c-\>]],
        cmd = 'ToggleTerm'
    }, {
        import = "plugins"
    }},
    defaults = {
        -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
        -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
        lazy = false,
        -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
        -- have outdated releases, which may break your Neovim install.
        version = false -- always use the latest git commit
        -- version = "*", -- try installing the latest stable version for plugins that support semver
    },
    install = {
        colorscheme = {"tokyonight", "habamax"}
    },
    checker = {
        enabled = true, -- check for plugin updates periodically
        notify = false -- notify on update
    }, -- automatically check for plugin updates
    performance = {
        rtp = {
            -- disable some rtp plugins
            disabled_plugins = {"gzip", -- "matchit",
            -- "matchparen",
            -- "netrwPlugin",
            "tarPlugin", "tohtml", "tutor", "zipPlugin"}
        }
    }
})

require('code_runner').setup({
    focus = false,
    better_term = "clean",
    filetype = {
        java = {"cd $dir &&", "javac $fileName &&", "java $fileNameWithoutExt"},
        python = "python3 -u",
        typescript = "deno run",
        rust = {"cd $dir &&", "rustc $fileName &&", "$dir/$fileNameWithoutExt"},
        go = {"cd $dir &&", "go run $fileName"},
        c = function(...)
            c_base = {"cd $dir &&", "gcc $fileName -o", "/tmp/$fileNameWithoutExt"}
            local c_exec = {"&& /tmp/$fileNameWithoutExt &&", "rm /tmp/$fileNameWithoutExt"}
            vim.ui.input({
                prompt = "Add more args:"
            }, function(input)
                c_base[4] = input
                vim.print(vim.tbl_extend("force", c_base, c_exec))
                require("code_runner.commands").run_from_fn(vim.list_extend(c_base, c_exec))
            end)
        end
    }
})
