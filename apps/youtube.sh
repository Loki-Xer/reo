#!/usr/bin/env bash

# name: youtube
# description: YouTube MPV player

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/core/index.sh"

# ─────────────────────────────────────
# SEARCH
# ─────────────────────────────────────
do_search() {
    local q="$1"
    QUERY="$q"
    QUERY_DISPLAY="${QUERY//%20/ }"
    QUERY_DISPLAY="${QUERY_DISPLAY//+/ }"

    RESPONSE=$(fetch "https://lokixer.koyeb.app/search/youtube?q=$QUERY")

    titles=()
    urls=()
    durations=()
    authors=()
    views=()

    while IFS= read -r line; do titles+=("$line"); done < <(
        echo "$RESPONSE" | grep -o '"title":"[^"]*"' | sed 's/"title":"//;s/"//g')
    while IFS= read -r line; do urls+=("$line"); done < <(
        echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"//g')
    while IFS= read -r line; do durations+=("$line"); done < <(
        echo "$RESPONSE" | grep -o '"duration":"[^"]*"' | sed 's/"duration":"//;s/"//g')
    while IFS= read -r line; do authors+=("$line"); done < <(
        echo "$RESPONSE" | grep -o '"author":"[^"]*"' | sed 's/"author":"//;s/"//g')
    while IFS= read -r line; do views+=("$line"); done < <(
        echo "$RESPONSE" | grep -o '"views":"[^"]*"' | sed 's/"views":"//;s/"//g')
}

INITIAL_QUERY=$(ask "Search YouTube")
clear

do_search "$INITIAL_QUERY"

if [[ ${#titles[@]} -eq 0 ]]; then
    echo "❌ No results found"
    exit 1
fi

selected=0

# ─────────────────────────────────────
# LOGO
# ─────────────────────────────────────
print_logo() {
    echo -e "\033[1;31m██╗   ██╗ ██████╗ ██╗   ██╗████████╗██╗   ██╗██████╗ ███████╗"
    echo      "╚██╗ ██╔╝██╔═══██╗██║   ██║╚══██╔══╝██║   ██║██╔══██╗██╔════╝"
    echo      " ╚████╔╝ ██║   ██║██║   ██║   ██║   ██║   ██║██████╔╝█████╗  "
    echo      "  ╚██╔╝  ██║   ██║██║   ██║   ██║   ██║   ██║██╔══██╗██╔══╝  "
    echo      "   ██║   ╚██████╔╝╚██████╔╝   ██║   ╚██████╔╝██████╔╝███████╗"
    echo -e   "   ╚═╝    ╚═════╝  ╚═════╝    ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝\033[0m"
}

# ─────────────────────────────────────
# SEARCH MENU
# ─────────────────────────────────────
draw_menu() {
    tput cup 0 0
    tput ed

    print_logo
    echo ""
    echo -e "\033[1;36m  🔍 $QUERY_DISPLAY\033[0m"
    echo ""

    local term_lines
    term_lines=$(tput lines)
    local header_lines=10
    local footer_lines=3
    local item_lines=3
    local visible=$(( (term_lines - header_lines - footer_lines) / item_lines ))
    [[ $visible -lt 1 ]] && visible=1

    local total=${#titles[@]}
    local half=$(( visible / 2 ))
    local offset=$(( selected - half ))
    [[ $offset -lt 0 ]] && offset=0
    [[ $(( offset + visible )) -gt $total ]] && offset=$(( total - visible ))
    [[ $offset -lt 0 ]] && offset=0
    local end=$(( offset + visible ))
    [[ $end -gt $total ]] && end=$total

    [[ $offset -gt 0 ]] && echo -e "  \033[0;90m↑ $offset more above\033[0m"

    for (( i=offset; i<end; i++ )); do
        if [[ $i -eq $selected ]]; then
            echo -e "\033[1;32m  ▶ ${titles[$i]}\033[0m"
            echo -e "    \033[0;90m👤 ${authors[$i]}  ⏱ ${durations[$i]}  👁 ${views[$i]}\033[0m"
            echo ""
        else
            echo -e "\033[0;37m    ${titles[$i]}\033[0m"
            echo -e "    \033[0;90m${authors[$i]} • ${durations[$i]}\033[0m"
            echo ""
        fi
    done

    local remaining=$(( total - end ))
    [[ $remaining -gt 0 ]] && echo -e "  \033[0;90m↓ $remaining more below\033[0m"

    echo -e "\033[0;90m  ──────────────────────────────────────────────────\033[0m"
    echo -e "\033[0;90m  ↑↓ navigate  ENTER play  / new search  q quit   [$(( selected + 1 ))/$total]\033[0m"
}

# ─────────────────────────────────────
# NOW PLAYING SCREEN
# ─────────────────────────────────────
MPV_SOCKET="/tmp/mpv-youtube-$$"
IS_PAUSED=false

mpv_cmd() {
    echo "$1" | socat - "$MPV_SOCKET" 2>/dev/null
}

get_paused() {
    local result
    result=$(echo '{"command":["get_property","pause"]}' | socat - "$MPV_SOCKET" 2>/dev/null)
    if echo "$result" | grep -q '"data":true'; then
        IS_PAUSED=true
    else
        IS_PAUSED=false
    fi
}

draw_player() {
    tput cup 0 0
    tput ed

    print_logo
    echo ""

    # Title (truncate if too wide)
    local term_cols
    term_cols=$(tput cols)
    local title="${titles[$selected]}"
    local max_len=$(( term_cols - 6 ))
    [[ ${#title} -gt $max_len ]] && title="${title:0:$max_len}…"

    echo -e "\033[1;37m  ♪  $title\033[0m"
    echo -e "\033[0;90m     👤 ${authors[$selected]}  ⏱ ${durations[$selected]}\033[0m"
    echo ""

    # Pause/play status
    get_paused
    if $IS_PAUSED; then
        echo -e "  \033[1;33m⏸  PAUSED\033[0m"
    else
        echo -e "  \033[1;32m▶  PLAYING\033[0m"
    fi

    echo ""
    echo -e "\033[0;90m  ──────────────────────────────────────────────────\033[0m"
    echo -e "\033[0;90m  SPACE pause/play  n next  / new search  q back\033[0m"
}

play_screen() {
    # Launch mpv in background with IPC socket, suppress all output
    mpv --no-terminal \
        --input-ipc-server="$MPV_SOCKET" \
        "${urls[$selected]}" \
        >/dev/null 2>&1 &
    MPV_PID=$!

    # Small wait for socket to appear
    local tries=0
    while [[ ! -S "$MPV_SOCKET" && $tries -lt 20 ]]; do
        sleep 0.1
        (( tries++ ))
    done

    # If mpv failed to start (no socket), fall back to browser
    if [[ ! -S "$MPV_SOCKET" ]]; then
        xdg-open "${urls[$selected]}" 2>/dev/null || open "${urls[$selected]}" 2>/dev/null
        return
    fi

    local player_running=true
    while $player_running; do

        draw_player

        # Check if mpv is still running
        if ! kill -0 "$MPV_PID" 2>/dev/null; then
            player_running=false
            break
        fi

        IFS= read -rsn1 -t 1 pkey
        local rc=$?

        # Timeout (no key) — just redraw
        if [[ $rc -ne 0 ]]; then
            continue
        fi

        case "$pkey" in
            " ")  # Space — toggle pause
                mpv_cmd '{"command":["cycle","pause"]}' >/dev/null
                ;;
            "n"|"N")  # Next result
                kill "$MPV_PID" 2>/dev/null
                rm -f "$MPV_SOCKET"
                (( selected++ ))
                [[ $selected -ge ${#titles[@]} ]] && selected=0
                play_screen
                return
                ;;
            "/")  # New search from player
                kill "$MPV_PID" 2>/dev/null
                rm -f "$MPV_SOCKET"
                player_running=false
                NEW_SEARCH=true
                return
                ;;
            "q"|"Q")  # Back to menu
                kill "$MPV_PID" 2>/dev/null
                rm -f "$MPV_SOCKET"
                player_running=false
                return
                ;;
            $'\x1b')  # Escape sequences
                IFS= read -rsn1 -t 0.1 ek2
                IFS= read -rsn1 -t 0.1 ek3
                case "$ek3" in
                    'C')  # Right arrow — seek +10s
                        mpv_cmd '{"command":["seek","10"]}' >/dev/null
                        ;;
                    'D')  # Left arrow — seek -10s
                        mpv_cmd '{"command":["seek","-10"]}' >/dev/null
                        ;;
                esac
                ;;
        esac
    done

    rm -f "$MPV_SOCKET"
}

# ─────────────────────────────────────
# SETUP TERMINAL
# ─────────────────────────────────────
tput civis
trap 'tput cnorm; tput rmcup; kill "$MPV_PID" 2>/dev/null; rm -f "$MPV_SOCKET"; exit' INT TERM EXIT
tput smcup
clear

# ─────────────────────────────────────
# MAIN LOOP
# ─────────────────────────────────────
while true; do

    NEW_SEARCH=false
    draw_menu

    IFS= read -rsn1 key

    if [[ $key == $'\x1b' ]]; then
        IFS= read -rsn1 -t 0.1 key2
        if [[ $key2 == '[' ]]; then
            IFS= read -rsn1 -t 0.1 key3
            case $key3 in
                'A')
                    (( selected-- ))
                    [[ $selected -lt 0 ]] && selected=$(( ${#titles[@]} - 1 ))
                    ;;
                'B')
                    (( selected++ ))
                    [[ $selected -ge ${#titles[@]} ]] && selected=0
                    ;;
            esac
        fi
        continue
    fi

    # ENTER — play
    if [[ $key == "" || $key == $'\n' || $key == $'\r' ]]; then
        play_screen
        if $NEW_SEARCH; then
            tput cnorm
            tput rmcup
            NEW_Q=$(ask "Search YouTube")
            tput smcup
            tput civis
            clear
            do_search "$NEW_Q"
            selected=0
            if [[ ${#titles[@]} -eq 0 ]]; then
                tput rmcup
                tput cnorm
                echo "❌ No results found"
                exit 1
            fi
        fi
        continue
    fi

    # / — new search from menu
    if [[ $key == "/" ]]; then
        tput cnorm
        tput rmcup
        NEW_Q=$(ask "Search YouTube")
        tput smcup
        tput civis
        clear
        do_search "$NEW_Q"
        selected=0
        if [[ ${#titles[@]} -eq 0 ]]; then
            tput rmcup
            tput cnorm
            echo "❌ No results found"
            exit 1
        fi
        continue
    fi

    # Q — quit
    if [[ $key == "q" || $key == "Q" ]]; then
        break
    fi

done

tput cnorm
tput rmcup
clear