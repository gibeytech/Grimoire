<div align="center">
  <img src="assets/grimoire.png" width="200" />

  # GRIMOIRE 🔮

  ### Un grimoire Hyprland pour la communauté francophone

  [![Version](https://img.shields.io/badge/version-1.1.2-e0789a?style=for-the-badge)](https://github.com/gibeytech/Grimoire)
  [![Hyprland](https://img.shields.io/badge/Hyprland-0.55-bd93f9?style=for-the-badge)](https://hyprland.org)
  [![Lua](https://img.shields.io/badge/config-Lua-ffb86c?style=for-the-badge)](https://lua.org)
  [![Licence](https://img.shields.io/badge/licence-MIT-69ff94?style=for-the-badge)](./LICENSE)
  [![Langue](https://img.shields.io/badge/langue-Français-e0789a?style=for-the-badge)](#)
</div>

---

> 🌍 **English speakers:** This project is a community-driven Hyprland configuration tailored for the Francophone community (hence the French documentation). However, the underlying architecture is highly modular and configured in Lua. Feel free to explore the code!

---

## 📸 Aperçu

<div align="center">
  <img src="assets/screenshot-fastfetch.png" width="800" />
</div>

---

## 🔮 À propos

**Grimoire** est une configuration Hyprland complète, écrite entièrement en **Lua**, documentée en français et pensée pour la communauté francophone Linux.

Inspiré par [ML4W](https://github.com/mylinuxforwork/dotfiles), [End4](https://github.com/end-4/dots-hyprland), [Omarchy](https://github.com/basecamp/omarchy) et [TypeCraft](https://www.youtube.com/@typecraft_dev), Grimoire propose une expérience cohérente et moderne avec le thème **Grimoire** — tons chauds sombres, rose-violet et orange.

> Testé sur **CachyOS** (fresh install sans DE) — Dell Vostro 15 5501, Intel i5-1035G1, Intel Iris Plus.

---

## ✨ Stack

| Composant     | Outil                    |
| ------------- | ------------------------ |
| Compositeur   | Hyprland 0.55 (Lua)      |
| Barre         | Waybar                   |
| Terminal      | Kitty                    |
| Shell         | Fish + Starship          |
| Launcher      | Rofi                     |
| Notifications | SwayNC                   |
| Éditeur       | Neovim + LazyVim         |
| Wallpaper     | Hyprpaper                |
| Fetch         | Fastfetch                |
| Lock          | Hyprlock                 |
| Idle          | Hypridle                 |
| Logout        | Wlogout                  |
| Bluetooth     | Bluez + Blueman          |
| Curseur       | Catppuccin Mocha Mauve   |
| Dotfiles      | GNU Stow                 |
| OSD           | SwayOSD                  |
| Distro        | CachyOS / Arch Linux     |

---

## 🚀 Installation

### Prérequis

- Arch Linux ou CachyOS
- Connexion internet
- Droits sudo
- Git installé

### Installation automatique

```bash
git clone https://github.com/gibeytech/Grimoire.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Le script :
- Détecte automatiquement votre helper AUR (paru / yay, ou l'installe)
- Installe tous les paquets nécessaires
- Déploie les dotfiles via GNU Stow
- Configure Fish comme shell par défaut
- Installe les thèmes SDDM, GRUB et GTK
- Active Bluetooth et SDDM

### Installation manuelle

```bash
git clone https://github.com/gibeytech/Grimoire.git ~/dotfiles
cd ~/dotfiles
stow hypr waybar kitty rofi fish starship swaync fastfetch \
     hyprpaper hyprlock hypridle wlogout nvim
chsh -s /usr/bin/fish
echo "kitty.desktop" > ~/.config/xdg-terminals.list
```

---

## ⌨️ Raccourcis

| Raccourci                      | Action                         |
| ------------------------------ | ------------------------------ |
| `SUPER + Entrée`               | Terminal (Kitty)               |
| `SUPER + Space`                | Launcher (Rofi)                |
| `SUPER + Q`                    | Fermer la fenêtre              |
| `SUPER + E`                    | Gestionnaire de fichiers       |
| `SUPER + W`                    | Sélecteur de wallpaper         |
| `SUPER + F`                    | Plein écran                    |
| `SUPER + V`                    | Fenêtre flottante              |
| `SUPER + P`                    | Fenêtre pseudo-tiled           |
| `SUPER + B`                    | Navigateur (Brave)             |
| `SUPER + L`                    | Verrouiller (Hyprlock)         |
| `SUPER + SHIFT + Q`            | Menu déconnexion (Wlogout)     |
| `SUPER + ←↑↓→`                 | Focus fenêtre                  |
| `SUPER + SHIFT + ←↑↓→`         | Déplacer la fenêtre            |
| `SUPER + & é " ' ( - è _ ç à` | Changer de workspace (AZERTY)  |
| `SUPER + SHIFT + & é …`        | Déplacer vers workspace        |
| `Print`                        | Capture région → presse-papier |
| `SHIFT + Print`                | Capture région → fichier       |
| `SUPER + Print`                | Capture écran → presse-papier  |

---

## 🎨 Thème Grimoire

| Variable    | Hex       | Usage             |
| ----------- | --------- | ----------------- |
| `base`      | `#221a1a` | Fond principal    |
| `surface`   | `#2d2020` | Surfaces          |
| `primary`   | `#e0789a` | Rose-violet chaud |
| `secondary` | `#ffb86c` | Orange            |
| `tertiary`  | `#ff6e6e` | Rouge-rose        |
| `text`      | `#f8f8f2` | Texte             |
| `cyan`      | `#a4ffff` | Info              |
| `green`     | `#69ff94` | Succès            |
| `purple`    | `#bd93f9` | Violet            |

---

## 📺 Multi-moniteurs

Grimoire supporte nativement la configuration double écran :

| Écran          | Résolution   | Position  |
| -------------- | ------------ | --------- |
| eDP-1 (laptop) | 1920×1080@60 | Bas       |
| HDMI-A-1       | 1920×1200@60 | Au-dessus |

La configuration est dans `hypr/.config/hypr/lua/monitors.lua`.

---

## 📁 Structure

```
dotfiles/
├── assets/                      # Images et ressources README
├── hypr/.config/hypr/           # Hyprland (Lua) — config modulaire
│   ├── hyprland.lua             # point d'entrée
│   └── lua/
│       ├── colors.lua
│       ├── keybinds.lua
│       ├── look.lua
│       ├── input.lua
│       ├── monitors.lua
│       ├── autostart.lua
│       ├── rules.lua
│       └── env.lua
├── waybar/.config/waybar/       # Barre de statut
├── kitty/.config/kitty/         # Terminal
├── rofi/.config/rofi/           # Launcher
├── fish/.config/fish/           # Shell
├── starship/.config/            # Prompt
├── swaync/.config/swaync/       # Notifications
├── fastfetch/.config/fastfetch/ # Fetch (logo grimoire.png)
├── nvim/.config/nvim/           # Neovim + LazyVim
├── hyprpaper/.config/hypr/      # Wallpaper
├── hyprlock/.config/hypr/       # Verrouillage
├── hypridle/.config/hypr/       # Idle
├── wlogout/.config/wlogout/     # Logout
├── themes/
│   ├── grimoire-sddm/           # Thème SDDM
│   ├── grimoire-grub/           # Thème GRUB
│   ├── Grimoire/                # Thème GTK
│   └── grimoire-cursors/        # Thème curseur
├── wallpapers/                  # Fonds d'écran Grimoire
├── scripts/
│   ├── wallpaper.sh
│   ├── lock.sh
│   ├── wlogout.sh
│   └── start-hyprpaper.sh
├── install.sh                   # Installateur automatique
└── README.md
```

---

## 🗺️ Roadmap

### V1 — Polish ✅
- [x] Thème SDDM Grimoire
- [x] Thème GRUB Grimoire
- [x] Renommage complet Dracula Warm → Grimoire
- [x] Icônes Wlogout custom
- [x] Support second écran HDMI-A-1
- [x] Script `install.sh` automatique
- [x] Thème curseur — Catppuccin Mocha Mauve (curseur Grimoire v2 en V2)
- [x] Keybinds finalisés (AZERTY codes, déplacement fenêtres)
- [x] xdg-terminals.list configuré (Kitty)
- [x] Waybar : date + heure + scroll volume/luminosité (SwayOSD)
- [x] Hypridle : verrouillage, dimming, dpms, suspend
- [x] Numlock persistant (Hyprland + SDDM)
- [x] Fastfetch avec logo Grimoire
- [ ] ⚠️ Fenêtres flottantes / Waybar (bug upstream Hyprland)

### V2 — Modernisation
- [ ] Waybar → AGS / Astal
- [ ] Kitty → Ghostty
- [ ] Hyprpaper → swww
- [ ] Shell Fish → ZSH
- [ ] Installateur TUI interactif
- [ ] Thèmes switchables
- [ ] Curseur Grimoire v2 — rebuild depuis Bibata (recoloration native)
- [ ] Screenshots officiels Grimoire
- [ ] GIF démo du bureau en action

### V3 — Communauté
- [ ] Site vitrine
- [ ] Discord francophone
- [ ] Logo et identité visuelle complète
- [ ] Post r/unixporn + r/linux_fr
- [ ] Article dev.to/Hashnode en français
- [ ] YouTube démo

---

## 🔧 Notes techniques

- **SwayOSD** : `swayosd-server` lancé via `autostart.lua`. Scroll molette sur modules Waybar backlight/pulseaudio
- **Hypridle** : config dans `~/.config/hypr/hypridle.conf`. Lancé avec `-c ~/.config/hypr/hypridle.conf`
- **Hyprpaper** : nécessite `start-hyprpaper.sh` avec `sleep 2` + `hyprctl hyprpaper wallpaper` pour chaque moniteur
- **Wlogout** : grille 2×2 via `-b 2`, icônes SVG convertis en PNG via `python-cairosvg`
- **SDDM** : `Numlock=on` dans `/etc/sddm.conf`, thème Grimoire fonctionnel
- **Keybinds AZERTY** : utilise `code:10` à `code:19` pour les workspaces
- **xdg-terminals.list** : `~/.config/xdg-terminals.list` pointe sur `kitty.desktop`
- **Stow** : peut nécessiter `rm -rf ~/.config/<app>` avant le stow si la config cible existe déjà
- **Fastfetch** : logo `grimoire.png` généré via `magick` + `chafa`, rendu kitty width=45 height=20

---

## 👤 Auteur

**gibeytech** — [@gibeytech](https://github.com/gibeytech)

---

## 📄 Licence

MIT — libre d'utilisation, de modification et de distribution.
