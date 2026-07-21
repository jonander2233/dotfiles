#!/bin/bash

# 1. Definimos las opciones separadas por un salto de línea (\n)
#opciones="Apps\nTerminal\nWifi\nApagar Equipo"
opciones="󰀻  Apps\n Terminal\n   Navegador\n  Redes\n  Tema\n󰐥  Opciones de apagado"

# 2. Lanzamos wofi y guardamos la selección en una variable
eleccion=$(echo -e "$opciones" | wofi --dmenu --width 400 --height 250)

# 3. Evaluamos qué opción se eligió y ejecutamos la acción
case "$eleccion" in
"󰐥  Opciones de apagado")
  ~/.local/bin/menu-apagado.sh &
  ;;
"  Redes")
  ~/.local/bin/menu-redes.sh &
  ;;
"   Navegador")
  qutebrowser &
  ;;
"󰀻  Apps")
  wofi --show drun &
  ;;
" Terminal")
  kitty & # O tu gestor de archivos preferido (nautilus, dolphin, etc.)
  ;;
"  Tema")
  ~/.local/bin/wallpaper-selector-awww-hyprlock.sh &
  ;;
*)
  # Si el usuario presiona ESC o cierra el menú sin elegir nada
  exit 0
  ;;
esac
