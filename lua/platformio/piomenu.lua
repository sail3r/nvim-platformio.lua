local utils = require('platformio.utils')

local M = {}

local icon = { icon = '\238\154\130  ', color = 'orange' } -- Assign platformio orange icon (Nerd Font U+E682)

local function traverseMenu(menu, wkey, wk_table)
  for _, child_node in ipairs(menu) do
    if child_node.node == 'menu' then
      traverseMenu(child_node.items, wkey .. child_node.shortcut, wk_table)
      table.insert(wk_table, { wkey .. child_node.shortcut, group = child_node.desc, icon = icon })
    elseif child_node.node == 'item' then
      table.insert(wk_table, {
        wkey .. child_node.shortcut,
        '<cmd> ' .. child_node.command .. '<CR>',
        desc = child_node.desc,
        icon = icon,
      })
    end
  end
end

-- which-key's parser removes the child entries from the spec it is given, so
-- every wk.add() call needs a freshly built table.
local function build_spec(config)
  local wk_table = { mode = { 'n', 'v' } }
  table.insert(wk_table, { config.menu_key, group = config.menu_name, icon = icon })
  traverseMenu(config.menu_bindings, config.menu_key, wk_table)
  return wk_table
end

local function add_project_menu(wk, config, buf)
  -- The b: flag is cleared together with buffer-local mappings when Neovim
  -- reuses a buffer for another file, so it never claims a menu that is gone.
  if vim.b[buf].platformio_menu then
    return
  end
  -- Special buffers (help, terminal, file explorers) have no real file path.
  if vim.bo[buf].buftype ~= '' then
    return
  end
  if utils.find_platformioRootDir(buf) == nil then
    return
  end
  local spec = build_spec(config)
  spec.buffer = buf
  wk.add(spec)
  vim.b[buf].platformio_menu = true
end

function M.piomenu(config)
  if config.menu_key == nil then
    return
  end

  local ok, wk = pcall(require, 'which-key')
  if not ok then
    vim.api.nvim_echo({ { 'which-key plugin not found!', 'ErrorMsg' } }, true, {})
    return
  end

  if not wk.did_setup then
    wk.setup({
      preset = 'helix', --'modern', --'classic'
    })
  end
  local Config = require('which-key.config')
  Config.sort = { 'order', 'group', 'manual', 'mod' }

  if not config.project_only then
    wk.add(build_spec(config))
    return
  end

  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('platformio_menu', { clear = true }),
    desc = 'Add the PlatformIO menu to buffers inside a PlatformIO project',
    callback = function(args)
      add_project_menu(wk, config, args.buf)
    end,
  })
  -- setup() can run after BufEnter already fired for the current buffer, e.g.
  -- when lazy.nvim loads the plugin from BufReadPost or a :Pio* command.
  add_project_menu(wk, config, vim.api.nvim_get_current_buf())
end

return M
