#!/usr/bin/env bash

generate_confusables() {
    local text="$1"
    local limit="${2:-10}"

    [[ -n "$text" ]] || return 0

    if [[ ! "$limit" =~ ^[1-9][0-9]*$ ]]; then
        return 1
    fi

    local -a variants=()
    local -a options=()

    local i
    local char
    local replacement
    local variant

    while IFS= read -r -d '' char; do

        case "$char" in
            a|A)
                options=("a" "à" "á" "â" "ã" "ä" "å" "ā" "ă" "ą" "ǎ" "а" "Α" "α")
                ;;
            b|B)
                options=("b" "ḅ" "ḇ" "ƀ" "Ь" "ь" "в" "В" "β")
                ;;
            c|C)
                options=("c" "ç" "ć" "ĉ" "ċ" "č" "ḉ" "ƈ" "с" "С" "ϲ")
                ;;
            d|D)
                options=("d" "ď" "đ" "ḋ" "ḍ" "ḏ" "ḓ" "ԁ" "ԃ")
                ;;
            e|E)
                options=("e" "è" "é" "ê" "ë" "ē" "ĕ" "ė" "ę" "ě" "ẻ" "ẽ" "ẹ" "е" "Е" "ε" "Ε")
                ;;
            f|F)
                options=("f" "ḟ" "ƒ")
                ;;
            g|G)
                options=("g" "ĝ" "ğ" "ġ" "ģ" "ǵ" "ḡ" "ɡ" "ԍ" "ɢ" "γ")
                ;;
            h|H)
                options=("h" "ĥ" "ħ" "ḧ" "ḩ" "ḫ" "ḥ" "һ" "Н" "н")
                ;;
            i|I)
                options=("i" "ì" "í" "î" "ï" "ĩ" "ī" "ĭ" "į" "ı" "ǐ" "ỉ" "ị" "і" "І" "ι" "Ι")
                ;;
            j|J)
                options=("j" "ĵ" "ǰ" "ј" "Ј")
                ;;
            k|K)
                options=("k" "ķ" "ḱ" "ḳ" "ḵ" "κ" "К" "к")
                ;;
            l|L)
                options=("l" "ĺ" "ļ" "ľ" "ł" "ḷ" "ḹ" "ḽ" "ƚ" "ⅼ" "ӏ")
                ;;
            m|M)
                options=("m" "ḿ" "ṁ" "ṃ" "м" "М" "ᴍ")
                ;;
            n|N)
                options=("n" "ñ" "ń" "ņ" "ň" "ŋ" "ṅ" "ṇ" "ṉ" "ṋ" "ո" "п")
                ;;
            o|O)
                options=("o" "ò" "ó" "ô" "õ" "ö" "ø" "ō" "ŏ" "ő" "ǒ" "ǫ" "ǭ" "ȯ" "ọ" "о" "О" "ο" "Ο")
                ;;
            p|P)
                options=("p" "ṕ" "ṗ" "р" "Р" "ρ" "Ρ")
                ;;
            q|Q)
                options=("q" "ɋ")
                ;;
            r|R)
                options=("r" "ŕ" "ŗ" "ř" "ṙ" "ṛ" "ṝ" "ṟ" "г" "Г")
                ;;
            s|S)
                options=("s" "ś" "ŝ" "ş" "š" "ș" "ṡ" "ṣ" "ṥ" "ṧ" "ṩ" "ѕ" "Ѕ" "σ" "ς")
                ;;
            t|T)
                options=("t" "ţ" "ť" "ț" "ŧ" "ṫ" "ṭ" "ṯ" "ṱ" "т" "Т" "τ" "Τ")
                ;;
            u|U)
                options=("u" "ù" "ú" "û" "ü" "ũ" "ū" "ŭ" "ů" "ű" "ų" "ǔ" "ǖ" "ǘ" "ǚ" "ǜ" "ụ" "ủ" "υ" "Υ")
                ;;
            v|V)
                options=("v" "ṽ" "ṿ" "ν" "ѵ")
                ;;
            w|W)
                options=("w" "ŵ" "ẁ" "ẃ" "ẅ" "ẇ" "ẉ" "ԝ" "Ԝ")
                ;;
            x|X)
                options=("x" "ẋ" "ẍ" "х" "Х" "χ" "Χ")
                ;;
            y|Y)
                options=("y" "ý" "ÿ" "ŷ" "ȳ" "ẏ" "ỳ" "ỵ" "у" "У" "γ" "Υ")
                ;;
            z|Z)
                options=("z" "ź" "ż" "ž" "ẑ" "ẓ" "ẕ" "ѕ" "Ζ" "ζ")
                ;;
            *)
                options=("$char")
                ;;
        esac

        for replacement in "${options[@]}"; do
            if [[ "$replacement" != "$char" ]]; then
                variant="${text:0:i}${replacement}${text:i+1}"
                variants+=("$variant")

                if (( ${#variants[@]} >= limit )); then
                    printf '%s\n' "${variants[@]}"
                    return 0
                fi
            fi
        done

        ((i++))

    done < <(printf '%s' "$text" | grep -oP '.' | while IFS= read -r char; do
        printf '%s\0' "$char"
    done)

    printf '%s\n' "${variants[@]}"
}
