#!/bin/bash
sleep 2
hyprpaper &
sleep 1
hyprctl hyprpaper preload "/home/joe/Pictures/wallpapers/grimoire 7.png"
sleep 0.5
hyprctl hyprpaper wallpaper "eDP-1,/home/joe/Pictures/wallpapers/grimoire 7.png"
hyprctl hyprpaper wallpaper "HDMI-A-1,/home/joe/Pictures/wallpapers/grimoire 7.png"
