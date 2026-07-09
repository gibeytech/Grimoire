local PackageManager = {}

local function print_packages(value, prefix)
    prefix = prefix or ""

    if type(value) ~= "table" then
        return
    end

    for key, item in pairs(value) do
        if type(item) == "string" then
            print(prefix .. "- " .. item)
        elseif type(item) == "table" then
            print("")
            print(prefix .. tostring(key) .. " :")
            print_packages(item, prefix .. "  ")
        end
    end
end

function PackageManager.install(plan)
    local packages = plan:getPackages()

    print("[PackageManager] Dry-run : packages détectés")

    if type(packages) ~= "table" then
        print("[PackageManager] Aucun package valide.")
        return
    end

    print_packages(packages)
end

return PackageManager
