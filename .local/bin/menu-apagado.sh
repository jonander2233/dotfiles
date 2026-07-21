#!/bin/bash

# Agregamos un icono a Hibernar para mantener consistencia y evitar fallos de coincidencia
opciones="󰐥  Apagar Equipo\n󰤄  Hibernar\n󰑙  Reiniciar\n  Bloquear"

# Lanzamos wofi y limpiamos espacios extra al inicio/final si los hubiera
eleccion=$(echo -e "$opciones" | wofi -j --dmenu --width 350 --height 250 --lines 4)

case "$eleccion" in
*"Hibernar"*)
  systemctl hibernate
  ;;
*"Bloquear"*)
  hyprlock &
  ;;
*"Reiniciar"*)
  reboot
  ;;
*"Apagar"*)
  poweroff
  ;;
*)
  exit 0
  ;;
esac
