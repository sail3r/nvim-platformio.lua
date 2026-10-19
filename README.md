<h1 align="center">
    <img alt="PlatformIO logo" src="https://github.com/user-attachments/assets/fa3f7663-802e-4845-b4f7-0992e34899f2" style="height: 1em; vertical-align: bottom;">
    nvim-platformio.lua
</h1>

<p align="center">PlatformIO wrapper for Neovim written in Lua.</p>

<https://github.com/user-attachments/assets/fdbb6655-4b2d-4a2b-81d1-fd8af6e7d9f1>

## Introduction

[PlatformIO](https://platformio.org) is a cross-platform build system and
package manager for embedded development: hundreds of boards, dozens of
platforms and frameworks such as Arduino, ESP-IDF and Zephyr, all behind one
command-line tool. nvim-platformio.lua brings that workflow into Neovim.
Create a project, build and flash firmware, watch the serial port, install
libraries and set up C/C++ language-server support, without leaving the
editor or memorising `pio` flags. Anything else PlatformIO Core can do is one
`:Piocmdf` away.

- **Project setup in seconds.** `:Pioinit` lets you search every board
  PlatformIO knows, pick a framework, and initialises the project in the
  current directory, with PlatformIO's sample code.
- **Build, upload and monitor.** Commands run in reusable floating or split
  terminals, from the project root: the nearest directory above the current
  file that contains `platformio.ini`.
- **Libraries from the registry.** `:Piolib` searches the PlatformIO registry,
  installs your pick and refreshes the language-server configuration.
- **Language-server configuration.** `:PioLSP` generates `.ccls` for ccls, or
  `compile_commands.json` for clangd, and restarts running LSP clients. The
  server itself is enabled in your own LSP setup.
- **Your picker.** Telescope, snacks.picker, mini.pick, or Neovim's built-in
  `vim.ui.select`.
- **A key-driven menu.** The default which-key menu puts 29 PlatformIO
  actions under one prefix. It is fully customisable and can be limited to
  buffers inside a PlatformIO project.

## System requirements

- [PlatformIO Core](https://docs.platformio.org/en/latest/core/installation/index.html)
  6.1.7 or newer (`:Pioinit` uses `pio project init --sample-code`). Core
  6.2 needs Python 3.9 or newer. The `pio` executable must be on your
  `PATH`; see
  [Install Shell Commands](https://docs.platformio.org/en/latest/core/installation/shell-commands.html).
- A command lookup tool, used to check that `pio` is installed: `which` on
  Linux and macOS, `where.exe` on Windows. macOS and Windows include it. On
  Arch Linux `which` comes with `base-devel`, not `base`; install it with
  `pacman -S which`. Without it the plugin reports "Platformio not found in
  the path" even when PlatformIO is installed.
- `curl`, used by `:Piolib` through plenary.nvim. macOS includes it, and so
  does Windows 10 from version 1803.
- Linux only: uploading and monitoring need PlatformIO's
  [udev rules](https://docs.platformio.org/en/latest/core/installation/udev-rules.html)
  (on Arch Linux, the `platformio-core-udev` package) and access to the
  serial port. Add your user to the group that owns it: usually `uucp` on
  Arch Linux, `dialout` or `plugdev` on Debian, Ubuntu and Fedora.

Upgrading PlatformIO: the menu item "Upgrade PlatformIO Core" runs
`pio upgrade`, which upgrades through pip. That suits the installer script
and pip installs. If PlatformIO came from a system package manager, upgrade
it with that instead: Arch Linux marks its system Python `EXTERNALLY-MANAGED`,
so pip will not upgrade the `platformio-core` package (use `pacman -Syu`), and
for Homebrew installs Core itself recommends `brew update && brew upgrade`.

## Neovim requirements

- Neovim 0.12 or newer. Older releases are not supported; `:PioLSP`, for
  example, uses `:lsp restart` and `vim.json.encode()` options added in 0.12.

Plugin dependencies:

| Plugin                                                           | Required          | Used for                                                     |
| ---------------------------------------------------------------- | ----------------- | ------------------------------------------------------------ |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)    | Yes               | Terminals that run build, upload, monitor and `pio` commands |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)         | For `:Piolib`     | HTTP requests to the PlatformIO registry                     |
| [which-key.nvim](https://github.com/folke/which-key.nvim)        | For `menu_key`    | The PlatformIO key menu                                      |
| A picker                                                         | No                | Board, framework, library and terminal selection             |

No picker plugin is required. Without one, the plugin uses Neovim's built-in
`vim.ui.select`, so a plugin that replaces `vim.ui.select` (snacks.nvim does
by default) is used too.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim). Every option is shown
with its default value, except `menu_key`, which is unset by default:

```lua
return {
    'anurag3301/nvim-platformio.lua',

 dependencies = {
  "akinsho/toggleterm.nvim", -- required
  "nvim-lua/plenary.nvim", -- :Piolib
  "folke/which-key.nvim", -- menu_key

  -- Pickers are optional. Uncomment your preference below, if desired.
  -- Without any installed, vim.ui.select is used.

  -- Telescope Picker
  -- 'nvim-telescope/telescope.nvim',

  -- snacks.picker
  -- Its default 'ui_select = true' also replaces vim.ui.select
  -- { 'folke/snacks.nvim', opts = { picker = { enabled = true } } },

  -- mini.pick
  -- opts = {} makes lazy.nvim call its setup()
  -- { 'nvim-mini/mini.pick', opts = {} },
 },

 opts = {
  -- Language server :PioLSP configures: 'ccls' | 'clangd'.
  lsp = "ccls",

  -- With lsp = 'clangd', set how compile_commands.json is produced:
  -- 'ccls' (converted from .ccls) | 'compiledb' (pio run -t compiledb).
  clangd_source = "ccls",

  -- 'auto' | 'telescope' | 'snacks' | 'mini_pick' | 'ui_select'.
  picker_backend = "auto",

  -- true: add the menu only to buffers inside a PlatformIO project.
  project_only = false,

  -- Echo terminal, window and job ids when a PIO terminal opens.
  debug = false,

  -- Label of the menu group.
  menu_name = "PlatformIO",

  -- Prefix of the which-key menu; leave unset to disable the menu.
  menu_key = "<leader>\\",

  -- Menu Keybindings: see Keybindings section below and paste the
  -- contents of opts = {} here
 },
}
```

`picker_backend = 'auto'` uses the first picker that is installed, in the
order telescope, snacks, mini.pick, `vim.ui.select`. If more than one is
installed, for example because telescope is part of your config anyway, set
`picker_backend` explicitly. An explicitly chosen picker that is not installed
reports an error instead of falling back.

With another plugin manager, install the same dependencies and call
`require('platformio').setup({ ... })` with the same table.

Details for every option: `:help platformio-configuration`.

### Try this plugin without touching your neovim config

A standalone config that installs everything into a temporary directory.
This is also the quickest way to tell a plugin problem from a config problem:

```sh
wget https://raw.githubusercontent.com/anurag3301/nvim-platformio.lua/main/minimal_config.lua
nvim -u minimal_config.lua
```

Then inside neovim run: `:Pioinit`

## Usage

| Command                         | Description                                                                 |
| ------------------------------- | --------------------------------------------------------------------------- |
| `:Pioinit`                      | Pick a board and framework, initialise a project in the current directory   |
| `:Piorun [target]`              | Target `build`, `upload`, `uploadfs` or `clean`; default: build and upload  |
| `:Piocmdf [args]`               | Run `pio <args>` in a floating terminal; without args, just open it         |
| `:Piocmdh [args]`               | Same as `:Piocmdf`, in a horizontal split                                   |
| `:Piomon [baud] [port]`         | Serial monitor; completes baud rates and detected ports                     |
| `:Piolsserial`                  | List serial ports                                                           |
| `:Piolib <query>`               | Search the PlatformIO registry and install the chosen library               |
| `:PioLSP`                       | Generate the ccls or clangd configuration for the project                   |
| `:Piodebug`                     | Start the PlatformIO debugger with gdb                                      |
| `:PioTermList`                  | Pick one of the open PIO terminals and switch to it                         |

Full reference: `:help PlatformIO`. To check the installation, run
`:checkhealth platformio`.

## Keybindings

### Menu

Setting `menu_key` registers a which-key menu under that prefix, in normal and
visual mode. With `project_only = true` it is added only to buffers whose file
is in a directory, or below a directory, that contains `platformio.ini`
(`:help platformio-project_only`).

The tree is defined by `menu_bindings`. A `menu` node opens a sub-menu and
holds `items`; an `item` node runs `command` as an Ex command. `shortcut` is
the key inside its menu. Setting `menu_bindings` replaces the whole default
tree, so copy it and edit it inside your Lazyvim config:

```lua
opts = {
  menu_bindings = {
    { node = 'item', desc = '[L]ist terminals', shortcut = 'l', command = 'PioTermList' },
    { node = 'item', desc = '[T]erminal Core CLI', shortcut = 't', command = 'Piocmdf' },
    {
      node = 'menu',
      desc = '[G]eneral',
      shortcut = 'g',
      items = {
        { node = 'item', desc = '[B]uild', shortcut = 'b', command = 'Piocmdf run' },
        { node = 'item', desc = '[U]pload', shortcut = 'u', command = 'Piocmdf run -t upload' },
        { node = 'item', desc = '[M]onitor', shortcut = 'm', command = 'Piocmdh run -t monitor' },
        { node = 'item', desc = '[C]lean', shortcut = 'c', command = 'Piocmdf run -t clean' },
        { node = 'item', desc = '[F]ull clean', shortcut = 'f', command = 'Piocmdf run -t fullclean' },
        { node = 'item', desc = '[D]evice list', shortcut = 'd', command = 'Piocmdf device list' },
      },
    },
    {
      node = 'menu',
      desc = '[P]latform',
      shortcut = 'p',
      items = {
        { node = 'item', desc = '[B]uild file system', shortcut = 'b', command = 'Piocmdf run -t buildfs' },
        { node = 'item', desc = 'Program [S]ize', shortcut = 's', command = 'Piocmdf run -t size' },
        { node = 'item', desc = '[U]pload file system', shortcut = 'u', command = 'Piocmdf run -t uploadfs' },
        { node = 'item', desc = '[E]rase Flash', shortcut = 'e', command = 'Piocmdf run -t erase' },
      },
    },
    {
      node = 'menu',
      desc = '[D]ependencies',
      shortcut = 'd',
      items = {
        { node = 'item', desc = '[L]ist packages', shortcut = 'l', command = 'Piocmdf pkg list' },
        { node = 'item', desc = '[O]utdated packages', shortcut = 'o', command = 'Piocmdf pkg outdated' },
        { node = 'item', desc = '[U]pdate packages', shortcut = 'u', command = 'Piocmdf pkg update' },
      },
    },
    {
      node = 'menu',
      desc = '[A]dvanced',
      shortcut = 'a',
      items = {
        { node = 'item', desc = '[T]est', shortcut = 't', command = 'Piocmdf test' },
        { node = 'item', desc = '[C]heck', shortcut = 'c', command = 'Piocmdf check' },
        { node = 'item', desc = '[D]ebug', shortcut = 'd', command = 'Piocmdf debug' },
        { node = 'item', desc = 'Compilation Data[b]ase', shortcut = 'b', command = 'Piocmdf run -t compiledb' },
        {
          node = 'menu',
          desc = '[V]erbose',
          shortcut = 'v',
          items = {
            { node = 'item', desc = 'Verbose [B]uild', shortcut = 'b', command = 'Piocmdf run -v' },
            { node = 'item', desc = 'Verbose [U]pload', shortcut = 'u', command = 'Piocmdf run -v -t upload' },
            { node = 'item', desc = 'Verbose [T]est', shortcut = 't', command = 'Piocmdf test -v' },
            { node = 'item', desc = 'Verbose [C]heck', shortcut = 'c', command = 'Piocmdf check -v' },
            { node = 'item', desc = 'Verbose [D]ebug', shortcut = 'd', command = 'Piocmdf debug -v' },
          },
        },
      },
    },
    {
      node = 'menu',
      desc = '[R]emote',
      shortcut = 'r',
      items = {
        { node = 'item', desc = 'Remote [U]pload', shortcut = 'u', command = 'Piocmdf remote run -t upload' },
        { node = 'item', desc = 'Remote [T]est', shortcut = 't', command = 'Piocmdf remote test' },
        { node = 'item', desc = 'Remote [M]onitor', shortcut = 'm', command = 'Piocmdh remote run -t monitor' },
        { node = 'item', desc = 'Remote [D]evices', shortcut = 'd', command = 'Piocmdf remote device list' },
      },
    },
    {
      node = 'menu',
      desc = '[M]iscellaneous',
      shortcut = 'm',
      items = {
        { node = 'item', desc = '[U]pgrade PlatformIO Core', shortcut = 'u', command = 'Piocmdf upgrade' },
      },
    },
  },
},
```

### Inside PIO terminals

These are buffer-local to the terminals the plugin opens:

| Mode     | Key     | Action                          |
| -------- | ------- | ------------------------------- |
| Terminal | `<Esc>` | Leave terminal mode             |
| Normal   | `<Esc>` | Return to terminal mode         |
| Normal   | `q`     | Close the terminal window       |

## Lazy loading

Loading the plugin checks for `pio` (`which pio`, or `where.exe pio` on
Windows) and starts `pio device list` in the background, to complete ports
for `:Piomon`. To defer that until the plugin is needed, add triggers to the
spec from [Installation](#installation).

### with `project_only = false` (default)

Load on the first PlatformIO command, or on the first press of the menu key:

```lua
cmd = {
  'Pioinit', 'PioLSP', 'Piorun', 'Piocmdh', 'Piocmdf',
  'Piolib', 'Piomon', 'Piolsserial', 'Piodebug', 'PioTermList',
},

-- `keys` must match `menu_key` inside `opts`, or opts.menu_key. 
-- lazy.nvim maps this key globally until the plugin loads, then replays the keypress.
keys = { { '<leader>\\', desc = 'PlatformIO' } },
```

### with `project_only = true`

Load `event` instead of `keys`. A `keys` trigger
is a global mapping, so the menu key would exist in every buffer until the
plugin loads:

```lua
cmd = {
  'Pioinit', 'PioLSP', 'Piorun', 'Piocmdh', 'Piocmdf',
  'Piolib', 'Piomon', 'Piolsserial', 'Piodebug', 'PioTermList',
},
event = { 'BufReadPost', 'BufNewFile' },
```

Neovim started without a file loads the plugin when the first file is opened
or the first PlatformIO command runs.

## Roadmap

- Connect `:Piodebug` with DAP.

## License

[MIT](LICENSE)
