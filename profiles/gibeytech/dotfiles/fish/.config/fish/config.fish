# ============================================================
# FISH CONFIG — HyprFR Dracula Warm
# by jonathanbourriauddev
# ============================================================

# Désactive le message de bienvenue
set -g fish_greeting ""

# Fastfetch au démarrage
if status is-interactive
    fastfetch
end

# ============================================================
# VARIABLES D'ENVIRONNEMENT
# ============================================================
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx BROWSER brave
set -gx MANPAGER "nvim +Man!"

# PATH
fish_add_path ~/.local/bin
fish_add_path ~/dotfiles/scripts

# ============================================================
# PROMPT
# ============================================================
starship init fish | source

# ============================================================
# ALIASES — Navigation
# ============================================================
alias ls    'eza --icons --group-directories-first'
alias ll    'eza -la --icons --group-directories-first'
alias lt    'eza --tree --icons --level=2'
alias cat   'bat'
alias grep  'grep --color=auto'

# Editeur
alias v     'nvim'
alias vim   'nvim'
alias vi    'nvim'

# Git
alias gs    'git status'
alias ga    'git add'
alias gc    'git commit -m'
alias gp    'git push'
alias gl    'git log --oneline'
alias gd    'git diff'

# Dotfiles
alias dots  'cd ~/dotfiles'
alias hypr  'nvim ~/.config/hypr/hyprland.lua'
alias fish-config 'nvim ~/dotfiles/fish/.config/fish/config.fish'

# Système
alias update  'sudo pacman -Syu'
alias cleanup 'sudo pacman -Rns (pacman -Qtdq)'
alias reload  'hyprctl reload'
alias refish  'source ~/.config/fish/config.fish'
