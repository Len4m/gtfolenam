#!/bin/bash

# Banner
echo ICAgX19fX19fX19fX19fX19fX19fX19fXyAgX18gICAgICAgICAgICAgICAgICAgICAgICAgICAgIA0KICAvIF9fX18vXyAgX18vIF9fX18vIF9fIFwvIC8gICBfX18gIF9fX18gIF9fX18gX19fX18gX19fIA0KIC8gLyBfXyAgLyAvIC8gL18gIC8gLyAvIC8gLyAgIC8gXyBcLyBfXyBcLyBfXyBgLyBfXyBgX18gXA0KLyAvXy8gLyAvIC8gLyBfXy8gLyAvXy8gLyAvX19fLyAgX18vIC8gLyAvIC9fLyAvIC8gLyAvIC8gLw0KXF9fX18vIC9fLyAvXy8gICAgXF9fX18vX19fX18vXF9fXy9fLyAvXy9cX18sXy9fLyAvXy8gL18vIA==| base64 -d
echo -e "\nEscáner automático de binarios en GTFOBins"

# Variables
verbose=0
scan_types="sudo,suid,capabilities"
baseurl="https://gtfobins.github.io/gtfobins/"
suid_files="passwd sudo su chsh chfn gpasswd newgrp" # Ficheros que necesitan SUID normalmente para funcionar.
capabilities_files="ping" # Ficheros que necesitan capabilities normalmente para funcionar.
html_content=

# Función para manejar la señal de Ctrl+C
trap ctrl_c INT

function ctrl_c() {
    echo -e "\n\e[31mProceso interrumpido por el usuario.\e[0m"
    if [[ -n "$html_content" && -f "$html_content" ]]; then
        rm "$html_content"
    fi
    exit 1
}

# Funciones para mostrar colores
function echo_red() {
    echo -e "\e[31m$1\e[0m"
}

function echo_green() {
    echo -e "\e[32m$1\e[0m"
}

function echo_yellow() {
    echo -e "\e[33m$1\e[0m"
}

function echo_purple() {
    echo -e "\e[35m$1\e[0m"
}

# Dependencias
if command -v curl >/dev/null; then
    downloader="curl"
elif command -v wget >/dev/null; then
    downloader="wget"
else
    echo_red "Error: No está instalado ni curl ni wget."
    exit 1
fi

if ! command -v awk >/dev/null; then
    echo_red "Error: No está instalado awk."
    exit 1
fi

if ! command -v grep >/dev/null; then
    echo_red "Error: No está instalado grep."
    exit 1
fi

# Función para mostrar la ayuda
function show_help() {
    echo "Uso: $0 [-v] [-h] [-t=tipo1,tipo2,...]"
    echo ""
    echo "Opciones:"
    echo "  -v    Modo verbose. Muestra información detallada del proceso y todos los archivos, incluso si fallan la evaluación."
    echo "  -h    Muestra esta ayuda y termina."
    echo "  -t    Tipo de escaneo a realizar, separado por comas, precedido por '='."
    echo "        Opciones válidas: sudo, suid, capabilities."
    echo "        Por defecto, se escanean todos los tipos si no se especifica."
    exit 0
}

# Función para evaluar cada archivo
function evaluate_file() {
    local file=$1
    local type=$2

    # Obtener solo el nombre del binario sin el path completo
    local binary_name=$(basename "$file")

    # Comprobando si es SUID y se encuntra en suid_files
    if [[ "$type" == "suid" && " $suid_files " =~ " $binary_name " ]]; then
        if [ $verbose -eq 1 ]; then
            echo "$binary_name está en la lista de suid_files."
        fi
        return 1
    fi

    # Comprobando si es capabilities y se encuntra en capabilities_files
    if [[ "$type" == "capabilities" && " $capabilities_files " =~ " $binary_name " ]]; then
        if [ $verbose -eq 1 ]; then
            echo "$binary_name está en la lista de capabilities_files."
        fi
        return 1
    fi

    # Mostrar información solo si estamos en modo verbose
    if [ $verbose -eq 1 ]; then
        echo "** Evaluando: $binary_name"
    fi

    # Construir la URL
    local url=$baseurl$binary_name"/"

    # Obtener el contenido HTML con curl y capturar el código de estado HTTP
    local http_status

    html_content=$(mktemp)

    if [ "$downloader" = "curl" ]; then
        http_status=$(curl -s -w "%{http_code}" -o "$html_content" "$url")
    elif [ "$downloader" = "wget" ]; then
        http_status=$(wget -q --server-response -O "$html_content" "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -n 1)
    fi

    # Comprobar el código de estado HTTP
    if [ "$http_status" -eq 200 ]; then
        # Comprobar si existe una etiqueta <h2> con el id igual a $type
        if grep -qP '<h2[^>]*\bid="'$type'"[^>]*>' "$html_content"; then
            rm "$html_content"
            return 0
        fi
    else
        # La URL no está disponible
        if [ $verbose -eq 1 ]; then
            echo "La URL $url no está disponible."
        fi
    fi
    rm "$html_content"
    return 1
}

# Parseo de opciones
while getopts "vht:" opt; do
    case ${opt} in
    v)
        verbose=1
        ;;
    h)
        show_help
        ;;
    t)
        scan_types=${OPTARG}
        ;;
    \?)
        show_help
        ;;
    esac
done

# Asegurarse de que el parámetro -t se procese correctamente
if [[ $scan_types == *=* ]]; then
    scan_types=${scan_types#*=}
fi

# Convertir el parámetro -t en un array
IFS=',' read -r -a types <<<"$scan_types"

# Función para escanear y mostrar archivos de acuerdo con el tipo
function scan_files() {
    local type=$1
    local find_command=$2
    local find_desc=$3

    if [ $verbose -eq 1 ]; then
        echo_yellow "Buscando archivos con ${find_desc}..."
    fi

    declare -a files
    mapfile -t files < <($find_command 2>/dev/null)

    echo_purple "\nArchivos con ${find_desc}:"
    for file in "${files[@]}"; do
        if evaluate_file "$file" "$type"; then
            echo_green "$file"                       # Siempre mostrar en verde si evalúa a true
            echo $baseurl$(basename "$file")'#'$type # imrimimos URL.
        else
            if [ $verbose -eq 1 ]; then
                echo_red "$file" # Mostrar en rojo solo en modo verbose si evalúa a false
            fi
        fi
    done
}

# Ejecutar escaneos según los tipos especificados
for type in "${types[@]}"; do
    case $type in
    sudo)
        scan_files "sudo" 'eval sudo -l -l | awk '\''/Commands:/ { in_commands=1; next } in_commands && /^[^ ]/ { if ($0 !~ /ALL$/ && $0 !~ /Sudoers/) { gsub(/^[ \t]+/, "", $0); gsub(/[ \t]+$/, "", $0); split($0, a, " "); print a[1]; } }'\''' "sudo"
        ;;
    capabilities)
        scan_files "capabilities" "eval getcap -r / | awk '{print \$1}'" "capabilities"
        ;;
    suid)
        scan_files "suid" "find / -perm -4000" "SUID"
        ;;
    *)
        echo -e "\e[31mTipo de escaneo desconocido: $type\e[0m"
        ;;
    esac
done
