# ============================================================
# Grimoire V2 — Fish Shell
# ============================================================

# Désactive le message de bienvenue
set -g fish_greeting ""

# Fastfetch au démarrage
if status is-interactive
    fastfetch
end

# ============================================================
# ENVIRONNEMENT
# ============================================================

set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx TERMINAL kitty
set -gx BROWSER brave

set -gx MANPAGER "nvim +Man!"

# ============================================================
# PATHS
# ============================================================

fish_add_path ~/.local/bin

# ============================================================
# STARSHIP
# ============================================================

starship init fish | source

# ============================================================
# ALIASES
# ============================================================

alias ls   'eza --icons --group-directories-first'
alias ll   'eza -la --icons --group-directories-first'
alias lt   'eza --tree --icons --level=2'

alias cat  'bat'
alias grep 'grep --color=auto'

