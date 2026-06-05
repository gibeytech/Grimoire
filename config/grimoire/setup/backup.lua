local Backup = {}

local home = os.getenv("HOME")

local function command_ok(command)
    local result = os.execute(command .. " >/dev/null 2>&1")
    return result == true or result == 0
end

local function path_exists(path)
    return command_ok('[ -e "' .. path .. '" ]')
end

local function mkdir(path)
    os.execute('mkdir -p "' .. path .. '"')
end

local function today()
    local handle = io.popen("date +%Y-%m-%d")
    local result = handle:read("*l")
    handle:close()
    return result
end

local function expand_home(path)
    if not path then
        return nil
    end

    return path:gsub("^~", home)
end

local function basename(path)
    return path:match("([^/]+)$")
end

function Backup.plan(items)
    local destination = home .. "/.config/grimoire-backups/" .. today()
    local backups = {}

    for _, item in ipairs(items or {}) do
        local source = expand_home(item.path)

        if source and path_exists(source) then
            table.insert(backups, {
                component = item.component,
                source = source,
                destination = destination .. "/" .. basename(source),
                status = "pending",
            })
        end
    end

    return {
        destination = destination,
        items = backups,
    }
end

function Backup.run(plan)
    mkdir(plan.destination)

    for _, item in ipairs(plan.items or {}) do
        local command = 'cp -a "' .. item.source .. '" "' .. item.destination .. '"'
        local result = os.execute(command)

        if result == true or result == 0 then
            item.status = "saved"
        else
            item.status = "failed"
        end
    end

    return plan
end

function Backup.report(plan)
    print("")
    print("Sauvegardes")
    print("-----------")

    if not plan.items or #plan.items == 0 then
        print("Aucune sauvegarde nécessaire.")
        return
    end

    for _, item in ipairs(plan.items) do
        if item.status == "saved" then
            print("✓ " .. item.component .. " → " .. item.destination)
        elseif item.status == "failed" then
            print("✗ " .. item.component .. " → échec")
        else
            print("- " .. item.component .. " → en attente")
        end
    end
end

return Backup
