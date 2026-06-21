#!/bin/bash

# RUTA DE FONDOS DE PANTALLA
DIR=$HOME/Pictures/wallpapers

# Configuración de la ventana de wofi (en %)
WIDTH=20
HEIGHT=30

PICS=($(ls ${DIR} | grep -e ".jpg$" -e ".jpeg$" -e ".png$" -e ".gif$"))

RANDOM_PIC=${PICS[ $RANDOM % ${#PICS[@]} ]}
RANDOM_PIC_NAME="${#PICS[@]}. random"

# CONFIGURACIÓN DE WOFI
CONFIG="$HOME/.config/wofi/config"
STYLE="$HOME/.config/wofi/style.css"
COLORS="$HOME/.config/wofi/colors"

wofi_command="wofi --show dmenu \
            --conf $CONFIG --style $STYLE --color $COLORS \
            --width=$WIDTH% --height=$HEIGHT% \
            --cache-file=/dev/null \
            --hide-scroll --no-actions \
            --matching=fuzzy"

# Menú para listar los fondos de pantalla
menu_pics(){
    for i in ${!PICS[@]}; do
        if [[ -z $(echo ${PICS[$i]} | grep .gif$) ]]; then
            printf "$i. $(echo ${PICS[$i]} | cut -d. -f1)\n"
        else
            printf "$i. ${PICS[$i]}\n"
        fi
    done
    printf "$RANDOM_PIC_NAME"
}

# Asegurar que hyprpaper se está ejecutando con IPC activo
if ! pidof hyprpaper >/dev/null; then
    hyprpaper &
    sleep 0.5
fi

main() {
    # 1. Primer paso: Elegir el fondo de pantalla
    pic_choice=$(menu_pics | ${wofi_command} --prompt "Selecciona fondo...")
    
    if [[ -z $pic_choice ]]; then return; fi

    # Determinar qué imagen se va a usar
    if [ "$pic_choice" = "$RANDOM_PIC_NAME" ]; then
        SELECTED_PIC="${DIR}/${RANDOM_PIC}"
    else
        pic_index=$(echo $pic_choice | cut -d. -f1)
        SELECTED_PIC="${DIR}/${PICS[$pic_index]}"
    fi

    # 2. Segundo paso: Elegir el tipo de tema (Claro u Oscuro)
    theme_choice=$(printf "Oscuro\nClaro" | ${wofi_command} --prompt "Modo de tema...")
    
    if [[ -z $theme_choice ]]; then return; fi

    # Configurar el argumento para pywal según la elección
    WAL_ARGS=""
    if [ "$theme_choice" = "Claro" ]; then
        WAL_ARGS="-l"
    fi

    # 3. Aplicar la paleta de colores con Pywal (Lo hacemos antes del cambio visual)
    wal -i "$SELECTED_PIC" $WAL_ARGS
    $HOME/.local/bin/pywal-asus-kb.sh &
    # Obtenemos el nombre del monitor activo de forma dinámica
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
    if [[ -z "$MONITOR" ]]; then
        MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')
    fi

    # --- NUEVA UBICACIÓN DEL ENLACE SIMBÓLICO ---
    # Definimos la ruta exacta que has pedido
    ENLACE_FIJO="/home/jon/Pictures/wallpapers/current_wp/current.png"
    
    # Nos aseguramos de que la carpeta contenedora exista
    mkdir -p "/home/jon/Pictures/wallpapers/current_wp"
    
    # Borramos el enlace anterior y creamos el nuevo apuntando a la foto elegida
    rm -f "$ENLACE_FIJO"
    ln -s "$SELECTED_PIC" "$ENLACE_FIJO"
    # ---------------------------------------------

    # Aplicar cambios en tiempo real mediante hyprctl apuntando al nuevo enlace fijo
    hyprctl hyprpaper preload "$ENLACE_FIJO"
    hyprctl hyprpaper wallpaper "$MONITOR,$ENLACE_FIJO"
    
    # Limpieza para que no se sature la RAM
    hyprctl hyprpaper unload all
}

# Control para evitar instancias duplicadas de Wofi
if pidof wofi >/dev/null; then
    killall wofi
    exit 0
else
    main
fi
