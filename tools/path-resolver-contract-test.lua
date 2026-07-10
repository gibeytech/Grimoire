package.path = "./?.lua;./?/init.lua;" .. package.path

local PathResolver = require("installer.path_resolver")

print("== PathResolver RC2-D1 Contract Test ==")

local test_home = "/home/grimoire-test"

----------------------------------------------------------------------
-- Tilde seul
----------------------------------------------------------------------

local tilde_result = PathResolver.resolve("~", {
    home = test_home,
})

assert(tilde_result.ok == true)
assert(tilde_result.input == "~")
assert(tilde_result.path == test_home)
assert(tilde_result.home == test_home)
assert(tilde_result.expanded == true)
assert(tilde_result.error == nil)

----------------------------------------------------------------------
-- Tilde avec suffixe
----------------------------------------------------------------------

local tilde_path_result = PathResolver.resolve(
    "~/.config/grimoire",
    {
        home = test_home,
    }
)

assert(tilde_path_result.ok == true)
assert(tilde_path_result.input == "~/.config/grimoire")
assert(
    tilde_path_result.path
        == "/home/grimoire-test/.config/grimoire"
)
assert(tilde_path_result.home == test_home)
assert(tilde_path_result.expanded == true)
assert(tilde_path_result.error == nil)

----------------------------------------------------------------------
-- $HOME seul
----------------------------------------------------------------------

local home_variable_result = PathResolver.resolve(
    "$HOME",
    {
        home = test_home,
    }
)

assert(home_variable_result.ok == true)
assert(home_variable_result.input == "$HOME")
assert(home_variable_result.path == test_home)
assert(home_variable_result.home == test_home)
assert(home_variable_result.expanded == true)
assert(home_variable_result.error == nil)

----------------------------------------------------------------------
-- $HOME avec suffixe
----------------------------------------------------------------------

local home_variable_path_result = PathResolver.resolve(
    "$HOME/.local/share",
    {
        home = test_home,
    }
)

assert(home_variable_path_result.ok == true)
assert(
    home_variable_path_result.path
        == "/home/grimoire-test/.local/share"
)
assert(home_variable_path_result.expanded == true)
assert(home_variable_path_result.error == nil)

----------------------------------------------------------------------
-- ${HOME} seul
----------------------------------------------------------------------

local braced_home_result = PathResolver.resolve(
    "${HOME}",
    {
        home = test_home,
    }
)

assert(braced_home_result.ok == true)
assert(braced_home_result.path == test_home)
assert(braced_home_result.expanded == true)
assert(braced_home_result.error == nil)

----------------------------------------------------------------------
-- ${HOME} avec suffixe
----------------------------------------------------------------------

local braced_home_path_result = PathResolver.resolve(
    "${HOME}/.cache/grimoire",
    {
        home = test_home,
    }
)

assert(braced_home_path_result.ok == true)
assert(
    braced_home_path_result.path
        == "/home/grimoire-test/.cache/grimoire"
)
assert(braced_home_path_result.expanded == true)
assert(braced_home_path_result.error == nil)

----------------------------------------------------------------------
-- HOME avec slash final
----------------------------------------------------------------------

local trailing_home_result = PathResolver.resolve(
    "~/.config",
    {
        home = "/home/grimoire-test///",
    }
)

assert(trailing_home_result.ok == true)
assert(
    trailing_home_result.path
        == "/home/grimoire-test/.config"
)
assert(trailing_home_result.home == test_home)
assert(trailing_home_result.expanded == true)
assert(trailing_home_result.error == nil)

----------------------------------------------------------------------
-- Chemin absolu inchangé
----------------------------------------------------------------------

local absolute_result = PathResolver.resolve(
    "/usr/share/grimoire",
    {
        home = test_home,
    }
)

assert(absolute_result.ok == true)
assert(absolute_result.input == "/usr/share/grimoire")
assert(absolute_result.path == "/usr/share/grimoire")
assert(absolute_result.home == test_home)
assert(absolute_result.expanded == false)
assert(absolute_result.error == nil)

----------------------------------------------------------------------
-- Chemin relatif inchangé
----------------------------------------------------------------------

local relative_result = PathResolver.resolve(
    "profiles/gibeytech/dotfiles",
    {
        home = test_home,
    }
)

assert(relative_result.ok == true)
assert(
    relative_result.path
        == "profiles/gibeytech/dotfiles"
)
assert(relative_result.home == test_home)
assert(relative_result.expanded == false)
assert(relative_result.error == nil)

----------------------------------------------------------------------
-- Tilde d'un autre utilisateur non interprété
----------------------------------------------------------------------

local other_user_result = PathResolver.resolve(
    "~other/.config",
    {
        home = test_home,
    }
)

assert(other_user_result.ok == true)
assert(other_user_result.path == "~other/.config")
assert(other_user_result.expanded == false)
assert(other_user_result.error == nil)

----------------------------------------------------------------------
-- Chemin vide
----------------------------------------------------------------------

local empty_result = PathResolver.resolve("", {
    home = test_home,
})

assert(empty_result.ok == false)
assert(empty_result.input == "")
assert(empty_result.path == nil)
assert(empty_result.home == nil)
assert(empty_result.expanded == false)
assert(empty_result.error == "Chemin invalide")

----------------------------------------------------------------------
-- Chemin nil
----------------------------------------------------------------------

local nil_result = PathResolver.resolve(nil, {
    home = test_home,
})

assert(nil_result.ok == false)
assert(nil_result.input == nil)
assert(nil_result.path == nil)
assert(nil_result.home == nil)
assert(nil_result.expanded == false)
assert(nil_result.error == "Chemin invalide")

----------------------------------------------------------------------
-- HOME indisponible
----------------------------------------------------------------------

local original_getenv = os.getenv

os.getenv = function(name)
    if name == "HOME" then
        return nil
    end

    return original_getenv(name)
end

local missing_home_result = PathResolver.resolve("~/.config")

os.getenv = original_getenv

assert(missing_home_result.ok == false)
assert(missing_home_result.input == "~/.config")
assert(missing_home_result.path == nil)
assert(missing_home_result.home == nil)
assert(missing_home_result.expanded == false)
assert(
    missing_home_result.error
        == "Répertoire HOME indisponible"
)

----------------------------------------------------------------------
-- HOME réel de l'environnement
----------------------------------------------------------------------

local environment_home = os.getenv("HOME")
local environment_result = PathResolver.resolve("~/.config")

assert(environment_result.ok == true)
assert(
    environment_result.path
        == environment_home .. "/.config"
)
assert(environment_result.home == environment_home)
assert(environment_result.expanded == true)
assert(environment_result.error == nil)

print("")
print("RC2-D1 OK : PathResolver développe les chemins utilisateur.")
