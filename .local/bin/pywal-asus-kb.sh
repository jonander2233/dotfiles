#!/bin/bash

# Ruta al archivo de colores de pywal
COLORS_FILE="$HOME/.cache/wal/colors"

# Verificar que pywal haya generado los colores
if [ -f "$COLORS_FILE" ]; then
    # Extrae la línea 2 (color1), elimina el '#' y lo guarda en la variable
    TECLADO_COLOR=$(sed -n '4p' "$COLORS_FILE" | tr -d '#')
    
    # Aplica el color al teclado Asus
    if [ -n "$TECLADO_COLOR" ]; then
        asusctl aura effect static -c "$TECLADO_COLOR"
    fi
else
    echo "Error: No se encontró el archivo de colores de pywal."
fi
