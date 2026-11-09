-- Hyprland for greetd's greeter user: shows crux's login screen, exits once a session starts.
-- greetd runs it as `Hyprland --config /usr/share/crux/greetd/crux-hyprland.lua` (see config.toml).

local crux = os.getenv("CRUX_DIR") or "/etc/xdg/quickshell/crux"

-- Every monitor at its preferred mode. Machine-specific lines (hl.monitor() rotations and layout, GPU
-- env vars) go in /etc/greetd/crux-local.lua, written the same way as your own Hyprland config.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
local local_config = os.getenv("CRUX_GREETER_LOCAL") or "/etc/greetd/crux-local.lua"
local f = io.open(local_config, "r")
if f then
    f:close()
    -- A mistake in the local file must not cost the login screen, so it can only lose its own lines.
    local ok, err = pcall(dofile, local_config)
    if not ok then
        print("crux-greeter: " .. local_config .. ": " .. tostring(err))
    end
end

-- The greeter user can't read /home, so crux-sync-greeter keeps its settings here.
hl.env("XDG_CONFIG_HOME", "/var/lib/crux-greeter")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.config({
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        enable_anr_dialog        = false,
    },
    animations = {
        enabled = false,
    },
    ecosystem = {
        no_donation_nag = true,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p " .. crux .. "/greeter.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)
