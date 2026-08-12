#!/usr/bin/env bash

# name: homograph
# description: Generate Unicode homograph variants

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"


if [[ -f "$ROOT_DIR/core/index.sh" ]]; then
    source "$ROOT_DIR/core/index.sh"
fi

if [[ -f "$ROOT_DIR/core/confusables.sh" ]]; then
    source "$ROOT_DIR/core/confusables.sh"
else
    echo "Error: core/confusables.sh not found."
    exit 1
fi


RESET="\033[0m"
BOLD="\033[1m"

RED="\033[38;5;196m"
GREEN="\033[38;5;82m"
YELLOW="\033[38;5;220m"
CYAN="\033[38;5;51m"
MAGENTA="\033[38;5;213m"
WHITE="\033[97m"
GRAY="\033[38;5;240m"


clear

echo
echo -e "  ${CYAN}${BOLD}╔══════════════════════════════════╗${RESET}"
echo -e "  ${CYAN}${BOLD}║          HOMOGRAPH GEN           ║${RESET}"
echo -e "  ${CYAN}${BOLD}╚══════════════════════════════════╝${RESET}"
echo


read -r -p "  Enter domain/text: " DOMAIN

DOMAIN="${DOMAIN#"${DOMAIN%%[![:space:]]*}"}"
DOMAIN="${DOMAIN%"${DOMAIN##*[![:space:]]}"}"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN#www.}"
DOMAIN="${DOMAIN%/}"


if [[ -z "$DOMAIN" ]]; then
    echo
    echo -e "  ${RED}${BOLD}[!] Input cannot be empty.${RESET}"
    echo
    exit 1
fi


if ! declare -F generate_confusables >/dev/null 2>&1; then
    echo
    echo -e "  ${RED}${BOLD}[!] generate_confusables() not found.${RESET}"
    echo -e "  ${GRAY}Check core/confusables.sh${RESET}"
    echo
    exit 1
fi


HOST="$DOMAIN"
TLD=""
IS_DOMAIN=false


if [[ "$DOMAIN" == *.* ]]; then

    possible_host="${DOMAIN%.*}"
    possible_tld="${DOMAIN##*.}"

    if [[ -n "$possible_host" && -n "$possible_tld" ]]; then


        if [[ "$possible_tld" =~ ^[A-Za-z]+$ ]]; then

            HOST="$possible_host"
            TLD="$possible_tld"
            IS_DOMAIN=true

        fi
    fi
fi


echo

if [[ "$IS_DOMAIN" == true ]]; then

    echo -e "  ${GRAY}Type${RESET}       ${GREEN}Domain${RESET}"
    echo -e "  ${GRAY}Input${RESET}      ${WHITE}${DOMAIN}${RESET}"
    echo -e "  ${GRAY}Host${RESET}       ${WHITE}${HOST}${RESET}"
    echo -e "  ${GRAY}TLD${RESET}        ${WHITE}.${TLD}${RESET}"

else

    echo -e "  ${GRAY}Type${RESET}       ${YELLOW}Text${RESET}"
    echo -e "  ${GRAY}Input${RESET}      ${WHITE}${DOMAIN}${RESET}"
    echo -e "  ${GRAY}Mode${RESET}       ${YELLOW}Direct generation${RESET}"

fi

echo


echo -e "  ${YELLOW}${BOLD}[+] Generating homographs...${RESET}"
echo

results=()

while IFS= read -r variant; do

    [[ -n "$variant" ]] || continue

    if [[ "$IS_DOMAIN" == true ]]; then

        results+=("${variant}.${TLD}")

    else

        results+=("$variant")

    fi

done < <(generate_confusables "$HOST")


if [[ ${#results[@]} -eq 0 ]]; then

    echo
    echo -e "  ${RED}${BOLD}[!] No variants generated.${RESET}"
    echo

    exit 1
fi


COUNT="${#results[@]}"

echo -e "  ${GREEN}${BOLD}[✓] Generated ${COUNT} variants${RESET}"
echo

echo -e "  ${GRAY}────────────────────────────────────────${RESET}"


INDEX=1

for variant in "${results[@]}"; do

    echo -e "  ${GRAY}${INDEX}.${RESET} ${WHITE}${variant}${RESET}"

    ((INDEX++))

done


echo
echo -e "  ${GRAY}────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}${BOLD}[✓] Done${RESET}"
echo
