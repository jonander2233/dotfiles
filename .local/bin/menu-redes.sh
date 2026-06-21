opciones="󰖩   Wifi\n󰂯  Bluetooth"

eleccion=$(echo -e "$opciones" | wofi -j --dmenu --width 350 --lines 3 )

case "$eleccion" in
    "󰂯  Bluetooth")
        ~/.local/bin/wofi-bluetooth.sh &
        ;;
    "󰖩   Wifi")
        nmsurf &
        ;;
    *)
        # Si el usuario presiona ESC o cierra el menú sin elegir nada
        exit 0
        ;;
esac
