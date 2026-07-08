local Profile = require("core.model.profile")

local ProfileLoader = {}

local REQUIRED_CONFIGS = {
  "packages",
  "services",
  "shell",
  "theme",
  "assets",
}

local function load_lua_table(path)
  local chunk, err = loadfile(path)

  if not chunk then
    error("Fichier introuvable ou invalide : " .. path .. "\n" .. tostring(err))
  end

  local ok, result = pcall(chunk)

  if not ok then
    error("Erreur Lua dans : " .. path .. "\n" .. tostring(result))
  end

  if type(result) ~= "table" then
    error("Le fichier doit retourner une table : " .. path)
  end

  return result
end

function ProfileLoader.load(profile_id)
  if not profile_id or profile_id == "" then
    error("Profil manquant. Exemple : gibeytech")
  end

  local profile_root = "profiles/" .. profile_id
  local manifest_path = profile_root .. "/manifest.lua"

  local manifest = load_lua_table(manifest_path)

  local profile_data = {
    id = manifest.id or profile_id,
    name = manifest.name or profile_id,
    description = manifest.description or "",
    version = manifest.version or "0.1.0",
    root = profile_root,
    manifest = manifest,
    config = {},
  }

  for _, config_name in ipairs(REQUIRED_CONFIGS) do
    local config_path = profile_root .. "/config/" .. config_name .. ".lua"
    profile_data.config[config_name] = load_lua_table(config_path)
  end

  return Profile:new(profile_data)
end

return ProfileLoader
