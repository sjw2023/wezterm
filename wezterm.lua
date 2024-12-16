-- Pull in the wezterm API
local wezterm = require ("wezterm")
local move = require("plugins.move")
local keys = require("keys")
local act = wezterm.action

-- Setting up workspace
wezterm.on('update-right-status', function(window, pane)
	window:set_right_status(window:active_workspace())
end)

-- Setting up mux
local mux = wezterm.mux
wezterm.on('gui-startup', function(cmd)
	-- allow 'wezterm sstart -- something' to affect what we spawn
	-- in our initial window
	local args = {}
	if cmd then
		args = cmd.args
	end
	-- Set a workspace for coding on a current project
	-- Top pane is for the editor, bottom is for the build tool
	local project_dir = wezterm.home_dir .. '\\wezterm'
	local tab, build_pane, window = mux.spawn_window{
		workspace = 'coding',
		cwd = project_dir,
		args = args,
	}
	local editor_pane = build_pane:split{
		direction = 'Top',
		size = 0.6,
		cwd = project_dir,
	}
	-- may as well kick off a build in that pane
	build_pane:send_text 'cargo build\n'

	-- A workspace for interacting with a local machine that 
	-- runs some docker conrainers for home automation
	local tab, pane, window = mux.spawn_window{
		workspace = 'automation',
		args = {'ssh', 'vault'},

	}

	-- We want to startup in the coding workspace
	mux.set_active_workspace 'coding'
--	local tab, pane, window = mux.spawn_window(cmd or {})
--	window:gui_window():maximize()
end)

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your configuration
-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Frappé (Gogh)'
config.font = wezterm.font 'JetBrains Mono'
-- config.window_background_opacity = 0.1
config.text_background_opacity = 0.3
config.default_prog = {'powershell.exe'}

-- setting up workspace
config.keys = {
	-- Switch to the default workspace
	{
		key = 'y',
		mods = 'CTRL|SHIFT',
		action = act.SwitchToWorkspace{
			name = 'default',
		},
	},
	-- Switch to a monitoring workspace, which will have 'top' launched into it
	{
		key = 'u',
		mods = 'CTRL|SHIFT',
		action = act.SwitchToWorkspace{
			name = 'mornitoring',
			spawn = {
			args = {'top'},
		},

		},
	},
	-- Create a new workspace with a random name and switch to it
	{ key='i', mods = 'CTRL|SHIFT', action = act.SwitchToWorkspace},
	-- Show the launcher in fuzzy selection mode and have it list all workspaces
	-- and allow activating one
	{
		key = '9',
		mods = 'ALT',
		action = act.ShowLauncherArgs{
			flags = 'FUZZY|WORKSPACES',
		},
	},
}

-- keys.setup(config)


-- and finally, return the configuration to Wezterm
return config
