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
# Asegurar que awww-daemon se está ejecutando
if ! pidof awww-daemon >/dev/null; then
    awww-daemon &
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
    # 3. Aplicar la paleta de colores con Pywal
    wal -i "$SELECTED_PIC" $WAL_ARGS
    $HOME/.local/bin/pywal-asus-kb.sh &

    # --- ENLACE SIMBÓLICO ---
    ENLACE_FIJO="/home/jon/Pictures/wallpapers/current_wp/current.png"
    mkdir -p "/home/jon/Pictures/wallpapers/current_wp"
    rm -f "$ENLACE_FIJO"
    ln -s "$SELECTED_PIC" "$ENLACE_FIJO"
    # ------------------------

    # Transición: sin efecto para GIFs, random para imágenes estáticas
    if [[ "$SELECTED_PIC" == *.gif ]]; then
        TRANSITION="none"
    else
        TRANSITION="random"
    fi

    # Aplicar el fondo con awww
    awww img "$SELECTED_PIC" \
        --transition-type $TRANSITION \
        --transition-duration 1 \
        --resize crop
}
# Control para evitar instancias duplicadas de Wofi
if pidof wofi >/dev/null; then
    killall wofi
    exit 0
else
    main
fi
