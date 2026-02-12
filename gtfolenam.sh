#!/bin/bash

# GTFOLenam v2 - Escáner de binarios en GTFOBins (modo offline)

cat << 'BANNER_EOF'
   _____ _____ ______ ___  __  
  / ____/_  __/ ____/ __ \/ /   ___  ____  ____ _____ ___ 
 / / __  / / / /_  / / / / /   / _ \/ __ \/ __ `/ __ `__ \
/ /_/ / / / / __/ / /_/ / /___/  __/ / / / /_/ / / / / / /
\____/ /_/ /_/    \____/_____/\___/_/ /_/\__,_/_/ /_/ /_/
BANNER_EOF
echo -e "\nEscáner automático de binarios en GTFOBins offline - v2"

# Variables
verbose=0
scan_types="sudo,suid,capabilities"
baseurl="https://gtfobins.org/gtfobins/"
suid_files="passwd sudo su chsh chfn gpasswd newgrp unix_chkpwd fusermount fusermount3 ssh-keysign mount umount pt_chown pam_timestamp_check"
capabilities_files="ping ping6"
flat_file=

# Limpieza al salir
cleanup() {
    rm -f "$flat_file"
}
trap cleanup EXIT
trap 'echo -e "\n\e[31mProceso interrumpido.\e[0m"; cleanup; exit 1' INT TERM

# Colores
echo_red()    { echo -e "\e[31m$1\e[0m"; }
echo_green()  { echo -e "\e[32m$1\e[0m"; }
echo_yellow() { echo -e "\e[33m$1\e[0m"; }
echo_purple() { echo -e "\e[35m$1\e[0m"; }

# Obtener path de este script
get_script_path() {
    if [[ -n "$BASH_SOURCE" ]]; then
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    else
        echo "$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    fi
}
SCRIPT_PATH=$(get_script_path)

# Listar rutas de binarios con capabilities (getcap -r devuelve "ruta capability=...")
getcap_paths() {
    $getcap_cmd -r / 2>/dev/null | while IFS= read -r line; do [[ -n "$line" ]] && echo "${line%% *}"; done
}

# Extraer datos GTFOBins (texto plano) desde el script
extract_embedded_data() {
    $sed_cmd -n "/^: <<'__GTFOBINS_END__'$/,/^__GTFOBINS_END__\$/p" "$SCRIPT_PATH" | $sed_cmd '1d;$d'
}

# Convertir api.json de GTFOBins a formato plano (A=alias, C=contexto)
json_to_flat() {
    local json_path="$1"
    [[ -z "$json_path" || ! -f "$json_path" ]] && return 1

    if command -v jq >/dev/null 2>&1; then
        jq -r '
.executables | to_entries[] |
.key as $bin | .value as $v |
if $v.alias then "A\t\($bin)\t\($v.alias)"
else
  [$v.functions | .. | .contexts? | select(type=="object") | keys[] | select(. == "sudo" or . == "suid" or . == "capabilities")] | unique[] | "C\t\($bin)\t\(.)"
end
' < "$json_path" 2>/dev/null
        return
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json,sys
def ctx_in_obj(obj, ctx):
    if isinstance(obj, dict):
        if 'contexts' in obj and ctx in obj['contexts']:
            return True
        for v in obj.values():
            if ctx_in_obj(v, ctx): return True
    elif isinstance(obj, list):
        for x in obj:
            if ctx_in_obj(x, ctx): return True
    return False
d=json.load(open(sys.argv[1]))
for bin_name, v in d.get('executables',{}).items():
    if isinstance(v,dict) and v.get('alias'):
        print('A\t'+bin_name+'\t'+v['alias'])
    elif isinstance(v,dict) and 'functions' in v:
        for ctx in ('sudo','suid','capabilities'):
            if ctx_in_obj(v['functions'], ctx):
                print('C\t'+bin_name+'\t'+ctx)
" "$json_path" 2>/dev/null
        return $?
    fi

    return 1
}

# Consultar si un binario tiene contexto en GTFOBins
check_binary_context() {
    local flat_file="$1"
    local binary="$2"
    local context="$3"

    [[ -z "$flat_file" || ! -f "$flat_file" || -z "$binary" || -z "$context" ]] && return 1

    binary=$(echo "$binary" | tr '[:upper:]' '[:lower:]')

    $awk_cmd -v bin="$binary" -v ctx="$context" '
        $1=="A" && $2==bin { alias_to=$3 }
        $1=="C" { key=$2"\t"$3; contexts[key]=1 }
        END {
            resolved = (alias_to != "") ? alias_to : bin
            k = resolved"\t"ctx
            if (k in contexts) exit 0
            exit 1
        }
    ' "$flat_file" 2>/dev/null
}

# Detección de herramientas
setup_tools() {
    if [[ "$1" == "update" ]]; then
        if command -v curl >/dev/null 2>&1; then
            downloader="curl"
        elif command -v wget >/dev/null 2>&1; then
            downloader="wget"
        elif command -v busybox >/dev/null 2>&1; then
            if busybox wget --help >/dev/null 2>&1; then
                downloader="busybox_wget"
            elif busybox curl --help >/dev/null 2>&1; then
                downloader="busybox_curl"
            else
                echo_red "Error: Busybox sin wget/curl. Se necesita para la actualización (-u)."
                exit 1
            fi
        else
            echo_red "Error: Se necesita curl, wget o busybox para la actualización (-u)."
            exit 1
        fi
        if command -v sed >/dev/null 2>&1; then
            sed_cmd="sed"
        elif command -v busybox >/dev/null 2>&1 && busybox sed --help >/dev/null 2>&1; then
            sed_cmd="busybox sed"
        else
            echo_red "Error: Se necesita sed o busybox sed para la actualización (-u)."
            exit 1
        fi
        return
    fi

    if command -v sed >/dev/null 2>&1; then
        sed_cmd="sed"
    elif command -v busybox >/dev/null 2>&1 && busybox sed --help >/dev/null 2>&1; then
        sed_cmd="busybox sed"
    else
        echo_red "Error: Se necesita sed o busybox sed."
        exit 1
    fi

    if command -v awk >/dev/null 2>&1; then
        awk_cmd="awk"
    elif command -v busybox >/dev/null 2>&1 && busybox awk --help >/dev/null 2>&1; then
        awk_cmd="busybox awk"
    else
        echo_red "Error: Se necesita awk o busybox awk."
        exit 1
    fi

    if [[ ",$1," == *",sudo,"* ]]; then
        if command -v grep >/dev/null 2>&1; then
            grep_cmd="grep"
        elif command -v busybox >/dev/null 2>&1 && busybox grep --help >/dev/null 2>&1; then
            grep_cmd="busybox grep"
        else
            echo_red "Error: Se necesita grep o busybox grep para el escaneo sudo."
            exit 1
        fi
    fi

    if [[ ",$1," == *",capabilities,"* ]]; then
        getcap_cmd=""
        if command -v getcap >/dev/null 2>&1; then
            getcap_cmd="getcap"
        elif [[ -x /usr/sbin/getcap ]]; then
            getcap_cmd="/usr/sbin/getcap"
        elif [[ -x /sbin/getcap ]]; then
            getcap_cmd="/sbin/getcap"
        fi
    fi

    if [[ ",$1," == *",suid,"* ]]; then
        if command -v find >/dev/null 2>&1; then
            find_cmd="find"
        elif command -v busybox >/dev/null 2>&1 && busybox find --help >/dev/null 2>&1; then
            find_cmd="busybox find"
        else
            echo_red "Error: Se necesita find o busybox find para el escaneo suid."
            exit 1
        fi
    fi
}

download_url() {
    local url="$1"
    local dest="$2"
    if [[ "$downloader" == "curl" ]]; then
        curl -sfL -o "$dest" "$url"
    elif [[ "$downloader" == "wget" ]]; then
        wget -q -O "$dest" "$url"
    elif [[ "$downloader" == "busybox_curl" ]]; then
        busybox curl -sfL -o "$dest" "$url"
    elif [[ "$downloader" == "busybox_wget" ]]; then
        busybox wget -q -O "$dest" "$url"
    fi
}

# Actualizar datos - texto plano directo
update_embedded_data() {
    echo_yellow "Descargando api.json de GTFOBins..."
    local tmp_json=$(mktemp)
    if ! download_url "https://gtfobins.org/api.json" "$tmp_json"; then
        echo_red "Error: No se pudo descargar api.json"
        rm -f "$tmp_json"
        exit 1
    fi

    if ! json_to_flat "$tmp_json" >/dev/null 2>&1; then
        echo_red "Error: Se necesita jq o Python para la actualización."
        rm -f "$tmp_json"
        exit 1
    fi

    local tmp_flat=$(mktemp)
    json_to_flat "$tmp_json" > "$tmp_flat"
    rm -f "$tmp_json"

    local tmp_script=$(mktemp)
    local update_date=$(date +%Y-%m-%d)
    {
        $sed_cmd -n "1,/^: <<'__GTFOBINS_END__'\$/p" "$SCRIPT_PATH" | $sed_cmd '$d' | grep -v '^# GTFOBins actualizado:'
        echo "# GTFOBins actualizado: $update_date"
        echo ": <<'__GTFOBINS_END__'"
        cat "$tmp_flat"
        $sed_cmd -n "/^__GTFOBINS_END__\$/,\$p" "$SCRIPT_PATH"
    } > "$tmp_script"
    rm -f "$tmp_flat"

    mv "$tmp_script" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo_green "Datos GTFOBins actualizados correctamente."
}

show_help() {
    echo "Uso: $0 [-v] [-h] [-t=tipo1,tipo2,...] [-u]"
    echo ""
    echo "Opciones:"
    echo "  -v    Modo verbose."
    echo "  -h    Muestra esta ayuda."
    echo "  -t    Tipos: sudo, suid, capabilities (por defecto: todos)"
    echo "  -u    Actualiza los datos GTFOBins embebidos desde gtfobins.org/api.json"
    echo ""
    echo "Los datos de GTFOBins están embebidos para uso offline."
    exit 0
}

evaluate_file() {
    local file=$1
    local type=$2
    local binary_name=$(basename "$file")

    [[ "$type" == "suid" && " $suid_files " == *" $binary_name "* ]] && return 1
    [[ "$type" == "capabilities" && " $capabilities_files " == *" $binary_name "* ]] && return 1

    [[ $verbose -eq 1 ]] && echo "** Evaluando: $binary_name"

    check_binary_context "$flat_file" "$binary_name" "$type"
}

scan_files() {
    local type=$1
    local find_command=$2
    local find_desc=$3
    local action="${4:-Escaneando}"

    echo_purple "\nArchivos con ${find_desc}:"
    printf "${action}..."
    declare -a files
    mapfile -t files < <($find_command 2>/dev/null)
    echo

    for file in "${files[@]}"; do
        if evaluate_file "$file" "$type"; then
            echo_red "$file"
            echo "$baseurl$(basename "$file")/#$type"
        else
            [[ $verbose -eq 1 ]] && echo_green "$file"
        fi
    done
}

check_sudo() {
    echo_purple "\nArchivos con sudo:"
    printf "Comprobando..."
    local sudo_out
    sudo_out=$(sudo -l 2>/dev/null)
    echo

    if echo "$sudo_out" | $grep_cmd -qE '\([^)]+\)[[:space:]]*(NOPASSWD:[[:space:]]+)?ALL[[:space:]]*$'; then
        if echo "$sudo_out" | $grep_cmd -qE '\([^)]+\)[[:space:]]*NOPASSWD:[[:space:]]+ALL[[:space:]]*$'; then
            echo_yellow "¡Atención! El usuario puede ejecutar CUALQUIER comando con sudo (ALL, sin contraseña)."
        else
            echo_yellow "¡Atención! El usuario puede ejecutar CUALQUIER comando con sudo (ALL, con contraseña)."
        fi
    fi

    local file nopasswd
    while IFS=$'\t' read -r file nopasswd; do
        [[ -z "$file" ]] && continue
        if evaluate_file "$file" "sudo"; then
            if [[ "$nopasswd" == "nopasswd" ]]; then
                echo_red "$file (sin contraseña)"
            else
                echo_red "$file (con contraseña)"
            fi
            echo "$baseurl$(basename "$file")/#sudo"
        else
            [[ $verbose -eq 1 ]] && echo_green "$file"
        fi
    done < <(echo "$sudo_out" | $awk_cmd '
        /may run the following|allowed to run|Comandos que/ { in_cmds=1; next }
        in_cmds && /^[[:space:]]*\(/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            nopass = ($0 ~ /NOPASSWD/) ? "nopasswd" : "passwd"
            for (i=1; i<=NF; i++) if ($i ~ /^\/[^ ]+$/) { print $i"\t"nopass; break }
        }
    ')
}

while getopts "vht:u" opt; do
    case $opt in
        v) verbose=1 ;;
        h) show_help ;;
        t) scan_types="${OPTARG}" ;;
        u)
            setup_tools "update"
            update_embedded_data
            exit 0
            ;;
        \?) show_help ;;
    esac
done

[[ "$scan_types" == *=* ]] && scan_types="${scan_types#*=}"
IFS=',' read -r -a types <<< "$scan_types"
setup_tools "$scan_types"

flat_file=$(mktemp)
extract_embedded_data > "$flat_file" 2>/dev/null
if [[ ! -s "$flat_file" ]]; then
    rm -f "$flat_file"
    echo_red "Error: No hay datos GTFOBins. Ejecute: $0 -u"
    exit 1
fi

for type in "${types[@]}"; do
    case $type in
        sudo)
            check_sudo
            ;;
        capabilities)
            if [[ -n "$getcap_cmd" ]]; then
                scan_files "capabilities" "getcap_paths" "capabilities" "Escaneando"
            else
                echo_yellow "getcap no encontrado, omitiendo escaneo de capabilities."
            fi
            ;;
        suid)
            scan_files "suid" "$find_cmd / -perm -4000" "SUID" "Escaneando"
            ;;
        *)
            echo_red "Tipo desconocido: $type"
            ;;
    esac
done

# GTFOBins actualizado: 2026-02-12
: <<'__GTFOBINS_END__'
C	7z	sudo
C	R	sudo
C	R	suid
C	aa-exec	sudo
C	aa-exec	suid
C	ab	sudo
C	ab	suid
C	acr	sudo
C	acr	suid
C	agetty	suid
C	alpine	sudo
C	alpine	suid
C	ansible-playbook	sudo
C	ansible-test	sudo
C	aoss	sudo
C	apache2	sudo
C	apache2	suid
C	apache2ctl	sudo
A	apt	apt-get
C	apt-get	sudo
C	apt-get	suid
C	aptitude	sudo
C	ar	sudo
C	ar	suid
C	aria2c	sudo
C	aria2c	suid
C	arj	sudo
C	arj	suid
C	arp	sudo
C	arp	suid
C	as	sudo
C	as	suid
C	ascii-xfr	sudo
C	ascii-xfr	suid
C	ascii85	sudo
C	ash	sudo
C	ash	suid
C	aspell	sudo
C	aspell	suid
C	asterisk	sudo
C	asterisk	suid
C	at	sudo
C	atobm	sudo
C	atobm	suid
A	awk	mawk
C	aws	sudo
C	aws	suid
C	base32	sudo
C	base32	suid
C	base58	sudo
C	base64	sudo
C	base64	suid
C	basenc	sudo
C	basenc	suid
C	basez	sudo
C	basez	suid
C	bash	sudo
C	bash	suid
C	bashbug	sudo
C	batcat	sudo
C	batcat	suid
C	bc	sudo
C	bc	suid
C	bconsole	sudo
C	bconsole	suid
C	bee	sudo
C	bee	suid
C	borg	sudo
C	bpftrace	sudo
C	bridge	sudo
C	bridge	suid
C	bundle	sudo
A	bundler	bundle
C	busctl	sudo
C	busctl	suid
C	busybox	sudo
C	byebug	sudo
C	bzip2	sudo
C	bzip2	suid
A	c89	gcc
A	c99	gcc
C	cabal	sudo
C	cabal	suid
C	cancel	sudo
C	cancel	suid
C	capsh	sudo
C	capsh	suid
C	cargo	sudo
C	cat	sudo
C	cat	suid
A	cc	gcc
C	cdist	sudo
C	certbot	sudo
C	chattr	sudo
C	chattr	suid
C	check_by_ssh	sudo
C	check_cups	sudo
C	check_log	sudo
C	check_memory	sudo
C	check_raid	sudo
C	check_ssl_cert	sudo
C	check_statusfile	sudo
C	chmod	sudo
C	chmod	suid
C	choom	sudo
C	choom	suid
C	chown	sudo
C	chown	suid
C	chroot	sudo
C	chroot	suid
C	chrt	sudo
C	chrt	suid
C	clamscan	sudo
C	clamscan	suid
C	clisp	sudo
C	clisp	suid
C	cmake	sudo
C	cmp	sudo
C	cmp	suid
C	cobc	sudo
C	cobc	suid
C	code	sudo
C	column	sudo
C	column	suid
C	comm	sudo
C	comm	suid
C	composer	sudo
C	cowsay	sudo
C	cowthink	sudo
C	cp	sudo
C	cp	suid
C	cpan	sudo
C	cpio	sudo
C	cpio	suid
C	cpulimit	sudo
C	cpulimit	suid
C	crash	sudo
C	crash	suid
C	crontab	sudo
C	csh	sudo
C	csh	suid
C	csplit	sudo
C	csplit	suid
C	csvtool	sudo
C	csvtool	suid
C	ctr	sudo
C	ctr	suid
C	cupsfilter	sudo
C	cupsfilter	suid
C	curl	sudo
C	curl	suid
C	cut	sudo
C	cut	suid
C	dash	sudo
C	dash	suid
C	date	sudo
C	date	suid
C	dc	sudo
C	dc	suid
C	dd	sudo
C	dd	suid
C	debugfs	sudo
C	debugfs	suid
C	dhclient	sudo
C	dialog	sudo
C	dialog	suid
C	diff	sudo
C	diff	suid
C	dig	sudo
C	dig	suid
C	distcc	sudo
C	distcc	suid
C	dmesg	sudo
C	dmesg	suid
C	dmsetup	sudo
C	dmsetup	suid
C	dnf	sudo
C	dnsmasq	sudo
C	dnsmasq	suid
C	doas	sudo
C	docker	sudo
C	docker	suid
C	dos2unix	sudo
C	dos2unix	suid
C	dosbox	sudo
C	dosbox	suid
C	dotnet	sudo
C	dpkg	sudo
C	dpkg	suid
C	dstat	sudo
C	dvips	sudo
C	dvips	suid
C	easy_install	sudo
C	easyrsa	sudo
C	easyrsa	suid
C	eb	sudo
C	ed	sudo
C	ed	suid
C	efax	sudo
C	efax	suid
C	egrep	sudo
C	egrep	suid
C	elvish	sudo
C	elvish	suid
C	emacs	sudo
C	enscript	sudo
C	enscript	suid
C	env	sudo
C	env	suid
C	eqn	sudo
C	eqn	suid
C	espeak	sudo
C	espeak	suid
C	ex	sudo
C	ex	suid
C	exiftool	sudo
C	expand	sudo
C	expand	suid
C	expect	sudo
C	expect	suid
C	facter	sudo
C	fail2ban-client	sudo
C	ffmpeg	sudo
C	ffmpeg	suid
C	fgrep	sudo
C	fgrep	suid
C	file	sudo
C	file	suid
C	find	sudo
C	find	suid
C	finger	sudo
C	finger	suid
C	firejail	sudo
C	fish	sudo
C	fish	suid
C	flock	sudo
C	flock	suid
C	fmt	sudo
C	fmt	suid
C	fold	sudo
C	fold	suid
C	forge	sudo
C	forge	suid
C	fping	sudo
C	fping	suid
C	ftp	sudo
C	ftp	suid
C	fzf	sudo
C	fzf	suid
A	g++	gcc
C	gawk	sudo
C	gawk	suid
C	gcc	sudo
C	gcloud	sudo
C	gcloud	suid
C	gcore	sudo
C	gcore	suid
C	gdb	capabilities
C	gdb	sudo
C	gdb	suid
C	gem	sudo
C	genie	sudo
C	genie	suid
C	genisoimage	sudo
C	genisoimage	suid
C	getent	sudo
C	getent	suid
C	ghc	sudo
C	ghci	sudo
C	gimp	sudo
C	ginsh	sudo
C	ginsh	suid
C	git	sudo
C	git	suid
C	gnuplot	sudo
C	gnuplot	suid
C	go	sudo
C	grc	sudo
C	grep	sudo
C	grep	suid
C	gtester	sudo
C	gtester	suid
C	guile	sudo
C	guile	suid
C	gzip	capabilities
C	gzip	sudo
C	gzip	suid
C	hashcat	sudo
A	hd	hexdump
C	head	sudo
C	head	suid
C	hexdump	sudo
C	hexdump	suid
C	hg	sudo
C	hg	suid
C	highlight	sudo
C	highlight	suid
C	hping3	sudo
C	hping3	suid
C	iconv	sudo
C	iconv	suid
C	iftop	sudo
C	iftop	suid
C	install	sudo
C	install	suid
C	ionice	sudo
C	ionice	suid
C	ip	sudo
C	ip	suid
C	iptables-save	sudo
C	irb	sudo
C	ispell	sudo
C	ispell	suid
C	java	sudo
C	jjs	sudo
C	joe	sudo
C	joe	suid
C	join	sudo
C	join	suid
C	journalctl	sudo
C	jq	sudo
C	jq	suid
C	jrunscript	sudo
C	jrunscript	suid
C	jshell	sudo
C	jtag	sudo
C	julia	sudo
C	julia	suid
C	knife	sudo
A	ksh	bash
C	ksshell	sudo
C	ksshell	suid
C	ksu	sudo
C	kubectl	sudo
C	kubectl	suid
C	last	sudo
C	last	suid
A	lastb	last
C	latex	sudo
C	latex	suid
C	latexmk	sudo
C	ld.so	sudo
C	ld.so	suid
C	ldconfig	sudo
C	ldconfig	suid
C	less	sudo
C	less	suid
C	lftp	sudo
C	lftp	suid
C	links	sudo
C	links	suid
C	ln	sudo
C	loginctl	sudo
C	logrotate	sudo
C	logrotate	suid
C	logsave	sudo
C	logsave	suid
C	look	sudo
C	look	suid
C	lp	sudo
C	lp	suid
C	ltrace	sudo
C	ltrace	suid
C	lua	sudo
C	lua	suid
C	lualatex	sudo
C	lualatex	suid
C	luatex	sudo
C	luatex	suid
C	lwp-download	sudo
C	lwp-request	sudo
C	lxd	sudo
C	lxd	suid
C	m4	sudo
C	m4	suid
C	mail	sudo
C	mail	suid
C	make	sudo
C	make	suid
C	man	sudo
C	man	suid
C	mawk	sudo
C	mawk	suid
C	minicom	sudo
C	minicom	suid
C	more	sudo
C	more	suid
C	mosh-server	sudo
C	mosquitto	sudo
C	mosquitto	suid
C	mount	sudo
C	msfconsole	sudo
C	msgattrib	sudo
C	msgattrib	suid
C	msgcat	sudo
C	msgcat	suid
C	msgconv	sudo
C	msgconv	suid
C	msgfilter	sudo
C	msgfilter	suid
C	msgmerge	sudo
C	msgmerge	suid
C	msguniq	sudo
C	msguniq	suid
C	mtr	sudo
C	multitime	sudo
C	multitime	suid
C	mutt	sudo
C	mv	sudo
C	mv	suid
C	mypy	sudo
C	mysql	sudo
C	mysql	suid
C	nano	sudo
C	nano	suid
C	nasm	sudo
C	nasm	suid
A	nawk	gawk
C	nc	sudo
C	nc	suid
C	ncdu	sudo
C	ncdu	suid
C	ncftp	sudo
C	ncftp	suid
C	neofetch	sudo
C	nft	sudo
C	nginx	sudo
C	nginx	suid
C	nice	sudo
C	nice	suid
C	nl	sudo
C	nl	suid
C	nm	sudo
C	nm	suid
C	nmap	sudo
C	nmap	suid
C	node	capabilities
C	node	sudo
C	node	suid
C	nohup	sudo
C	nohup	suid
C	npm	sudo
C	nroff	sudo
C	nsenter	sudo
C	nsenter	suid
C	ntpdate	sudo
C	ntpdate	suid
A	nvim	vim
C	octave	sudo
C	octave	suid
C	od	sudo
C	od	suid
C	openssl	sudo
C	openssl	suid
C	openvpn	sudo
C	openvpn	suid
C	openvt	sudo
C	opkg	sudo
C	pandoc	sudo
C	pandoc	suid
C	passwd	sudo
C	paste	sudo
C	paste	suid
C	pax	sudo
C	pax	suid
C	pdb	sudo
C	pdflatex	sudo
C	pdflatex	suid
C	pdftex	sudo
C	pdftex	suid
C	perf	sudo
C	perf	suid
C	perl	capabilities
C	perl	sudo
C	perl	suid
C	perlbug	sudo
C	pexec	sudo
C	pexec	suid
C	pg	sudo
C	pg	suid
C	php	capabilities
C	php	sudo
C	php	suid
C	pic	sudo
C	pic	suid
A	pico	nano
C	pidstat	sudo
C	pidstat	suid
C	pip	sudo
C	pipx	sudo
C	pkexec	sudo
C	pkg	sudo
C	plymouth	sudo
C	plymouth	suid
C	podman	sudo
C	poetry	sudo
C	posh	sudo
C	pr	sudo
C	pr	suid
C	procmail	sudo
C	pry	sudo
C	psftp	sudo
C	psftp	suid
C	psql	sudo
C	psql	suid
C	ptx	sudo
C	ptx	suid
C	puppet	sudo
C	pwsh	sudo
C	pygmentize	sudo
C	pyright	sudo
C	python	capabilities
C	python	sudo
C	python	suid
C	qpdf	sudo
C	qpdf	suid
C	rake	sudo
C	ranger	sudo
C	rc	sudo
C	rc	suid
C	readelf	sudo
C	readelf	suid
A	red	ed
C	redcarpet	sudo
C	redis	sudo
C	redis	suid
C	restic	sudo
C	restic	suid
C	rev	sudo
C	rev	suid
C	rlogin	sudo
C	rlogin	suid
C	rlwrap	sudo
C	rlwrap	suid
C	rpm	sudo
C	rpm	suid
C	rpmdb	sudo
C	rpmdb	suid
C	rpmquery	sudo
C	rpmquery	suid
C	rpmverify	sudo
C	rpmverify	suid
C	rsync	sudo
C	rsync	suid
C	rsyslogd	sudo
C	rtorrent	sudo
C	rtorrent	suid
C	ruby	capabilities
C	ruby	sudo
C	run-mailcap	sudo
C	run-parts	sudo
C	run-parts	suid
C	runscript	sudo
C	runscript	suid
C	rustc	sudo
C	rustdoc	sudo
C	rustfmt	sudo
C	rustup	sudo
A	rview	view
A	rvim	vim
C	sash	sudo
C	sash	suid
C	scanmem	sudo
C	scanmem	suid
C	scp	sudo
C	scp	suid
C	screen	sudo
C	script	sudo
C	script	suid
C	scrot	sudo
C	scrot	suid
C	sed	sudo
C	sed	suid
C	service	sudo
C	setarch	sudo
C	setarch	suid
C	setcap	sudo
C	setcap	suid
C	setfacl	sudo
C	setfacl	suid
C	setlock	sudo
C	setlock	suid
C	sftp	sudo
C	sftp	suid
C	sg	sudo
C	shred	sudo
C	shred	suid
C	shuf	sudo
C	shuf	suid
C	slsh	sudo
C	slsh	suid
C	smbclient	sudo
C	snap	sudo
C	socat	sudo
C	socat	suid
C	socket	sudo
C	socket	suid
C	soelim	sudo
C	soelim	suid
C	softlimit	sudo
C	softlimit	suid
C	sort	sudo
C	sort	suid
C	split	sudo
C	split	suid
C	sqlite3	sudo
C	sqlite3	suid
C	sqlmap	sudo
C	ss	sudo
C	ss	suid
C	ssh	sudo
C	ssh	suid
C	ssh-agent	sudo
C	ssh-agent	suid
C	ssh-copy-id	sudo
C	ssh-keygen	sudo
C	ssh-keygen	suid
C	ssh-keyscan	sudo
C	ssh-keyscan	suid
C	sshfs	sudo
C	sshpass	sudo
C	sshpass	suid
C	sshuttle	sudo
C	start-stop-daemon	sudo
C	start-stop-daemon	suid
C	stdbuf	sudo
C	stdbuf	suid
C	strace	sudo
C	strace	suid
C	strings	sudo
C	strings	suid
C	su	sudo
C	sudo	sudo
C	sysctl	sudo
C	sysctl	suid
C	systemctl	sudo
C	systemctl	suid
C	systemd-resolve	sudo
C	systemd-run	sudo
C	tac	sudo
C	tac	suid
C	tail	sudo
C	tail	suid
C	tailscale	sudo
C	tar	sudo
C	tar	suid
C	task	sudo
C	task	suid
C	taskset	sudo
C	tasksh	sudo
C	tasksh	suid
C	tbl	sudo
C	tbl	suid
C	tclsh	capabilities
C	tclsh	sudo
C	tclsh	suid
C	tcpdump	sudo
C	tcpdump	suid
C	tcsh	sudo
C	tcsh	suid
C	tdbtool	sudo
C	tdbtool	suid
C	tee	sudo
C	tee	suid
C	telnet	sudo
C	telnet	suid
C	terraform	sudo
C	terraform	suid
C	tex	sudo
C	tex	suid
C	tftp	sudo
C	tftp	suid
C	tic	sudo
C	tic	suid
C	time	sudo
C	time	suid
C	timedatectl	sudo
C	timeout	sudo
C	timeout	suid
C	tmate	sudo
C	tmate	suid
C	tmux	sudo
C	tmux	suid
C	top	sudo
C	torify	sudo
C	torsocks	sudo
C	troff	sudo
C	troff	suid
C	tsc	sudo
C	tshark	sudo
C	ul	sudo
C	ul	suid
C	unexpand	sudo
C	unexpand	suid
C	uniq	sudo
C	uniq	suid
C	unshare	sudo
C	unshare	suid
C	unsquashfs	sudo
C	unsquashfs	suid
C	unzip	sudo
C	unzip	suid
C	update-alternatives	sudo
C	update-alternatives	suid
C	urlget	sudo
C	urlget	suid
C	uuencode	sudo
C	uuencode	suid
C	uv	sudo
C	vagrant	sudo
C	valgrind	sudo
C	varnishncsa	sudo
C	varnishncsa	suid
C	vi	sudo
C	vi	suid
A	view	vim
C	vigr	sudo
C	vigr	suid
C	vim	sudo
C	vim	suid
A	vimdiff	vim
C	vipw	sudo
C	vipw	suid
C	virsh	sudo
C	volatility	sudo
C	volatility	suid
C	w3m	sudo
C	w3m	suid
C	wall	sudo
C	watch	sudo
C	watch	suid
C	wc	sudo
C	wc	suid
C	wg-quick	sudo
C	wget	sudo
C	wget	suid
C	whiptail	sudo
C	whiptail	suid
C	whois	sudo
C	whois	suid
C	wireshark	sudo
C	wish	sudo
C	wish	suid
C	xargs	sudo
C	xargs	suid
C	xdg-user-dir	sudo
C	xdotool	sudo
C	xdotool	suid
A	xelatex	latex
A	xetex	tex
C	xmodmap	sudo
C	xmodmap	suid
C	xmore	sudo
C	xmore	suid
C	xpad	sudo
C	xpad	suid
C	xxd	sudo
C	xxd	suid
C	xz	sudo
C	xz	suid
C	yarn	sudo
C	yash	sudo
C	yash	suid
C	yelp	sudo
C	yt-dlp	sudo
C	yum	sudo
C	zathura	sudo
C	zcat	sudo
C	zgrep	sudo
C	zic	sudo
C	zic	suid
C	zip	sudo
C	zip	suid
C	zless	sudo
C	zless	suid
C	zsh	sudo
C	zsh	suid
C	zsoelim	sudo
C	zsoelim	suid
C	zypper	sudo
__GTFOBINS_END__
