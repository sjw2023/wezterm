-- Pull in the wezterm API
local wezterm = require("wezterm")
local move = require("plugins.move")
local keys = require("keys")
local act = wezterm.action

local platform_info = {
	window = "x86_64-pc-windows-msvc",
	mac_intel = "x86_64-apple-darwin",
	mac_silicon = "aarch64-apple-darwin",
	linux = "x86_64-unknown-linux-gnu",
}
-- This will hold the configuration.
local config = wezterm.config_builder()

local platform = wezterm.target_triple
if platform == platform_info["window"] then
	-- config.default_prog = { "powershell.exe" }
	config.default_prog = { "nu" }
else
	config.default_prog = { "/opt/homebrew/bin/nu" }
end

-- Setting up workspace
wezterm.on("update-right-status", function(window, pane)
	window:set_right_status(window:active_workspace())
end)

-- Setting up opening scrollingback in vim
local io = require("io")
local os = require("os")

--gui-startup
wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local window_width = screen.width * 0.8
	local window_height = screen.height * 0.8
	local x = (screen.width - window_width) / 2
	local y = (scree.height - window_height) / 2
	wezterm.mux.spawn_window({
		position = { x = x, y = y, origin = "ActiveScreen" },
	})
end)

wezterm.on("trigger-vim-with-scrollback", function(window, pane)
	-- Retrieve the text from the pane
	local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
	-- Create a temporary file to pass to vim
	local name = os.tmpname()
	local f = io.open(name, "w+")
	f:write(text)
	f:flush()
	f:close()

	-- Open a new window running vim and tell it to open the file
	window:perform_action(
		act.spawnCommandInNewWindow({
			args = { "nvim", name },
		}),
		pane
	)

	-- Wait enough imte for nvim to read the file before we remove it.
	-- The window creation and process spawn are asynchronous wrt, running
	-- this script and are not wawaitable, so we just pick a number.
	--
	-- Note : We don't strictly need to remove this file, but it is nice
	-- to avoid cluttering up the temporary directory.
	wezterm.sleep_ms(1000)
	os.remove(name)
end)

--Default-settings
config.automatically_reload_config = true
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.font_size = 12.5
config.initial_cols = 200
config.initial_rows = 50

-- Setting up mux
--  local mux = wezterm.mux
--  wezterm.on("gui-startup", function(cmd)
--    -- allow 'wezterm sstart -- something' to affect what we spawn
--    -- in our initial window
--    local args = {}
--    if cmd then
--      args = cmd.args
--    end
--    -- Set a workspace for coding on a current project
--    -- Top pane is for the editor, bottom is for the build tool
--    local project_dir = wezterm.home_dir .. "\\wezterm"
--    local tab, build_pane, window = mux.spawn_window({
--      workspace = "coding",
--      cwd = project_dir,
--      args = args,
--    })
--    local editor_pane = build_pane:split({
--      direction = "Top",
--      size = 0.6,
--      cwd = project_dir,
--    })

-- Background seting
config.background = {}

config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.5,
}

-- Window setting
config.window_padding = {
	left = 3,
	right = 3,
	top = 0,
	bottom = 0,
}

-- A workspace for interacting with a local machine that
-- runs some docker conrainers for home automation
-- local tab, pane, window = mux.spawn_window({
--workspace = "automation",
-- args = { "ssh", "vault" },
-- })

-- We want to startup in the coding workspace
--     mux.set_active_workspace("coding")
--     --	local tab, pane, window = mux.spawn_window(cmd or {})
--     --	window:gui_window():maximize()
--   end)
--
-- This is where you actually apply your configuration
-- config.window_background_opacity = 0.1
-- config.text_background_opacity = 0.3
config.window_background_opacity = 0.6
config.enable_scroll_bar = true
config.scrollback_lines = 3500

-- setting up workspace
term = "xterm_256color"
config.font = wezterm.font("JetBrains Mono")
config.front_end = "OpenGL"
config.max_fps = 144
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.cell_width = 0.9

-- Setting Color
-- For example, changing the color scheme:
-- config.color_scheme = 'Catppuccin Frappé (Gogh)'
-- config.color_scheme = 'Catppuccin Latte'
-- config.color_scheme = "Catppuccin Macchiato"
config.colors = require("cyberdream")
config.colors = {
	background = "#0c0b0f",
	tab_bar = {
		background = "#0c0b0f",
		active_tab = {
			bg_color = "#0c0b0f",
			fg_color = "#bea3c7",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#0c0b0f",
			fg_color = "#f8f2f5",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		new_tab = {
			-- bg_color = "rgba(59, 34, 76, 50%)",
			bg_color = "#0c0b0f",
			fg_color = "white",
		},
	},
}

-- Setting up key mappings

config.keys = {
	-- Switch to the default workspace
	{
		key = "y",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace({
			name = "default",
		}),
	},

	-- Switch to a monitoring workspace, which will have 'top' launched into it
	--[[ {
		key = "u",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace({
			name = "mornitoring",
			spawn = {
				args = { "top" },
			},
		}),
	}, ]]

	-- Create a new workspace with a random name and switch to it
	--[[ {
		key = "i",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace,
	}, ]]

	-- Show the launcher in fuzzy selection mode and have it list all workspaces
	-- and allow activating one
	{
		key = "9",
		mods = "ALT",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
		}),
	},
	{
		key = "U",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Left", 1 }),
	},
	{
		key = "I",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Down", 1 }),
	},
	{
		key = "O",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Up", 1 }),
	},
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Right", 1 }),
	},

	-- Move pane
	{
		key = "h",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},

	-- Copy and Paste setting
	{
		key = "v",
		mods = "CTRL",
		action = act.PasteFrom("Clipboard"),
	},

	-- Splitting panes

	{
		key = "H",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitPane({
			direction = "Left",
			size = { Percent = 50 },
		}),
	},
	{
		key = "J",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	{
		key = "K",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitPane({
			direction = "Up",
			size = { Percent = 50 },
		}),
	},
	{
		key = "L",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},

	{
		key = "9",
		mods = "CTRL",
		action = act.PaneSelect,
	},

	{
		key = "j",
		mods = "CTRL|ALT|SHIFT",
		action = act.ScrollByPage(1),
	},

	{
		key = "k",
		mods = "CTRL|ALT|SHIFT",
		action = act.ScrollByPage(-1),
	},
}

-- keys.setup(config)

-- and finally, return the configuration to Wezterm
return config
