local Detect = {}

local function command_exists(command)
    local result = os.execute("command -v " .. command .. " >/dev/null 2>&1")
    return result == true or result == 0
end

local function read_first_line(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local line = file:read("*l")
    file:close()

    return line
end

local function path_exists(path)
    local ok = os.execute("[ -e " .. path .. " ] >/dev/null 2>&1")
    return ok == true or ok == 0
end

function Detect.run()
    return {
        distribution = read_first_line("/etc/os-release"),

        session = os.getenv("XDG_SESSION_TYPE"),
        desktop = os.getenv("XDG_CURRENT_DESKTOP"),

        commands = {
            hyprland = command_exists("Hyprland"),
            waybar = command_exists("waybar"),
            rofi = command_exists("rofi"),
            swaync = command_exists("swaync"),
            kitty = command_exists("kitty"),
            ghostty = command_exists("ghostty"),
            fish = command_exists("fish"),
            zsh = command_exists("zsh"),
            brave = command_exists("brave"),
            firefox = command_exists("firefox"),
            code = command_exists("code"),
            nvim = command_exists("nvim"),
        },

        configs = {
            hypr = path_exists(os.getenv("HOME") .. "/.config/hypr"),
            waybar = path_exists(os.getenv("HOME") .. "/.config/waybar"),
            rofi = path_exists(os.getenv("HOME") .. "/.config/rofi"),
            fish = path_exists(os.getenv("HOME") .. "/.config/fish"),
            kitty = path_exists(os.getenv("HOME") .. "/.config/kitty"),
            swaync = path_exists(os.getenv("HOME") .. "/.config/swaync"),
        },
    }
end

return Detect
