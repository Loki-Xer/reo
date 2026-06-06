fetch() {
    local METHOD="GET"
    local URL=""
    local DATA=""
    local HEADERS=()
    local RESPONSE=""
    local CURL_EXIT=0

    if [[ $# -eq 1 && ! "$1" =~ ^- ]]; then
        URL="$1"
    else
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -X|--method)
                    METHOD="${2^^}"
                    shift 2
                    ;;
                -U|--url)
                    URL="$2"
                    shift 2
                    ;;
                -H|--header)
                    HEADERS+=("-H" "$2")
                    shift 2
                    ;;
                -D|--data)
                    DATA="$2"
                    shift 2
                    ;;
                *)
                    echo '{"status":false,"message":"Unknown option"}'
                    return 1
                    ;;
            esac
        done
    fi

    # URL check
    if [[ -z "$URL" ]]; then
        echo '{"status":false,"message":"URL is required"}'
        return 1
    fi

    # Request
    if [[ -n "$DATA" ]]; then
        RESPONSE=$(curl -sS \
            --connect-timeout 10 \
            --max-time 30 \
            -X "$METHOD" \
            "${HEADERS[@]}" \
            -H "Content-Type: application/json" \
            -d "$DATA" \
            "$URL" 2>/dev/null)

        CURL_EXIT=$?
    else
        RESPONSE=$(curl -sS \
            --connect-timeout 10 \
            --max-time 30 \
            -X "$METHOD" \
            "${HEADERS[@]}" \
            "$URL" 2>/dev/null)

        CURL_EXIT=$?
    fi

    # Network error
    if [[ $CURL_EXIT -ne 0 ]]; then
        echo '{"status":false,"message":"Network request failed"}'
        return 1
    fi

    # Empty response
    if [[ -z "$RESPONSE" ]]; then
        echo '{"status":false,"message":"Empty response from API"}'
        return 1
    fi

    # HTML error page check
    if echo "$RESPONSE" | grep -qi "<html"; then
        echo '{"status":false,"message":"API returned invalid response"}'
        return 1
    fi

    echo "$RESPONSE"
}