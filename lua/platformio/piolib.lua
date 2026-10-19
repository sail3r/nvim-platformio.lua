local M = {}

local curl = require('plenary.curl')
local utils = require('platformio.utils')
local terminal = require('platformio.terminal')
local picker = require('platformio.pickers')

function M.piolib(lib_arg_list)
  if not utils.pio_install_check() then
    return
  end

  -- The registry also returns platforms and tools; Core's own searches add
  -- the same type qualifier (registry/client.py list_packages).
  local lib_str = 'type:"library" ' .. table.concat(lib_arg_list, ' ')

  local url = 'https://api.registry.platformio.org/v3/search'
  local res = curl.get(url, {
    insecure = utils.is_windows, -- Windows curl builds often lack a CA bundle, breaking TLS verification
    timeout = 20000,
    headers = { content_type = 'application/json' },
    query = {
      query = lib_str,
      limit = 30,
      sort = 'popularity',
      -- page = 1,
      -- limit = 1,
    },
  })

  if res['status'] == 200 then
    local json_data = vim.json.decode(res['body'])
    picker.pick_library(json_data.items or {}, function(selected_library)
      local owner = (selected_library.owner and selected_library.owner.username) or ''
      local name = selected_library.name or ''
      if owner == '' or name == '' then
        vim.notify('Invalid library selection: missing owner or name.', vim.log.levels.ERROR)
        return
      end
      -- Registry names can contain spaces; quoting keeps them intact and
      -- stops shell injection. The terminal runs 'shell', as shellescape() assumes.
      local command = 'pio pkg install --library ' .. vim.fn.shellescape(owner .. '/' .. name)
      terminal.ToggleTerminal(command, 'float', function()
        vim.cmd(':PioLSP')
      end, utils.get_platformioRootDir())
    end)
  else
    vim.notify(
      'API Request to platformio return HTTP code: ' .. res['status'] .. '\nplease run `curl -LI ' .. url .. '` for complete information',
      vim.log.levels.ERROR
    )
  end
end

return M
