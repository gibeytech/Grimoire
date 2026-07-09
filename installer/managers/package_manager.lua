local PackageManager = {}

local function collect_packages(value, result)
    if type(value) ~= "table" then
        return
    end

    for _, item in pairs(value) do
        if type(item) == "string" then
            table.insert(result, item)
        elseif type(item) == "table" then
            collect_packages(item, result)
        end
    end
end

local function unique(values)
    local seen = {}
    local result = {}

    for _, value in ipairs(values) do
        if not seen[value] then
            seen[value] = true
            table.insert(result, value)
        end
    end

    table.sort(result)

    return result
end

function PackageManager.get_packages(plan)
    local packages = {}
    collect_packages(plan:getPackages(), packages)

    return unique(packages)
end

function PackageManager.build_command(plan)
    local packages = PackageManager.get_packages(plan)

    if #packages == 0 then
        return nil
    end

    return "sudo pacman -S --needed " .. table.concat(packages, " ")
end

function PackageManager.install(plan)
    local packages = PackageManager.get_packages(plan)

    print("[PackageManager] Dry-run : commande d'installation")

    if #packages == 0 then
        print("[PackageManager] Aucun package à installer.")
        return
    end

    print("")
    print(PackageManager.build_command(plan))
end

return PackageManager
