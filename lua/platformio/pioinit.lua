local M = {}

local utils = require('platformio.utils')
local terminal = require('platformio.terminal')
local picker = require('platformio.pickers')

local function init_project(board_details, selected_framework)
  local framework = selected_framework
  if framework == 'none' then
    framework = ''
  end
  -- Core only writes --sample-code for a resolved environment; with --board,
  -- --ide is what resolves it (project/commands/init.py).
  local command = 'pio project init --board '
    .. vim.fn.shellescape(board_details.id)
    .. ' --project-option '
    .. vim.fn.shellescape('framework=' .. framework)
    .. ' --ide vim --sample-code'
  terminal.ToggleTerminal(command, 'float', function()
    vim.cmd(':PioLSP')
  end)
end

local function pick_framework(board_details)
  local framework_list = vim.list_extend({ 'none' }, board_details.frameworks or {})
  picker.pick_framework(framework_list, function(selected_framework)
    init_project(board_details, selected_framework)
  end)
end

local function pick_board(boards)
  picker.pick_board(boards, function(selected_board)
    pick_framework(selected_board)
  end)
end

function M.pioinit()
  if not utils.pio_install_check() then
    return
  end

  -- Read stdout
  local command = 'pio boards --json-output'
  local handel = io.popen(command .. utils.devNul)
  if not handel then
    return
  end
  local json_str = handel:read('*a')
  handel:close()

  if #json_str == 0 then
    -- read stderr
    handel = io.popen(command .. ' 2>&1')
    if not handel then
      return
    end
    local command_output = handel:read('*a')
    handel:close()
    vim.notify('Some error occured while executing `' .. command .. "`', command output: \n", vim.log.levels.WARN)
    print(command_output)
    return
  end

  local json_data = vim.json.decode(json_str)
  pick_board(json_data or {})
end

return M
