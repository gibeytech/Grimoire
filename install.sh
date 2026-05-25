#!/usr/bin/env bash
# =============================================================================
#  ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██╗██████╗ ███████╗
# ██╔════╝ ██╔══██╗██║████╗ ████║██╔═══██╗██║██╔══██╗██╔════╝
# ██║  ███╗██████╔╝██║██╔████╔██║██║   ██║██║██████╔╝█████╗
# ██║   ██║██╔══██╗██║██║╚██╔╝██║██║   ██║██║██╔══██╗██╔══╝
# ╚██████╔╝██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██║██║  ██║███████╗
#  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝
# =============================================================================
#  Un grimoire Hyprland pour la communauté francophone 🔮
#  https://github.com/gibeytech/Grimoire
#  Auteur : Jonathan Bourriaud
#  Licence : MIT
# =============================================================================

set -euo pipefail

# =============================================================================
# COULEURS & STYLES
# =============================================================================
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

PRIMARY="\033[38;2;224;120;154m"
SECONDARY="\033[38;2;255;184;108m"
TERTIARY="\033[38;2;255;110;110m"
CYAN="\033[38;2;164;255;255m"
GREEN="\033[38;2;105;255;148m"
PURPLE="\033[38;2;189;147;249m"
TEXT="\033[38;2;248;248;242m"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$DOTFILES_DIR/grimoire-install.log"
AUR_HELPER=""
ERRORS=0
START_TIME=$(date +%s)

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

log() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') | $*" >>"$LOG_FILE"
}

banner() {
  clear
  echo -e "${PRIMARY}${BOLD}"
  echo "  ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██╗██████╗ ███████╗"
  echo " ██╔════╝ ██╔══██╗██║████╗ ████║██╔═══██╗██║██╔══██╗██╔════╝"
  echo " ██║  ███╗██████╔╝██║██╔████╔██║██║   ██║██║██████╔╝█████╗  "
  echo " ██║   ██║██╔══██╗██║██║╚██╔╝██║██║   ██║██║██╔══██╗██╔══╝  "
  echo " ╚██████╔╝██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██║██║  ██║███████╗"
  echo "  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝"
  echo -e "${RESET}"
  echo -e "${SECONDARY}${BOLD}  Un grimoire Hyprland pour la communauté francophone 🔮${RESET}"
  echo -e "${DIM}  https://github.com/gibeytech/Grimoire${RESET}"
  echo ""
  echo -e "${DIM}  Journal d'installation : ${LOG_FILE}${RESET}"
  echo ""
  separator
}

separator() {
  echo -e "${DIM}$(printf '─%.0s' {1..70})${RESET}"
}

step() {
  echo ""
  echo -e "${PURPLE}${BOLD}  ✦ $1${RESET}"
  log "ÉTAPE: $1"
}

info() {
  echo -e "${CYAN}  → $1${RESET}"
  log "INFO: $1"
}

success() {
  echo -e "${GREEN}  ✔ $1${RESET}"
  log "OK: $1"
}

warn() {
  echo -e "${SECONDARY}  ⚠ $1${RESET}"
  log "AVERTISSEMENT: $1"
}

error() {
  echo -e "${TERTIARY}${BOLD}  ✘ $1${RESET}"
  log "ERREUR: $1"
  ERRORS=$((ERRORS + 1))
}

fatal() {
  echo ""
  echo -e "${TERTIARY}${BOLD}  ✘ ERREUR FATALE : $1${RESET}"
  echo -e "${DIM}  Consultez le journal : ${LOG_FILE}${RESET}"
  log "FATAL: $1"
  exit 1
}

confirm() {
  local msg="$1"
  local default="${2:-o}"
  local prompt

  if [[ "$default" == "o" ]]; then
    prompt="${PRIMARY}[O/n]${RESET}"
  else
    prompt="${PRIMARY}[o/N]${RESET}"
  fi

  echo -ne "${TEXT}  ? ${msg} ${prompt} ${RESET}"
  read -r response
  response="${response:-$default}"
  [[ "$response" =~ ^[oOyY]$ ]]
}

progress() {
  local current=$1
  local total=$2
  local label="$3"
  local percent=$((current * 100 / total))
  local filled=$((percent / 2))
  local bar=""

  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = filled; i < 50; i++)); do bar+="░"; done

  printf "\r  ${CYAN}[${bar}]${RESET} ${TEXT}%3d%% — %s${RESET}" "$percent" "$label"
}

# =============================================================================
# VÉRIFICATIONS PRÉALABLES
# =============================================================================

check_not_root() {
  if [[ "$EUID" -eq 0 ]]; then
    fatal "Ne pas exécuter ce script en root. Utilisez votre compte utilisateur normal."
  fi
}

check_arch() {
  if ! command -v pacman &>/dev/null; then
    fatal "Ce script est conçu pour Arch Linux / CachyOS (pacman requis)."
  fi
  success "Distribution compatible détectée"
}

check_internet() {
  info "Vérification de la connexion internet..."
  if ! ping -c 1 archlinux.org &>/dev/null; then
    fatal "Pas de connexion internet. Vérifiez votre réseau."
  fi
  success "Connexion internet active"
}

check_hyprland() {
  if ! command -v Hyprland &>/dev/null; then
    warn "Hyprland n'est pas installé. Il sera installé avec les paquets."
  else
    local version
    version=$(Hyprland --version 2>/dev/null | head -1 || echo "inconnue")
    success "Hyprland déjà présent ($version)"
  fi
}

detect_aur_helper() {
  step "Détection du helper AUR"

  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    success "paru détecté"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    success "yay détecté"
  else
    warn "Aucun helper AUR trouvé. Installation de yay..."
    install_yay
  fi

  info "Helper AUR utilisé : ${BOLD}${AUR_HELPER}${RESET}"
}

install_yay() {
  info "Clonage de yay depuis l'AUR..."
  local tmp_dir
  tmp_dir=$(mktemp -d)

  if git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay" >>"$LOG_FILE" 2>&1; then
    pushd "$tmp_dir/yay" >/dev/null
    if makepkg -si --noconfirm >>"$LOG_FILE" 2>&1; then
      success "yay installé avec succès"
      AUR_HELPER="yay"
    else
      warn "Échec de yay, tentative avec paru..."
      install_paru
    fi
    popd >/dev/null
  else
    warn "Impossible de cloner yay, tentative avec paru..."
    install_paru
  fi

  rm -rf "$tmp_dir"
}

install_paru() {
  info "Clonage de paru depuis l'AUR..."
  local tmp_dir
  tmp_dir=$(mktemp -d)

  if git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru" >>"$LOG_FILE" 2>&1; then
    pushd "$tmp_dir/paru" >/dev/null
    if makepkg -si --noconfirm >>"$LOG_FILE" 2>&1; then
      success "paru installé avec succès"
      AUR_HELPER="paru"
    else
      fatal "Impossible d'installer yay ou paru. Installez l'un d'eux manuellement."
    fi
    popd >/dev/null
  else
    fatal "Impossible de cloner paru depuis l'AUR."
  fi

  rm -rf "$tmp_dir"
}

# =============================================================================
# INSTALLATION DES PAQUETS
# =============================================================================

install_packages() {
  step "Installation des paquets"

  local pacman_packages=(
    # Compositeur & protocoles
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    qt5-wayland
    qt6-wayland
    # Barre
    waybar
    # Terminal & shell
    kitty
    fish
    starship
    # Launcher
    rofi-wayland
    # Notifications
    swaync
    # Éditeur
    neovim
    # Wallpaper & lock & idle
    hyprpaper
    hyprlock
    hypridle
    # Logout
    wlogout
    # Bluetooth
    bluez
    bluez-utils
    blueman
    # Fetch
    fastfetch
    chafa
    # Dotfiles
    stow
    # Polices
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
    # Outils Wayland
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    # GTK
    nwg-look
    # Gestionnaire de fichiers
    thunar
    thunar-volman
    gvfs
    # Polkit
    polkit-gnome
    # Presse-papier persistant
    cliphist
    # Réseau GUI
    network-manager-applet
    # Lumière bleue
    hyprsunset
    # SDDM & dépendances QML
    sddm
    qt5-quickcontrols2
    qt5-graphicaleffects
    qt5-svg
    # Curseurs
    imagemagick
    xorg-xcursorgen
    # Multi-boot
    os-prober
    # Dépendances
    python-cairosvg
    git
    base-devel
  )

  local aur_packages=(
    hyprpicker
    wlogout
    brave-bin
    obsidian
    xcur2png
    xdg-terminal-exec
    swayosd-git
    onlyoffice-bin
  )

  info "Mise à jour du système..."
  if sudo pacman -Syu --noconfirm >>"$LOG_FILE" 2>&1; then
    success "Système mis à jour"
  else
    error "Échec de la mise à jour système"
  fi

  info "Installation des paquets officiels (${#pacman_packages[@]} paquets)..."
  local count=0
  for pkg in "${pacman_packages[@]}"; do
    count=$((count + 1))
    progress "$count" "${#pacman_packages[@]}" "$pkg"
    if ! sudo pacman -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1; then
      warn "Paquet ignoré ou introuvable : $pkg"
    fi
  done
  echo ""
  success "Paquets officiels installés"

  count=0
  for pkg in "${aur_packages[@]}"; do
    count=$((count + 1))
    progress "$count" "${#aur_packages[@]}" "$pkg"
    if [[ "$pkg" == "swayosd-git" ]]; then
      echo ""
      warn "SwayOSD compile depuis les sources Rust — 5-10 min ☕"
    fi
    if ! $AUR_HELPER -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1; then
      warn "Paquet AUR ignoré ou introuvable : $pkg"
    fi
  done
}

# =============================================================================
# DÉPLOIEMENT DES DOTFILES (GNU Stow)
# =============================================================================

deploy_dotfiles() {
  step "Déploiement des dotfiles via GNU Stow"

  local modules=(
    hypr
    waybar
    kitty
    rofi
    fish
    starship
    swaync
    fastfetch
    nvim
    hyprpaper
    hyprlock
    hypridle
    wlogout
  )

  cd "$DOTFILES_DIR"

  local count=0
  for module in "${modules[@]}"; do
    count=$((count + 1))
    progress "$count" "${#modules[@]}" "$module"

    if [[ ! -d "$DOTFILES_DIR/$module" ]]; then
      warn "Module absent, ignoré : $module"
      continue
    fi

    local target_dir="$HOME/.config/$(basename "$module")"
    if [[ -d "$target_dir" && ! -L "$target_dir" ]]; then
      info "Sauvegarde de ~/.config/$module → ~/.config/$module.bak"
      mv "$target_dir" "${target_dir}.bak" >>"$LOG_FILE" 2>&1 || true
    fi

    if stow --target="$HOME" "$module" >>"$LOG_FILE" 2>&1; then
      log "OK stow: $module"
    else
      if stow --adopt --target="$HOME" "$module" >>"$LOG_FILE" 2>&1; then
        log "OK stow (adopt): $module"
      else
        error "Échec du stow pour : $module"
      fi
    fi
  done
  echo ""
  success "Dotfiles déployés"
}

# =============================================================================
# CONFIGURATION DU SHELL
# =============================================================================

setup_shell() {
  step "Configuration du shell Fish"

  if command -v fish &>/dev/null; then
    local fish_path
    fish_path=$(command -v fish)

    if ! grep -q "$fish_path" /etc/shells; then
      info "Ajout de fish à /etc/shells..."
      echo "$fish_path" | sudo tee -a /etc/shells >>"$LOG_FILE" 2>&1
    fi

    if [[ "$SHELL" == "$fish_path" ]]; then
      success "Fish est déjà le shell par défaut"
    else
      info "Définition de fish comme shell par défaut..."
      if sudo chsh -s "$fish_path" "$USER" >>"$LOG_FILE" 2>&1; then
        success "Shell par défaut → fish"
      else
        warn "Impossible de changer le shell (peut-être déjà fish sur CachyOS)"
      fi
    fi
  else
    error "Fish n'est pas installé, shell non modifié"
  fi
}

# =============================================================================
# THÈME SDDM
# =============================================================================

setup_sddm() {
  step "Configuration du thème SDDM"

  local sddm_theme_src="$DOTFILES_DIR/themes/grimoire-sddm"
  local sddm_theme_dst="/usr/share/sddm/themes/grimoire-sddm"

  if [[ ! -d "$sddm_theme_src" ]]; then
    warn "Thème SDDM introuvable dans $sddm_theme_src — ignoré"
    return
  fi

  info "Copie du thème SDDM..."
  if sudo cp -r "$sddm_theme_src" "$sddm_theme_dst" >>"$LOG_FILE" 2>&1; then
    success "Thème SDDM copié"
  else
    error "Impossible de copier le thème SDDM"
    return
  fi

  info "Application du thème SDDM..."
  sudo mkdir -p /etc/sddm.conf.d

  sudo tee /etc/sddm.conf.d/grimoire.conf >/dev/null <<EOF
[Theme]
Current=grimoire-sddm

[General]
Numlock=on
EOF

  info "Activation du service SDDM..."
  if sudo systemctl enable sddm >>"$LOG_FILE" 2>&1; then
    success "SDDM activé au démarrage"
  else
    warn "SDDM déjà activé ou erreur ignorée"
  fi

  success "Thème SDDM Grimoire configuré"
}

# =============================================================================
# THÈME GRUB
# =============================================================================

setup_grub() {
  step "Configuration du thème GRUB"
  set +e

  local grub_theme_src="$DOTFILES_DIR/themes/grimoire-grub"
  local grub_theme_dst="/boot/grub/themes/grimoire"

  if [[ ! -d "$grub_theme_src" ]]; then
    warn "Thème GRUB introuvable dans $grub_theme_src — ignoré"
    set -e
    return
  fi

  info "Copie du thème GRUB..."
  if sudo cp -r "$grub_theme_src" "$grub_theme_dst" >>"$LOG_FILE" 2>&1; then
    success "Thème GRUB copié"
  else
    error "Impossible de copier le thème GRUB"
    set -e
    return
  fi

  info "Mise à jour de la configuration GRUB..."
  local grub_conf="/etc/default/grub"
  local theme_line="GRUB_THEME=\"${grub_theme_dst}/theme.txt\""

  if grep -q "^GRUB_THEME=" "$grub_conf"; then
    sudo sed -i "s|^GRUB_THEME=.*|${theme_line}|" "$grub_conf"
  else
    echo "$theme_line" | sudo tee -a "$grub_conf" >/dev/null
  fi

  if grep -q "^#GRUB_DISABLE_OS_PROBER" "$grub_conf" 2>/dev/null; then
    sudo sed -i "s|^#GRUB_DISABLE_OS_PROBER.*|GRUB_DISABLE_OS_PROBER=false|" "$grub_conf"
  elif ! grep -q "^GRUB_DISABLE_OS_PROBER" "$grub_conf" 2>/dev/null; then
    echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a "$grub_conf" >/dev/null
  fi
  info "os-prober activé dans /etc/default/grub"

  info "Détection des autres disques pour le dual boot..."
  local current_disk
  current_disk=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" 2>/dev/null | head -1 || echo "")
  log "Disque actuel : $current_disk"

  local tmp_efi
  tmp_efi=$(mktemp -d)
  local other_efi_mounted=false

  if [[ -n "$current_disk" ]]; then
    while IFS= read -r efi_part; do
      local efi_disk
      efi_disk=$(lsblk -no PKNAME "$efi_part" 2>/dev/null | head -1 || echo "")
      if [[ -n "$efi_disk" && "$efi_disk" != "$current_disk" ]]; then
        info "Montage EFI : $efi_part"
        if sudo mount "$efi_part" "$tmp_efi" >>"$LOG_FILE" 2>&1; then
          other_efi_mounted=true
          log "EFI monté : $efi_part"
        fi
      fi
    done < <(lsblk -rno NAME,FSTYPE 2>/dev/null | awk '$2=="vfat"{print "/dev/"$1}')
  fi

  local os_prober_result
  os_prober_result=$(sudo os-prober 2>/dev/null || true)
  log "os-prober résultat : ${os_prober_result:-rien}"

  if [[ "$other_efi_mounted" == true ]]; then
    sudo umount "$tmp_efi" >>"$LOG_FILE" 2>&1 || true
  fi
  rm -rf "$tmp_efi"

  if [[ -z "$os_prober_result" ]]; then
    warn "os-prober n'a rien détecté — ajout manuel des entrées btrfs"
    setup_grub_custom_entries
  else
    success "os-prober a détecté : $os_prober_result"
  fi

  info "Régénération de grub.cfg..."
  if sudo grub-mkconfig -o /boot/grub/grub.cfg >>"$LOG_FILE" 2>&1; then
    success "GRUB configuré avec le thème Grimoire"
  else
    error "Échec de la régénération de grub.cfg"
  fi

  set -e
}

setup_grub_custom_entries() {
  set +e

  local custom_file="/etc/grub.d/40_custom"
  local current_disk
  current_disk=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" 2>/dev/null | head -1 || echo "")
  local entries_added=0

  while IFS= read -r part; do
    local part_disk
    part_disk=$(lsblk -no PKNAME "$part" 2>/dev/null | head -1 || echo "")

    if [[ -z "$part_disk" || "$part_disk" == "$current_disk" ]]; then
      continue
    fi

    local uuid
    uuid=$(sudo blkid -s UUID -o value "$part" 2>/dev/null || true)
    if [[ -z "$uuid" ]]; then
      continue
    fi

    local tmp_mnt
    tmp_mnt=$(mktemp -d)
    local kernel_name="vmlinuz-linux-cachyos"
    local initrd_name="initramfs-linux-cachyos.img"

    if sudo mount -o subvol=@,ro "$part" "$tmp_mnt" >>"$LOG_FILE" 2>&1; then
      local found_kernel
      found_kernel=$(ls "$tmp_mnt/boot"/vmlinuz-* 2>/dev/null | head -1 | xargs -I{} basename {} 2>/dev/null || true)
      if [[ -n "$found_kernel" ]]; then
        kernel_name="$found_kernel"
        initrd_name="initramfs-${kernel_name#vmlinuz-}.img"
      fi
      sudo umount "$tmp_mnt" >>"$LOG_FILE" 2>&1 || true
    fi
    rm -rf "$tmp_mnt"

    local entry_label="CachyOS ($part_disk)"
    info "Ajout entrée GRUB : $entry_label (UUID=$uuid)"

    sudo tee -a "$custom_file" >/dev/null <<EOF

menuentry '${entry_label}' {
    insmod part_gpt
    insmod btrfs
    search --no-floppy --fs-uuid --set=root ${uuid}
    linux /@/boot/${kernel_name} root=UUID=${uuid} rootflags=subvol=@ rw quiet splash
    initrd /@/boot/${initrd_name}
}
EOF
    entries_added=$((entries_added + 1))

  done < <(lsblk -rno NAME,FSTYPE 2>/dev/null | awk '$2=="btrfs"{print "/dev/"$1}')

  if [[ $entries_added -gt 0 ]]; then
    success "$entries_added entrée(s) GRUB ajoutée(s) dans 40_custom"
  else
    warn "Aucun autre disque btrfs détecté"
  fi

  set -e
}

# =============================================================================
# THÈME GTK
# =============================================================================

setup_gtk() {
  step "Configuration du thème GTK"

  local gtk_theme_src="$DOTFILES_DIR/themes/Grimoire"
  local gtk_theme_dst="$HOME/.themes/Grimoire"

  if [[ ! -d "$gtk_theme_src" ]]; then
    warn "Thème GTK introuvable dans $gtk_theme_src — ignoré"
    return
  fi

  mkdir -p "$HOME/.themes"

  info "Copie du thème GTK..."
  if cp -r "$gtk_theme_src" "$gtk_theme_dst" >>"$LOG_FILE" 2>&1; then
    success "Thème GTK copié dans ~/.themes/Grimoire"
  else
    error "Impossible de copier le thème GTK"
    return
  fi

  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "Grimoire" 2>/dev/null || true
    success "Thème GTK appliqué via gsettings"
  else
    info "Ouvrez nwg-look pour appliquer le thème GTK manuellement"
  fi
}

# =============================================================================
# BLUETOOTH
# =============================================================================

setup_bluetooth() {
  step "Activation du Bluetooth"

  if sudo systemctl enable --now bluetooth >>"$LOG_FILE" 2>&1; then
    success "Service Bluetooth activé"
  else
    warn "Impossible d'activer le Bluetooth (ignoré)"
  fi
}

# =============================================================================
# RÉPERTOIRES & WALLPAPERS
# =============================================================================

setup_directories() {
  step "Création des répertoires nécessaires"

  local dirs=(
    "$HOME/Pictures/wallpapers"
    "$HOME/Pictures/screenshots"
    "$HOME/.local/share/fonts"
  )

  for dir in "${dirs[@]}"; do
    if mkdir -p "$dir" >>"$LOG_FILE" 2>&1; then
      success "Créé : $dir"
    else
      error "Impossible de créer : $dir"
    fi
  done

  local wallpaper_src="$DOTFILES_DIR/wallpapers"
  local wallpaper_dst="$HOME/Pictures/wallpapers"

  if [[ -d "$wallpaper_src" ]]; then
    cp "$wallpaper_src"/* "$wallpaper_dst/" >>"$LOG_FILE" 2>&1
    success "Wallpapers copiés dans ~/Pictures/wallpapers/"
  else
    warn "Dossier wallpapers/ introuvable dans le repo"
  fi
}

# =============================================================================
# PERMISSIONS DES SCRIPTS
# =============================================================================

setup_scripts() {
  step "Configuration des scripts"

  if [[ -d "$DOTFILES_DIR/scripts" ]]; then
    if chmod +x "$DOTFILES_DIR"/scripts/*.sh >>"$LOG_FILE" 2>&1; then
      success "Scripts rendus exécutables"
    else
      warn "Aucun script .sh trouvé dans scripts/"
    fi
  else
    warn "Dossier scripts/ introuvable"
  fi
}

# =============================================================================
# CURSEURS GRIMOIRE
# =============================================================================

setup_cursors() {
  step "Installation du thème curseur (Catppuccin Mocha Mauve)"
  set +e

  local cursor_name="catppuccin-mocha-mauve-cursors"
  local cursor_zip="catppuccin-mocha-mauve-cursors.zip"
  local cursor_url="https://github.com/catppuccin/cursors/releases/latest/download/${cursor_zip}"
  local install_dir="$HOME/.local/share/icons/$cursor_name"

  if [[ -d "$install_dir" ]]; then
    info "Curseur $cursor_name déjà installé — skip"
    set -e
    return
  fi

  info "Téléchargement de $cursor_name..."
  local tmp_dir
  tmp_dir=$(mktemp -d)

  if ! wget -q --show-progress "$cursor_url" -O "$tmp_dir/$cursor_zip" >>"$LOG_FILE" 2>&1; then
    error "Échec du téléchargement du curseur — voir le log"
    rm -rf "$tmp_dir"
    set -e
    return
  fi

  info "Extraction du curseur..."
  if ! unzip -q "$tmp_dir/$cursor_zip" -d "$HOME/.local/share/icons/" >>"$LOG_FILE" 2>&1; then
    error "Échec de l'extraction du curseur"
    rm -rf "$tmp_dir"
    set -e
    return
  fi

  rm -rf "$tmp_dir"
  success "Curseur installé dans $install_dir"

  # Copie dans /usr/share/icons pour SDDM
  sudo cp -r "$install_dir" /usr/share/icons/ >>"$LOG_FILE" 2>&1 &&
    success "Curseur copié dans /usr/share/icons/ pour SDDM" ||
    warn "Impossible de copier dans /usr/share/icons/ — SDDM utilisera le curseur par défaut"

  # Mise à jour de ~/.icons/default
  mkdir -p "$HOME/.icons/default"
  cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$cursor_name
EOF
  success "~/.icons/default/index.theme mis à jour"

  set -e
}

# =============================================================================
# TERMINAL PAR DÉFAUT (xdg-terminal-exec)
# =============================================================================

setup_xdg_terminal() {
  step "Configuration de Kitty comme terminal par défaut"

  local xdg_conf="$HOME/.config/xdg-terminals.list"
  mkdir -p "$HOME/.config"
  echo "kitty.desktop" >"$xdg_conf"
  success "Kitty défini comme terminal par défaut ($xdg_conf)"
}

# =============================================================================
# SWAYOSD
# =============================================================================

setup_swayosd() {
  step "Configuration de SwayOSD"

  if command -v swayosd-server &>/dev/null; then
    success "SwayOSD déjà installé"
  else
    warn "SwayOSD non trouvé — vérifiez l'installation AUR"
  fi

  info "SwayOSD sera lancé automatiquement via autostart.lua au démarrage de Hyprland"
  success "SwayOSD configuré"
}

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================

summary() {
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  local minutes=$((duration / 60))
  local seconds=$((duration % 60))

  echo ""
  separator
  echo ""

  if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}  🔮 Installation de Grimoire terminée avec succès !${RESET}"
  else
    echo -e "${SECONDARY}${BOLD}  🔮 Installation terminée avec ${ERRORS} avertissement(s).${RESET}"
    echo -e "${DIM}  Consultez le journal pour les détails : ${LOG_FILE}${RESET}"
  fi

  echo ""
  echo -e "${TEXT}  Durée : ${minutes}m ${seconds}s${RESET}"
  echo -e "${TEXT}  Journal : ${LOG_FILE}${RESET}"
  echo ""
  separator
  echo ""
  echo -e "${PRIMARY}${BOLD}  Prochaines étapes :${RESET}"
  echo ""
  echo -e "${CYAN}  1.${RESET} ${TEXT}Redémarrez votre session pour appliquer tous les changements${RESET}"
  echo -e "${CYAN}  2.${RESET} ${TEXT}Placez votre wallpaper dans ~/Pictures/wallpapers/grimoire.png${RESET}"
  echo -e "${CYAN}  3.${RESET} ${TEXT}Ouvrez nwg-look pour peaufiner le thème GTK${RESET}"
  echo -e "${CYAN}  4.${RESET} ${TEXT}Lancez Hyprland depuis SDDM ou via 'Hyprland' en TTY${RESET}"
  echo -e "${CYAN}  5.${RESET} ${TEXT}Ajoutez dans autostart.lua : hl.exec_cmd(\"wl-paste --watch cliphist store\")${RESET}"
  echo -e "${CYAN}  6.${RESET} ${TEXT}Keybind presse-papier suggéré : SUPER + SHIFT + V → cliphist list | rofi -dmenu | cliphist decode | wl-copy${RESET}"
  echo ""
  echo -e "${SECONDARY}  Bienvenue dans le Grimoire. 🔮${RESET}"
  echo ""
}

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

main() {
  echo "=== Grimoire Install Log — $(date) ===" >"$LOG_FILE"

  banner

  step "Vérifications préalables"
  check_not_root
  check_arch
  check_internet
  check_hyprland

  echo ""
  echo -e "${TEXT}  Ce script va :${RESET}"
  echo -e "${DIM}  • Installer tous les paquets nécessaires (pacman + AUR)${RESET}"
  echo -e "${DIM}  • Déployer les dotfiles via GNU Stow${RESET}"
  echo -e "${DIM}  • Configurer Fish comme shell par défaut${RESET}"
  echo -e "${DIM}  • Installer les thèmes SDDM, GRUB et GTK${RESET}"
  echo -e "${DIM}  • Activer Bluetooth et SDDM${RESET}"
  echo -e "${DIM}  • Installer SwayOSD et OnlyOffice${RESET}"
  echo ""

  if ! confirm "Lancer l'installation complète de Grimoire ?"; then
    echo -e "${SECONDARY}  Installation annulée.${RESET}"
    exit 0
  fi

  detect_aur_helper
  install_packages
  setup_directories
  setup_scripts
  deploy_dotfiles
  setup_shell
  setup_sddm
  setup_grub
  setup_gtk
  setup_bluetooth
  setup_cursors
  setup_xdg_terminal
  setup_swayosd

  summary
}

main "$@"
