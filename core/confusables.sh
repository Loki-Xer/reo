generate_confusables() {
    local text="$1"

    local -a results=("")
    local -a next
    local -a chars
    local char replacement prefix
    local options

    while IFS= read -r -n1 char; do
        next=()

        case "${char,,}" in
            a) options="a à á â ã ä å ā ă ą ǎ ǟ ǡ а Α α" ;;
            b) options="b ḅ ḇ ƀ Ь ь в В β" ;;
            c) options="c ç ć ĉ ċ č ḉ ƈ с С ϲ" ;;
            d) options="d ď đ ḋ ḍ ḏ ḓ ԁ ԃ" ;;
            e) options="e è é ê ë ē ĕ ė ę ě ẻ ẽ ẹ ế ề ể ễ ệ е Е ε Ε" ;;
            f) options="f ḟ ƒ" ;;
            g) options="g ĝ ğ ġ ģ ǵ ḡ ɡ ԍ ɢ γ" ;;
            h) options="h ĥ ħ ḧ ḩ ḫ ḥ һ Н н" ;;
            i) options="i ì í î ï ĩ ī ĭ į ı ǐ ỉ ị і І ι Ι" ;;
            j) options="j ĵ ǰ ј Ј" ;;
            k) options="k ķ ḱ ḳ ḵ κ К к" ;;
            l) options="l ĺ ļ ľ ł ḷ ḹ ḽ ƚ ⅼ ӏ" ;;
            m) options="m ḿ ṁ ṃ м М ᴍ" ;;
            n) options="n ñ ń ņ ň ŋ ṅ ṇ ṉ ṋ ո п" ;;
            o) options="o ò ó ô õ ö ø ō ŏ ő ǒ ǫ ǭ ȯ ọ о О ο Ο" ;;
            p) options="p ṕ ṗ р Р ρ Ρ" ;;
            q) options="q ɋ" ;;
            r) options="r ŕ ŗ ř ṙ ṛ ṝ ṟ г Г" ;;
            s) options="s ś ŝ ş š ș ṡ ṣ ṥ ṧ ṩ ѕ Ѕ σ ς" ;;
            t) options="t ţ ť ț ŧ ṫ ṭ ṯ ṱ т Т τ Τ" ;;
            u) options="u ù ú û ü ũ ū ŭ ů ű ų ǔ ǖ ǘ ǚ ǜ ụ ủ υ Υ" ;;
            v) options="v ṽ ṿ ν ѵ" ;;
            w) options="w ŵ ẁ ẃ ẅ ẇ ẉ ԝ Ԝ" ;;
            x) options="x ẋ ẍ х Х χ Χ" ;;
            y) options="y ý ÿ ŷ ȳ ẏ ỳ ỵ у У γ Υ" ;;
            z) options="z ź ż ž ẑ ẓ ẕ ѕ Ζ ζ" ;;
            *) options="$char" ;;
        esac

        # Convert replacement string into Unicode characters
        chars=()

        while IFS= read -r -n1 replacement; do
            [[ -n "$replacement" ]] && chars+=("$replacement")
        done <<< "$options"

        # Cartesian product
        for prefix in "${results[@]}"; do
            for replacement in "${chars[@]}"; do
                next+=("${prefix}${replacement}")
            done
        done

        results=("${next[@]}")

    done <<< "$text"

    # Return every possible combination
    printf '%s\n' "${results[@]}"
}
