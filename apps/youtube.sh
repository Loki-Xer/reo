#!/usr/bin/env bash

# name: youtube
# description: YouTube MPV player

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/core/index.sh"

QUERY=$(ask "Search YouTube")
clear

# Decode %20/+ to spaces for display
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

if [[ ${#titles[@]} -eq 0 ]]; then
    echo "❌ No results found"
    exit 1
fi

selected=0

draw_menu() {
    tput cup 0 0
    tput ed

    echo -e "\033[1;31m"
    echo "██╗   ██╗ ██████╗ ██╗   ██╗████████╗██╗   ██╗██████╗ ███████╗"
    echo "╚██╗ ██╔╝██╔═══██╗██║   ██║╚══██╔══╝██║   ██║██╔══██╗██╔════╝"
    echo " ╚████╔╝ ██║   ██║██║   ██║   ██║   ██║   ██║██████╔╝█████╗  "
    echo "  ╚██╔╝  ██║   ██║██║   ██║   ██║   ██║   ██║██╔══██╗██╔══╝  "
    echo "   ██║   ╚██████╔╝╚██████╔╝   ██║   ╚██████╔╝██████╔╝███████╗"
    echo "   ╚═╝    ╚═════╝  ╚═════╝    ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝"
    echo -e "\033[0m"

    echo -e "\033[1;36mSearch:\033[0m $QUERY_DISPLAY"
    echo ""

    local term_lines
    term_lines=$(tput lines)
    local header_lines=9
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

    [[ $offset -gt 0 ]] && echo -e "   \033[0;90m↑ $offset more above\033[0m"

    for (( i=offset; i<end; i++ )); do
        if [[ $i -eq $selected ]]; then
            echo -e "\033[1;32m▶ ${titles[$i]}\033[0m"
            echo -e "   \033[0;90m👤 ${authors[$i]}  ⏱ ${durations[$i]}  👁 ${views[$i]}\033[0m"
            echo ""
        else
            echo -e "\033[0;37m  ${titles[$i]}\033[0m"
            echo -e "   \033[0;90m${authors[$i]} • ${durations[$i]}\033[0m"
            echo ""
        fi
    done

    local remaining=$(( total - end ))
    [[ $remaining -gt 0 ]] && echo -e "   \033[0;90m↓ $remaining more below\033[0m"

    echo -e "\033[0;90m─────────────────────────────────────\033[0m"
    echo -e "\033[0;90m↑ ↓ navigate • ENTER play • q quit   [$(( selected + 1 ))/$total]\033[0m"
}

tput civis
trap 'tput cnorm; tput rmcup; exit' INT TERM EXIT
tput smcup
clear

while true; do

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
        tput rmcup
        tput cnorm
        echo ""
        echo -e "\033[1;32m▶ Playing:\033[0m ${titles[$selected]}"
        echo ""
        mpv --no-terminal "${urls[$selected]}" >/dev/null 2>&1 || xdg-open "${urls[$selected]}" >/dev/null 2>&1 || open "${urls[$selected]}" >/dev/null 2>&1
        tput smcup
        tput civis
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