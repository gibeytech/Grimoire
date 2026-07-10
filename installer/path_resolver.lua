local PathResolver = {}

local function value_is_present(value)
    return value ~= nil and tostring(value) ~= ""
end

local function resolve_home(options)
    options = options or {}

    if value_is_present(options.home) then
        return tostring(options.home)
    end

    local environment_home = os.getenv("HOME")

    if value_is_present(environment_home) then
        return tostring(environment_home)
    end

    return nil
end

local function normalize_home(home)
    local normalized = tostring(home)

    while #normalized > 1 and normalized:sub(-1) == "/" do
        normalized = normalized:sub(1, -2)
    end

    return normalized
end

local function join_home(home, suffix)
    local normalized_home = normalize_home(home)

    if suffix == nil or suffix == "" then
        return normalized_home
    end

    if suffix:sub(1, 1) == "/" then
        return normalized_home .. suffix
    end

    return normalized_home .. "/" .. suffix
end

local function expand_tilde(path, home)
    if path == "~" then
        return normalize_home(home)
    end

    if path:sub(1, 2) == "~/" then
        return join_home(home, path:sub(2))
    end

    return nil
end

local function expand_home_variable(path, home)
    if path == "$HOME" or path == "${HOME}" then
        return normalize_home(home)
    end

    if path:sub(1, 6) == "$HOME/" then
        return join_home(home, path:sub(6))
    end

    if path:sub(1, 8) == "${HOME}/" then
        return join_home(home, path:sub(8))
    end

    return nil
end

function PathResolver.resolve(path, options)
    if not value_is_present(path) then
        return {
            ok = false,
            input = path,
            path = nil,
            home = nil,
            expanded = false,
            error = "Chemin invalide",
        }
    end

    local string_path = tostring(path)
    local home = resolve_home(options)

    local requires_home = string_path == "~"
        or string_path:sub(1, 2) == "~/"
        or string_path == "$HOME"
        or string_path:sub(1, 6) == "$HOME/"
        or string_path == "${HOME}"
        or string_path:sub(1, 8) == "${HOME}/"

    if requires_home and not home then
        return {
            ok = false,
            input = path,
            path = nil,
            home = nil,
            expanded = false,
            error = "Répertoire HOME indisponible",
        }
    end

    if home then
        local tilde_path = expand_tilde(string_path, home)

        if tilde_path then
            return {
                ok = true,
                input = path,
                path = tilde_path,
                home = normalize_home(home),
                expanded = true,
                error = nil,
            }
        end

        local variable_path = expand_home_variable(
            string_path,
            home
        )

        if variable_path then
            return {
                ok = true,
                input = path,
                path = variable_path,
                home = normalize_home(home),
                expanded = true,
                error = nil,
            }
        end
    end

    return {
        ok = true,
        input = path,
        path = string_path,
        home = home and normalize_home(home) or nil,
        expanded = false,
        error = nil,
    }
end

return PathResolver
