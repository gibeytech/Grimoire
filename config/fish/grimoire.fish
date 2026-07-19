# ============================================================
# Grimoire V3 — Fish Shell
# ============================================================

# Environnement Grimoire
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx BROWSER brave
set -gx MANPAGER "nvim +Man!"

# PATH local sans variable universelle ni duplication
if not contains -- "$HOME/.local/bin" $PATH
    set -gx PATH "$HOME/.local/bin" $PATH
end

# Les fonctions, le prompt et les alias ne concernent
# que les sessions interactives.
if status is-interactive
    # Remplace proprement le greeting fourni par CachyOS.
    functions -e fish_greeting 2>/dev/null

    function fish_greeting
        if type -q fastfetch
            fastfetch
        end
    end

    # Starship remplace le prompt fournisseur lorsqu’il est présent.
    if type -q starship
        starship init fish | source
    end

    if type -q eza
        alias ls 'eza --icons --group-directories-first'
        alias ll 'eza -la --icons --group-directories-first'
        alias lt 'eza --tree --icons --level=2'
    end

    if type -q bat
        alias cat 'bat'
    end

    alias grep 'grep --color=auto'
end
