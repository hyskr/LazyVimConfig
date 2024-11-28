-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local wk = require("which-key")

vim.g["quarto_is_r_mode"] = nil
vim.g["reticulate_running"] = false

local nmap = function(key, effect)
  vim.keymap.set("n", key, effect, { silent = true, noremap = true })
end

local vmap = function(key, effect)
  vim.keymap.set("v", key, effect, { silent = true, noremap = true })
end

local imap = function(key, effect)
  vim.keymap.set("i", key, effect, { silent = true, noremap = true })
end

local cmap = function(key, effect)
  vim.keymap.set("c", key, effect, { silent = true, noremap = true })
end

wk.add({
  { "<c-LeftMouse>", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "go to definition" },
  { "gN", "Nzzzv", desc = "center search" },
  { "gf", ":e <cfile><CR>", desc = "edit file" },
  { "n", "nzzzv", desc = "center search" },
}, { mode = "n", silent = true })

vim.keymap.set("n", "<Leader>y", ":%y+<CR>", {
  noremap = true,
  silent = true,
})
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>r", ":RunCode<CR>", {
  noremap = true,
  silent = false,
})
vim.keymap.set("n", "<leader>rf", ":RunFile<CR>", {
  noremap = true,
  silent = false,
})
vim.keymap.set("n", "<leader>rft", ":RunFile tab<CR>", {
  noremap = true,
  silent = false,
})
vim.keymap.set("n", "<leader>rp", ":RunProject<CR>", {
  noremap = true,
  silent = false,
})
vim.keymap.set("n", "<leader>rc", ":RunClose<CR>", {
  noremap = true,
  silent = false,
})
vim.keymap.set("n", "<leader>crf", ":CRFiletype<CR>", {
  noremap = true,
  silent = false,
})
vim.keymap.set("n", "<leader>crp", ":CRProjects<CR>", {
  noremap = true,
  silent = false,
})

local hop = require("hop")
local directions = require("hop.hint").HintDirection

wk.add({
  {
    "<leader>h",
    group = "hop",
  }, -- group
  {
    mode = { "n", "v" }, -- NORMAL and VISUAL mode
    {
      "<leader>hf",
      function()
        hop.hint_char1({
          direction = directions.AFTER_CURSOR,
          current_line_only = true,
        })
      end,
      desc = "下一个字符",
    },
    {
      "<leader>hF",
      function()
        hop.hint_char1({
          direction = directions.BEFORE_CURSOR,
          current_line_only = true,
        })
      end,
      desc = "前一个字符",
    },
    {
      "<leader>hw",
      ":HopWord<CR>",
      desc = "跳转到单词",
    },
    {
      "<leader>hl",
      ":HopLine<CR>",
      desc = "跳转到行",
    },
    {
      "<leader>hp",
      ":HopPattern<CR>",
      desc = "跳转到匹配",
    },
  },
})

-- required in which-key plugin spec in plugins/ui.lua as `require 'config.keymap'`
local ms = vim.lsp.protocol.Methods

--- Send code to terminal with vim-slime
--- If an R terminal has been opend, this is in r_mode
--- and will handle python code via reticulate when sent
--- from a python chunk.
--- TODO: incorpoarate this into quarto-nvim plugin
--- such that QuartoRun functions get the same capabilities
--- TODO: figure out bracketed paste for reticulate python repl.
local function send_cell()
  if vim.b["quarto_is_r_mode"] == nil then
    vim.fn["slime#send_cell"]()
    return
  end
  if vim.b["quarto_is_r_mode"] == true then
    vim.g.slime_python_ipython = 0
    local is_python = require("otter.tools.functions").is_otter_language_context("python")
    if is_python and not vim.b["reticulate_running"] then
      vim.fn["slime#send"]("reticulate::repl_python()" .. "\r")
      vim.b["reticulate_running"] = true
    end
    if not is_python and vim.b["reticulate_running"] then
      vim.fn["slime#send"]("exit" .. "\r")
      vim.b["reticulate_running"] = false
    end
    vim.fn["slime#send_cell"]()
  end
end

--- Send code to terminal with vim-slime
--- If an R terminal has been opend, this is in r_mode
--- and will handle python code via reticulate when sent
--- from a python chunk.
local slime_send_region_cmd = ":<C-u>call slime#send_op(visualmode(), 1)<CR>"
slime_send_region_cmd = vim.api.nvim_replace_termcodes(slime_send_region_cmd, true, false, true)
local function send_region()
  -- if filetyps is not quarto, just send_region
  if vim.bo.filetype ~= "quarto" or vim.b["quarto_is_r_mode"] == nil then
    vim.cmd("normal" .. slime_send_region_cmd)
    return
  end
  if vim.b["quarto_is_r_mode"] == true then
    vim.g.slime_python_ipython = 0
    local is_python = require("otter.tools.functions").is_otter_language_context("python")
    if is_python and not vim.b["reticulate_running"] then
      vim.fn["slime#send"]("reticulate::repl_python()" .. "\r")
      vim.b["reticulate_running"] = true
    end
    if not is_python and vim.b["reticulate_running"] then
      vim.fn["slime#send"]("exit" .. "\r")
      vim.b["reticulate_running"] = false
    end
    vim.cmd("normal" .. slime_send_region_cmd)
  end
end

--- Show R dataframe in the browser
-- might not use what you think should be your default web browser
-- because it is a plain html file, not a link
-- see https://askubuntu.com/a/864698 for places to look for
local function show_r_table()
  local node = vim.treesitter.get_node({ ignore_injections = false })
  assert(node, "no symbol found under cursor")
  local text = vim.treesitter.get_node_text(node, 0)
  local cmd = [[call slime#send("DT::datatable(]] .. text .. [[)" . "\r")]]
  vim.cmd(cmd)
end

local is_code_chunk = function()
  local current, _ = require("otter.keeper").get_current_language_context()
  if current then
    return true
  else
    return false
  end
end

--- Insert code chunk of given language
--- Splits current chunk if already within a chunk
--- @param lang string
local insert_code_chunk = function(lang)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", true)
  local keys
  if is_code_chunk() then
    keys = [[o```<cr><cr>```{]] .. lang .. [[}<esc>o]]
  else
    keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
  end
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

local insert_r_chunk = function()
  insert_code_chunk("r")
end

local insert_py_chunk = function()
  insert_code_chunk("python")
end

local insert_lua_chunk = function()
  insert_code_chunk("lua")
end

local insert_julia_chunk = function()
  insert_code_chunk("julia")
end

local insert_bash_chunk = function()
  insert_code_chunk("bash")
end

local insert_ojs_chunk = function()
  insert_code_chunk("ojs")
end


local function new_terminal(lang)
  vim.cmd("vsplit term://" .. lang)
end

local function new_terminal_python()
  new_terminal("python")
end

local function new_terminal_r()
  new_terminal("R --no-save")
end

local function new_terminal_ipython()
  new_terminal("ipython --no-confirm-exit")
end

local function new_terminal_shell()
  new_terminal("$SHELL")
end

local function get_otter_symbols_lang()
  local otterkeeper = require("otter.keeper")
  local main_nr = vim.api.nvim_get_current_buf()
  local langs = {}
  for i, l in ipairs(otterkeeper.rafts[main_nr].languages) do
    langs[i] = i .. ": " .. l
  end
  -- promt to choose one of langs
  local i = vim.fn.inputlist(langs)
  local lang = otterkeeper.rafts[main_nr].languages[i]
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    otter = {
      lang = lang,
    },
  }
  -- don't pass a handler, as we want otter to use it's own handlers
  vim.lsp.buf_request(main_nr, ms.textDocument_documentSymbol, params, nil)
end

vim.keymap.set("n", "<localleader>os", get_otter_symbols_lang, { desc = "otter [s]ymbols" })

local runner = require("quarto.runner")
local quarto = require("quarto")
quarto.setup()
vim.keymap.set("n", "<localleader>qp", quarto.quartoPreview, {
  silent = true,
  noremap = true,
})
vim.keymap.set("n", "<localleader>rc", runner.run_cell, {
  desc = "run cell",
  silent = true,
})
vim.keymap.set("n", "<localleader>ra", runner.run_above, {
  desc = "run cell and above",
  silent = true,
})
vim.keymap.set("n", "<localleader>rA", runner.run_all, {
  desc = "run all cells",
  silent = true,
})
vim.keymap.set("n", "<localleader>rl", runner.run_line, {
  desc = "run line",
  silent = true,
})
vim.keymap.set("v", "<localleader>r", runner.run_range, {
  desc = "run visual range",
  silent = true,
})
vim.keymap.set("n", "<localleader>rA", function()
  runner.run_all(true)
end, {
  desc = "run all cells of all languages",
  silent = true,
})

-- normal mode with <leader>
wk.add({
  {
    { "<localleader><cr>", send_cell, desc = "run code cell" },
    { "<locallead<er>c", group = "[c]ode / [c]ell / [c]hunk" },
    { "<localleader>ci", new_terminal_ipython, desc = "new [i]python terminal" },
    { "<localleader>cn", new_terminal_shell, desc = "[n]ew terminal with shell" },
    { "<localleader>cp", new_terminal_python, desc = "new [p]ython terminal" },
    { "<localleader>cr", new_terminal_r, desc = "new [R] terminal" },
    { "<localleader>o", group = "[o]tter & c[o]de" },
    { "<localleader>oa", require("otter").activate, desc = "otter [a]ctivate" },
    { "<localleader>ob", insert_bash_chunk, desc = "[b]ash code chunk" },
    { "<localleader>oc", "O# %%<cr>", desc = "magic [c]omment code chunk # %%" },
    { "<localleader>od", require("otter").activate, desc = "otter [d]eactivate" },
    { "<localleader>oj", insert_julia_chunk, desc = "[j]ulia code chunk" },
    { "<localleader>ol", insert_lua_chunk, desc = "[l]lua code chunk" },
    { "<localleader>oo", insert_ojs_chunk, desc = "[o]bservable js code chunk" },
    { "<localleader>op", insert_py_chunk, desc = "[p]ython code chunk" },
    { "<localleader>or", insert_r_chunk, desc = "[r] code chunk" },
    { "<localleader>q", group = "[q]uarto" },
    {
      "<localleader>qE",
      function()
        require("otter").export(true)
      end,
      desc = "[E]xport with overwrite",
    },
    { "<localleader>qa", ":QuartoActivate<cr>", desc = "[a]ctivate" },
    { "<localleader>qe", require("otter").export, desc = "[e]xport" },
    { "<localleader>qh", ":QuartoHelp ", desc = "[h]elp" },
    { "<localleader>qp", ":lua require'quarto'.quartoPreview()<cr>", desc = "[p]review" },
    { "<localleader>qq", ":lua require'quarto'.quartoClosePreview()<cr>", desc = "[q]uiet preview" },
    { "<localleader>qr", group = "[r]un" },
    { "<localleader>qra", ":QuartoSendAll<cr>", desc = "run [a]ll" },
    { "<localleader>qrb", ":QuartoSendBelow<cr>", desc = "run [b]elow" },
    { "<localleader>qrr", ":QuartoSendAbove<cr>", desc = "to cu[r]sor" },
    { "<localleader>r", group = "[r] R specific tools" },
    { "<localleader>rt", show_r_table, desc = "show [t]able" },
  },
}, { mode = "n" })
