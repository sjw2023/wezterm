-- Pull in the wezterm API
local wezterm = require("wezterm")
local move = require("plugins.move")
local keys = require("keys")
local act = wezterm.action

-- Setting up workspace
wezterm.on("update-right-status", function(window, pane)
	window:set_right_status(window:active_workspace())
end)

-- Setting up opening scrollingback in vim
local io = require("io")
local os = require("os")

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

-- Setting up mux
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	-- allow 'wezterm sstart -- something' to affect what we spawn
	-- in our initial window
	local args = {}
	if cmd then
		args = cmd.args
	end
	-- Set a workspace for coding on a current project
	-- Top pane is for the editor, bottom is for the build tool
	local project_dir = wezterm.home_dir .. "\\wezterm"
	local tab, build_pane, window = mux.spawn_window({
		workspace = "coding",
		cwd = project_dir,
		args = args,
	})
	local editor_pane = build_pane:split({
		direction = "Top",
		size = 0.6,
		cwd = project_dir,
	})
	-- may as well kick off a build in that pane
	build_pane:send_text("cargo build\n")

	-- A workspace for interacting with a local machine that
	-- runs some docker conrainers for home automation
	local tab, pane, window = mux.spawn_window({
		workspace = "automation",
		args = { "ssh", "vault" },
	})

	-- We want to startup in the coding workspace
	mux.set_active_workspace("coding")
	--	local tab, pane, window = mux.spawn_window(cmd or {})
	--	window:gui_window():maximize()
end)

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your configuration
--- config.window_background_opacity = 0.1
-- config.text_background_opacity = 0.3
config.window_background_opacity = 0.85
config.enable_scroll_bar = true
config.default_prog = { "powershell.exe" }
config.scrollback_lines = 3500

-- setting up workspace

config.font = wezterm.font("JetBrains Mono")

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
	{
		key = "u",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace({
			name = "mornitoring",
			spawn = {
				args = { "top" },
			},
		}),
	},
	-- Create a new workspace with a random name and switch to it
	{
		key = "i",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace,
	},

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
		key = "h",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "U",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "I",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "O",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	{
		key = "9",
		mods = "CTRL",
		action = act.PaneSelect,
	},
	{
		key = "L",
		mods = "CTRL",
		action = act.ShowDebugOverlay,
	},
	{
		key = "j",
		mods = "CTRL",
		action = act.ScrollByPage(-1),
	},
	{
		key = "k",
		mods = "CTRL",
		action = act.ScrollByPage(1),
	},
}

-- keys.setup(config)

-- and finally, return the configuration to Wezterm
return config
