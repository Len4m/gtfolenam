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
    echo_red "\nProceso interrumpido por el usuario."
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
elif command -v busybox >/dev/null; then
    # Verificar si busybox tiene wget o curl
    if busybox wget --help >/dev/null 2>&1; then
        downloader="busybox_wget"
    elif busybox curl --help >/dev/null 2>&1; then
        downloader="busybox_curl"
    else
        echo_red "Error: Busybox está disponible pero no tiene wget ni curl."
        exit 1
    fi
else
    echo_red "Error: No está instalado ni curl ni wget, ni busybox con wget/curl."
    exit 1
fi

# Detectar awk
if command -v awk >/dev/null; then
    awk_cmd="awk"
elif command -v busybox >/dev/null && busybox awk --help >/dev/null 2>&1; then
    awk_cmd="busybox awk"
else
    echo_red "Error: No está instalado awk ni busybox con awk."
    exit 1
fi

# Detectar grep
if command -v grep >/dev/null; then
    grep_cmd="grep"
elif command -v busybox >/dev/null && busybox grep --help >/dev/null 2>&1; then
    grep_cmd="busybox grep"
else
    echo_red "Error: No está instalado grep ni busybox con grep."
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
        http_status=$(wget -q --server-response -O "$html_content" "$url" 2>&1 | $awk_cmd '/^  HTTP/{print $2}' | tail -n 1)
    elif [ "$downloader" = "busybox_curl" ]; then
        # Busybox curl no tiene la opción -w, así que usamos un enfoque diferente
        if busybox curl -s -o "$html_content" "$url"; then
            http_status="200"
        else
            http_status="404"
        fi
    elif [ "$downloader" = "busybox_wget" ]; then
        # Busybox wget no tiene --server-response, así que usamos un enfoque diferente
        if busybox wget -q -O "$html_content" "$url"; then
            http_status="200"
        else
            http_status="404"
        fi
    fi

    # Comprobar el código de estado HTTP
    if [ "$http_status" -eq 200 ]; then
        # Comprobar si existe una etiqueta <h2> con el id igual a $type
        # Busybox grep no tiene -P (PCRE), así que usamos -E (extended regex) como alternativa
        if [ "$grep_cmd" = "busybox grep" ]; then
            if $grep_cmd -qE '<h2[^>]*\bid="'$type'"[^>]*>' "$html_content"; then
                rm "$html_content"
                return 0
            fi
        else
            if $grep_cmd -qP '<h2[^>]*\bid="'$type'"[^>]*>' "$html_content"; then
                rm "$html_content"
                return 0
            fi
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
        scan_files "sudo" 'eval sudo -l -l | $awk_cmd '\''/Commands:/ { in_commands=1; next } in_commands && /^[^ ]/ { if ($0 !~ /ALL$/ && $0 !~ /Sudoers/) { gsub(/^[ \t]+/, "", $0); gsub(/[ \t]+$/, "", $0); split($0, a, " "); print a[1]; } }'\''' "sudo"
        ;;
    capabilities)
        scan_files "capabilities" "eval getcap -r / | $awk_cmd '{print \$1}'" "capabilities"
        ;;
    suid)
        scan_files "suid" "find / -perm -4000" "SUID"
        ;;
    *)
        echo_red "Tipo de escaneo desconocido: $type"
        ;;
    esac
done
