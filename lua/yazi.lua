local window = require('yazi.window')
local utils = require('yazi.utils')

local M = {}

---@type integer?
YAZI_BUFFER = nil
YAZI_LOADED = false
vim.g.yazi_opened = 0
local prev_win = -1

---@type integer?
local win = -1
---@type integer?
local buffer = -1

local output_path = '/tmp/yazi_filechosen'

local function on_exit(job_id, code, event)
  if code ~= 0 then
    return
  end

  YAZI_BUFFER = nil
  YAZI_LOADED = false
  vim.g.yazi_opened = 0
  vim.cmd('silent! :checktime')

  -- NOTE the types for nvim_ apis are inaccurate so we need to typecast

  if vim.api.nvim_win_is_valid(prev_win) then
    ---@cast win integer
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_set_current_win(prev_win)
    if code == 0 and utils.file_exists(output_path) == true then
      local chosen_file = vim.fn.readfile(output_path)[1]
      if chosen_file then
        vim.cmd(string.format('edit %s', chosen_file))
      end
    end
    prev_win = -1
    if
      ---@cast buffer integer
      vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer)
    then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
    buffer = -1
    win = -1
  end
end

--- Call yazi
local function exec_yazi_command(cmd)
  if YAZI_LOADED == false then
    -- ensure that the buffer is closed on exit
    vim.g.yazi_opened = 1
    vim.fn.termopen(cmd, { on_exit = on_exit })
  end
  vim.cmd('startinsert')
end

--- :Yazi entry point
function M.yazi(path)
  if utils.is_yazi_available() ~= true then
    print('Please install yazi. Check documentation for more information')
    return
  end

  prev_win = vim.api.nvim_get_current_win()
  path = vim.fn.expand('%:p:h')

  win, buffer = window.open_floating_window()

  os.remove(output_path)
  local cmd = string.format('yazi "%s" --chooser-file "%s"', path, output_path)

  exec_yazi_command(cmd)
end

return M
