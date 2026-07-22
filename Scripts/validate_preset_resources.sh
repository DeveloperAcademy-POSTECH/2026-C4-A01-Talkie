#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h:h}"
resource_root="$repo_root/Talkie/Talkie/Resources/Presets"

validate_speaker() {
    local speaker="$1"
    local expected_count="$2"
    local directory="$resource_root/$speaker"
    local files=("$directory"/*.m4a(N))

    if (( ${#files[@]} != expected_count )); then
        print -u2 "$speaker: expected $expected_count files, found ${#files[@]}"
        return 1
    fi

    local index number file info
    for index in {1..$expected_count}; do
        number=$(printf "%02d" "$index")
        file="$directory/${speaker}_${number}.m4a"

        if [[ ! -f "$file" ]]; then
            print -u2 "$speaker: missing ${speaker}_${number}.m4a"
            return 1
        fi

        info=$(afinfo "$file")
        if ! print -r -- "$info" | grep -q "1 ch,  48000 Hz, aac"; then
            print -u2 "$speaker: invalid audio format in ${speaker}_${number}.m4a"
            return 1
        fi
    done

    print "$speaker: PASS ($expected_count files)"
}

validate_speaker Grace 13
validate_speaker Kaelyn 13
validate_speaker Kevin 24

print "Preset resources: PASS (50 files)"
