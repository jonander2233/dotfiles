#!/bin/bash

opciones="󰐥  Apagar Equipo\n󰑙  Reiniciar\n  Bloquear"


# 2. Lanzamos wofi y guardamos la selección en una variable
eleccion=$(echo -e "$opciones" | wofi -j --dmenu --width 350 --height 250 --lines 4 )
# 
# 3. Evaluamos qué opción se eligió y ejecutamos la acción
case "$eleccion" in
    "  Bloquear")
        hyprlock &
        ;;
    "󰑙  Reiniciar")
        reboot &
        ;;
    "󰐥  Apagar Equipo")
        poweroff
        ;;
    *)
        # Si el usuario presiona ESC o cierra el menú sin elegir nada
        exit 0
        ;;
esac
