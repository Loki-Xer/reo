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

# -----------------------------
# TITLES
# -----------------------------
while IFS= read -r line; do
    titles+=("$line")
done < <(
    echo "$RESPONSE" |
    grep -o '"title":"[^"]*"' |
    sed 's/"title":"//;s/"//g'
)

# -----------------------------
# URLS
# -----------------------------
while IFS= read -r line; do
    urls+=("$line")
done < <(
    echo "$RESPONSE" |
    grep -o '"url":"[^"]*"' |
    sed 's/"url":"//;s/"//g'
)

# -----------------------------
# DURATIONS
# -----------------------------
while IFS= read -r line; do
    durations+=("$line")
done < <(
    echo "$RESPONSE" |
    grep -o '"duration":"[^"]*"' |
    sed 's/"duration":"//;s/"//g'
)

# -----------------------------
# AUTHORS
# -----------------------------
while IFS= read -r line; do
    authors+=("$line")
done < <(
    echo "$RESPONSE" |
    grep -o '"author":"[^"]*"' |
    sed 's/"author":"//;s/"//g'
)

# -----------------------------
# VIEWS
# -----------------------------
while IFS= read -r line; do
    views+=("$line")
done < <(
    echo "$RESPONSE" |
    grep -o '"views":"[^"]*"' |
    sed 's/"views":"//;s/"//g'
)

# -----------------------------
# SAFETY
# -----------------------------
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

    # Calculate how many results fit on screen
    # Header = 9 lines (logo 6 + blank + search + blank)
    # Footer = 3 lines (divider + hint + spare)
    # Each item = 3 lines (title + author + duration + blank)
    local term_lines
    term_lines=$(tput lines)
    local header_lines=9
    local footer_lines=3
    local item_lines=3
    local visible=$(( (term_lines - header_lines - footer_lines) / item_lines ))
    [[ $visible -lt 1 ]] && visible=1

    local total=${#titles[@]}

    # Compute scroll offset so selected is always in view
    local half=$(( visible / 2 ))
    local offset=$(( selected - half ))
    [[ $offset -lt 0 ]] && offset=0
    [[ $(( offset + visible )) -gt $total ]] && offset=$(( total - visible ))
    [[ $offset -lt 0 ]] && offset=0

    local end=$(( offset + visible ))
    [[ $end -gt $total ]] && end=$total

    # Show scroll indicator if not at top
    if [[ $offset -gt 0 ]]; then
        echo -e "   \033[0;90m↑ $offset more above\033[0m"
    fi

    for (( i=offset; i<end; i++ )); do
        if [[ $i -eq $selected ]]; then
            echo -e "\033[1;32m▶ ${titles[$i]}\033[0m"
            echo -e "   \033[0;90m👤 ${authors[$i]}\033[0m"
            echo -e "   \033[0;90m⏱ ${durations[$i]}   👁 ${views[$i]}\033[0m"
            echo ""
        else
            echo -e "\033[0;37m  ${titles[$i]}\033[0m"
            echo -e "   \033[0;90m${authors[$i]} • ${durations[$i]}\033[0m"
            echo ""
        fi
    done

    # Show scroll indicator if not at bottom
    local remaining=$(( total - end ))
    if [[ $remaining -gt 0 ]]; then
        echo -e "   \033[0;90m↓ $remaining more below\033[0m"
    fi

    echo -e "\033[0;90m─────────────────────────────────────\033[0m"
    echo -e "\033[0;90m↑ ↓ navigate • ENTER play • q quit   [$(( selected + 1 ))/$total]\033[0m"
}

# Hide cursor for cleaner UI
tput civis
trap 'tput cnorm; tput rmcup; exit' INT TERM EXIT

# Use alternate screen buffer
tput smcup
clear

while true; do

    draw_menu

    # Read key input properly
    IFS= read -rsn1 key

    # Handle escape sequences (arrow keys)
    if [[ $key == $'\x1b' ]]; then
        IFS= read -rsn1 -t 0.1 key2
        if [[ $key2 == '[' ]]; then
            IFS= read -rsn1 -t 0.1 key3
            case $key3 in
                'A')  # Up arrow
                    ((selected--))
                    [[ $selected -lt 0 ]] && selected=$((${#titles[@]} - 1))
                    ;;
                'B')  # Down arrow
                    ((selected++))
                    [[ $selected -ge ${#titles[@]} ]] && selected=0
                    ;;
            esac
        fi
        continue
    fi

    # ENTER
    if [[ $key == "" || $key == $'\n' || $key == $'\r' ]]; then
        tput rmcup
        tput cnorm
        echo ""
        echo -e "\033[1;32m▶ Playing:\033[0m ${titles[$selected]}"
        echo ""
        mpv "${urls[$selected]}" 2>/dev/null || xdg-open "${urls[$selected]}" 2>/dev/null || open "${urls[$selected]}" 2>/dev/null
        # Return to menu after playback
        tput smcup
        tput civis
        continue
    fi

    # QUIT
    if [[ $key == "q" || $key == "Q" ]]; then
        break
    fi

done

tput cnorm
tput rmcup
clear