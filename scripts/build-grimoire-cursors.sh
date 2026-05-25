#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         Grimoire Cursor Theme Builder                       ║
# ║  Recolorie phinger-cursors-gruvbox-material → palette       ║
# ║  Grimoire (tons chauds sombres, rose-violet, orange)        ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Couleurs terminal ────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
M='\033[0;35m'; C='\033[0;36m'; W='\033[1;37m'; N='\033[0m'

log()  { echo -e "${C}[grimoire]${N} $*"; }
ok()   { echo -e "${G}[  ok  ]${N} $*"; }
warn() { echo -e "${Y}[ warn ]${N} $*"; }
err()  { echo -e "${R}[ err  ]${N} $*"; exit 1; }

# ── Chemins ──────────────────────────────────────────────────────
WORK_DIR="$HOME/.cache/grimoire-cursors-build"
THEME_NAME="phinger-cursors-grimoire"
INSTALL_DIR="$HOME/.local/share/icons/$THEME_NAME"
DOTFILES_DIR="$HOME/dotfiles"
CURSOR_SIZES=(24 32 48 64 96 128)

# ── Palette Gruvbox Material (source) ────────────────────────────
# Couleurs dominantes dans les PNGs du thème gruvbox-material
# Identifiées depuis la spec officielle saharaji/gruvbox-material
GRV_BG="#1d2021"         # fond très sombre
GRV_BG2="#282828"        # fond principal
GRV_FG="#d4be98"         # texte / corps curseur (beige chaud)
GRV_ORANGE="#e78a4e"     # orange accent
GRV_YELLOW="#d8a657"     # jaune
GRV_RED="#ea6962"        # rouge
GRV_AQUA="#89b482"       # aqua / hover
GRV_BLUE="#7daea3"       # bleu
GRV_WHITE="#ddc7a1"      # blanc cassé (outline lumineuse)

# ── Palette Grimoire (cible) ──────────────────────────────────────
GRM_BG="#221a1a"         # base — fond principal
GRM_BG2="#2d2020"        # surface
GRM_FG="#f8f8f2"         # texte — corps curseur
GRM_PRIMARY="#e07892"    # rose-violet chaud — accent principal
GRM_SECONDARY="#ffb86c"  # orange — accent secondaire
GRM_TERTIARY="#ff6e6e"   # rouge-rose
GRM_CYAN="#a4ffff"       # cyan — hover / info
GRM_PURPLE="#bd93f9"     # violet
GRM_WHITE="#f8f8f2"      # outline lumineuse

# ── Vérification dépendances ─────────────────────────────────────
check_deps() {
    log "Vérification des dépendances..."
    local missing=()
    for dep in convert mogrify wget xcursorgen xcur2png; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        err "Dépendances manquantes : ${missing[*]}\n  → sudo pacman -S imagemagick xorg-xcursorgen xcur2png wget"
    fi
    ok "Dépendances OK"
}

# ── Téléchargement source ─────────────────────────────────────────
download_source() {
    log "Téléchargement de phinger-cursors-gruvbox-material..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    if [[ -f "phinger-cursors-variants.tar.bz2" ]]; then
        warn "Archive déjà présente, skip download"
    else
        wget -q --show-progress \
            "https://github.com/rehanzo/phinger-cursors-gruvbox-material/releases/download/3328966123/phinger-cursors-variants.tar.bz2" \
            -O phinger-cursors-variants.tar.bz2 \
            || err "Téléchargement échoué"
    fi

    log "Extraction..."
    rm -rf themes/
    mkdir -p themes/
    tar xfj phinger-cursors-variants.tar.bz2 -C themes/
    ok "Source extraite dans $WORK_DIR/themes/"
    ls themes/
}

# ── Substitution de couleur sur un PNG ───────────────────────────
# Stratégie : remap HSL complet via -modulate puis
# substitution hex précise via sparse-color pour les teintes clés.
# On travaille en deux passes :
#   1. Shift teinte globale (chaud gruvbox → chaud grimoire)
#   2. Substitutions couleur par couleur sur les zones de forte saturation
recolor_png() {
    local src="$1"
    local dst="$2"
    local tmp="${dst}.tmp.png"

    # Copie de travail
    cp "$src" "$tmp"

    # ── Passe 1 : Shift teinte globale ──────────────────────────
    magick "$tmp" \
        -modulate 95,115,94 \
        "$tmp"

    # ── Passe 2 : Remplacement couleur précis ───────────────────
    # Fond sombre gruvbox → fond Grimoire
    magick "$tmp" \
        -fuzz 12% \
        -fill "$GRM_BG" -opaque "$GRV_BG" \
        -fill "$GRM_BG2" -opaque "$GRV_BG2" \
        "$tmp"

    # Corps principal / FG (beige gruvbox → texte Grimoire)
    magick "$tmp" \
        -fuzz 18% \
        -fill "$GRM_FG" -opaque "$GRV_FG" \
        -fill "$GRM_WHITE" -opaque "$GRV_WHITE" \
        "$tmp"

    # Orange gruvbox → orange Grimoire (secondaire)
    magick "$tmp" \
        -fuzz 20% \
        -fill "$GRM_SECONDARY" -opaque "$GRV_ORANGE" \
        -fill "$GRM_TERTIARY" -opaque "$GRV_RED" \
        "$tmp"

    # Aqua/bleu gruvbox → cyan/violet Grimoire
    magick "$tmp" \
        -fuzz 20% \
        -fill "$GRM_CYAN" -opaque "$GRV_AQUA" \
        -fill "$GRM_PURPLE" -opaque "$GRV_BLUE" \
        "$tmp"

    # Jaune gruvbox → primary Grimoire (rose-violet)
    magick "$tmp" \
        -fuzz 25% \
        -fill "$GRM_PRIMARY" -opaque "$GRV_YELLOW" \
        "$tmp"

    # Déplace le résultat final vers dst
    mv "$tmp" "$dst"
}

# ── Recoloration de tous les curseurs d'un variant ───────────────
recolor_variant() {
    local src_variant="$1"   # ex: themes/phinger-cursors-gruvbox-material
    local dst_variant="$2"   # ex: build/phinger-cursors-grimoire

    log "Recoloration de $(basename "$src_variant")..."
    mkdir -p "$dst_variant/cursors"

    # Copie des symlinks
    find "$src_variant/cursors" -maxdepth 1 -type l \
        -exec cp -P {} "$dst_variant/cursors/" \;

    # Détection : PNGs natifs ou binaires xcursor ?
    local png_count
    png_count=$(find "$src_variant" -name "*.png" 2>/dev/null | wc -l)

    local count=0

    if [[ $png_count -gt 0 ]]; then
        # ── Mode A : PNGs natifs ────────────────────────────────
        find "$src_variant/cursors" -maxdepth 1 -type f ! -name "*.png" \
            -exec cp {} "$dst_variant/cursors/" \;

        while IFS= read -r -d '' png; do
            local rel_path="${png#$src_variant/}"
            local dst_png="$dst_variant/$rel_path"
            mkdir -p "$(dirname "$dst_png")"
            recolor_png "$png" "$dst_png"
            ((count++))
        done < <(find "$src_variant" -name "*.png" -print0)

        ok "$count PNGs recolorés (mode natif)"

    else
        # ── Mode B : Binaires xcursor → xcur2png → recolor → xcursorgen ──
        warn "Pas de PNGs natifs — pipeline xcur2png activé"

        local xcur_tmp="$WORK_DIR/xcur2png_tmp"
        rm -rf "$xcur_tmp"
        mkdir -p "$xcur_tmp"

        while IFS= read -r -d '' xcur_bin; do
            local cursor_name
            cursor_name=$(basename "$xcur_bin")

            local cur_work="$xcur_tmp/$cursor_name"
            mkdir -p "$cur_work"

            # Extraction des PNGs depuis le binaire xcursor
            if ! xcur2png "$xcur_bin" -d "$cur_work" 2>/dev/null; then
                warn "xcur2png échoué sur $cursor_name — skip"
                continue
            fi

            # Vérification qu'on a bien des PNGs
            local extracted_count
            extracted_count=$(find "$cur_work" -name "*.png" 2>/dev/null | wc -l)
            if [[ $extracted_count -eq 0 ]]; then
                warn "Aucun PNG extrait pour $cursor_name — skip"
                continue
            fi

            # Recoloration de chaque PNG extrait
            local png_list=()
            while IFS= read -r -d '' png; do
                local tmp_png="${png%.png}_recolored.png"
                recolor_png "$png" "$tmp_png"
                mv "$tmp_png" "$png"
                png_list+=("$png")
                count=$((count + 1))
            done < <(find "$cur_work" -name "*.png" -print0)

            # Génération du .cursor config pour xcursorgen
            local cursor_cfg="$cur_work/${cursor_name}.cursor"
            : > "$cursor_cfg"
            for png_file in "${png_list[@]}"; do
                local size
                size=$(magick identify "$png_file" 2>/dev/null | awk '{print $3}' | cut -d'x' -f1)
                [[ -z "$size" || ! "$size" =~ ^[0-9]+$ ]] && size=32
                echo "$size 0 0 $png_file" >> "$cursor_cfg"
            done

            # Rebuild du binaire xcursor recolorié
            local output_bin="$dst_variant/cursors/$cursor_name"
            xcursorgen "$cursor_cfg" "$output_bin" 2>/dev/null || \
                warn "xcursorgen échoué sur $cursor_name"

        done < <(find "$src_variant/cursors" -maxdepth 1 -type f -not -type l -print0)

        ok "$count PNGs recolorés et xcursors rebuildés (mode xcur2png)"
        rm -rf "$xcur_tmp"
    fi
}

# ── Reconstruction des fichiers xcursor ──────────────────────────
rebuild_xcursors() {
    local variant_dir="$1"

    log "Reconstruction des xcursors dans $(basename "$variant_dir")..."

    # On cherche les .cursor config files (format xcursorgen)
    # Structure : cursors/<name>.cursor ou cursors/<name> (binaire déjà buildé)
    # phinger utilise des PNGs par taille dans des sous-dossiers
    # et des fichiers de config .cursor à la racine du curseur

    local built=0
    local skipped=0

    # Si les curseurs source sont déjà des binaires xcursor (pas des .cursor configs),
    # on a juste à remplacer les PNGs dans un thème qui a déjà ses binaires.
    # Dans ce cas on rebuild via le script de phinger si dispo, sinon on copie.

    # Détection : est-ce qu'on a des .cursor files ou des binaires directs ?
    local cursor_configs
    cursor_configs=$(find "$variant_dir/cursors" -maxdepth 1 -name "*.cursor" 2>/dev/null | wc -l)

    if [[ $cursor_configs -gt 0 ]]; then
        # Mode build depuis configs
        while IFS= read -r -d '' cursor_cfg; do
            local cursor_name
            cursor_name=$(basename "$cursor_cfg" .cursor)
            local output="$variant_dir/cursors/$cursor_name"
            xcursorgen "$cursor_cfg" "$output" 2>/dev/null && ((built++)) || ((skipped++))
        done < <(find "$variant_dir/cursors" -name "*.cursor" -print0)
        ok "Xcursors : $built buildés, $skipped ignorés"
    else
        # Mode B géré directement dans recolor_variant (xcur2png pipeline)
        ok "Xcursors rebuildés via pipeline xcur2png"
    fi
}

# ── Création du index.theme ──────────────────────────────────────
create_index_theme() {
    local variant_dir="$1"
    local variant_name="$2"

    cat > "$variant_dir/index.theme" << EOF
[Icon Theme]
Name=$variant_name
Comment=Grimoire cursor theme — tons chauds sombres, rose-violet, orange
Example=default
Inherits=hicolor
EOF
    ok "index.theme créé"
}

# ── Installation ──────────────────────────────────────────────────
install_theme() {
    local build_dir="$1"

    log "Installation dans $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cp -r "$build_dir/." "$INSTALL_DIR/"

    # Aussi dans /usr/share/icons pour SDDM
    if [[ -w /usr/share/icons ]]; then
        log "Installation système dans /usr/share/icons/$THEME_NAME..."
        sudo cp -r "$build_dir/." "/usr/share/icons/$THEME_NAME/"
    else
        warn "/usr/share/icons non accessible sans sudo — installation user seulement"
        warn "Pour SDDM : sudo cp -r $INSTALL_DIR /usr/share/icons/"
    fi

    ok "Thème installé dans $INSTALL_DIR"
}

# ── Intégration dotfiles ──────────────────────────────────────────
integrate_dotfiles() {
    log "Intégration dans les dotfiles Grimoire..."

    # Dossier curseurs dans dotfiles
    local cursor_dotfiles="$DOTFILES_DIR/themes/grimoire-cursors"
    mkdir -p "$cursor_dotfiles"
    cp -r "$INSTALL_DIR/." "$cursor_dotfiles/"
    ok "Curseurs copiés dans $cursor_dotfiles"

    # Hyprland : env cursor
    local hypr_env="$DOTFILES_DIR/hypr/.config/hypr/lua/env.lua"
    if [[ -f "$hypr_env" ]]; then
        if grep -q "XCURSOR_THEME" "$hypr_env"; then
            warn "XCURSOR_THEME déjà présent dans env.lua — vérifie manuellement"
        else
            cat >> "$hypr_env" << 'EOF'

-- Curseur Grimoire
hl.env("XCURSOR_THEME", "phinger-cursors-grimoire")
hl.env("XCURSOR_SIZE", "24")
EOF
            ok "env.lua mis à jour avec XCURSOR_THEME"
        fi
    else
        warn "env.lua non trouvé à $hypr_env"
        log "Ajoute manuellement dans ton env.lua :"
        echo -e "  ${Y}hl.env(\"XCURSOR_THEME\", \"phinger-cursors-grimoire\")${N}"
        echo -e "  ${Y}hl.env(\"XCURSOR_SIZE\", \"24\")${N}"
    fi

    # GTK settings.ini
    local gtk3="$HOME/.config/gtk-3.0/settings.ini"
    local gtk4="$HOME/.config/gtk-4.0/settings.ini"
    for gtk_cfg in "$gtk3" "$gtk4"; do
        if [[ -f "$gtk_cfg" ]]; then
            if grep -q "gtk-cursor-theme-name" "$gtk_cfg"; then
                sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME_NAME/" "$gtk_cfg"
                ok "$(basename "$gtk_cfg") mis à jour"
            else
                echo "gtk-cursor-theme-name=$THEME_NAME" >> "$gtk_cfg"
                echo "gtk-cursor-theme-size=24" >> "$gtk_cfg"
                ok "$(basename "$gtk_cfg") mis à jour"
            fi
        fi
    done

    # ~/.icons/default/index.theme pour les apps X11
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$THEME_NAME
EOF
    ok "~/.icons/default/index.theme mis à jour"
}

# ── Résumé final ──────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${M}╔══════════════════════════════════════════════╗${N}"
    echo -e "${M}║    🔮 Grimoire Cursors — Installation OK    ║${N}"
    echo -e "${M}╚══════════════════════════════════════════════╝${N}"
    echo ""
    echo -e "  Thème installé : ${C}$THEME_NAME${N}"
    echo -e "  Emplacement    : ${C}$INSTALL_DIR${N}"
    echo ""
    echo -e "${W}Prochaines étapes :${N}"
    echo -e "  1. ${Y}hyprctl reload${N}           — recharger Hyprland"
    echo -e "  2. ${Y}nwg-look${N}                 — vérifier le curseur GTK"
    echo -e "  3. Relancer une app GTK pour voir le résultat"
    echo ""
    echo -e "${W}Pour SDDM :${N}"
    echo -e "  ${Y}sudo cp -r $INSTALL_DIR /usr/share/icons/${N}"
    echo -e "  puis éditer /etc/sddm.conf.d/grimoire.conf :"
    echo -e "  ${Y}CursorTheme=$THEME_NAME${N}"
    echo ""
    echo -e "${W}Dotfiles :${N}"
    echo -e "  ${Y}cd ~/dotfiles && git add themes/grimoire-cursors && git commit -m \"feat: curseur Grimoire\"${N}"
    echo ""
}

# ── Pipeline principal ────────────────────────────────────────────
main() {
    echo -e "${M}"
    echo "  ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██╗██████╗ ███████╗"
    echo "  ██╔════╝ ██╔══██╗██║████╗ ████║██╔═══██╗██║██╔══██╗██╔════╝"
    echo "  ██║  ███╗██████╔╝██║██╔████╔██║██║   ██║██║██████╔╝█████╗  "
    echo "  ██║   ██║██╔══██╗██║██║╚██╔╝██║██║   ██║██║██╔══██╗██╔══╝  "
    echo "  ╚██████╔╝██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██║██║  ██║███████╗"
    echo "   ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝"
    echo -e "${C}                    Cursor Theme Builder${N}"
    echo ""

    check_deps
    download_source

    # Détection des variants disponibles
    local variants
    variants=$(find "$WORK_DIR/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    if [[ -z "$variants" ]]; then
        err "Aucun variant trouvé dans $WORK_DIR/themes/"
    fi

    log "Variants source trouvés :"
    echo "$variants" | while read -r v; do echo "  → $(basename "$v")"; done

    # On prend le variant principal (phinger-cursors, pas light)
    local src_variant
    src_variant=$(echo "$variants" | grep -v "light" | head -1)

    if [[ -z "$src_variant" ]]; then
        src_variant=$(echo "$variants" | head -1)
    fi

    log "Variant sélectionné : $(basename "$src_variant")"

    # Build dir
    local build_dir="$WORK_DIR/build/$THEME_NAME"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"

    # Recoloration
    recolor_variant "$src_variant" "$build_dir"

    # Rebuild xcursors si configs disponibles
    rebuild_xcursors "$build_dir"

    # index.theme
    create_index_theme "$build_dir" "Phinger Cursors Grimoire"

    # Installation
    install_theme "$build_dir"

    # Intégration dotfiles
    if [[ -d "$DOTFILES_DIR" ]]; then
        integrate_dotfiles
    else
        warn "~/dotfiles non trouvé — intégration dotfiles skippée"
    fi

    print_summary
}

main "$@"
