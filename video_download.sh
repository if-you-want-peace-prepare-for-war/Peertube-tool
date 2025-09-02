#!/usr/bin/env bash

#
# <Program Name>: Video Downloader
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2025. spirillen
# My Privacy DNS: https://www.mypdns.org/
# Author: @spirillen url: https://github.com/spirillen
# License: License: GNU Affero General Public License v3.0 or later
# License: CC BY-NC-SA 4.0 for data files
#
# Requirements:
# - bash
# - curl
# - yt-dlp (auto-installed if missing)
# - ffmpeg (for transcoding)
# - GNU coreutils
#
# Thanks to Framasoft for hosting (see joinpeertube.org).
#

VERSION="1.2.0"

# User-configurable variables (all at top)
UPDATE_URL="https://framagit.org/spirillen/peertube-tool/-/raw/master/video_download.sh"
DEFAULT_FFMPEG_LOCATIONS=("/usr/local/bin/ffmpeg" "/usr/bin/ffmpeg")
DEFAULT_YTDLP_LOCATIONS=("/usr/local/bin/yt-dlp" "/usr/bin/yt-dlp")
SCRUB_YOUTUBE_REGEX="^https?://(www\.)?(youtube\.com|youtu\.be)/"
SUCCESS_PATTERNS=("Merging formats into" "Download successful")
RETRY_PATTERNS=("HTTP Error 403: Forbidden" "Sign in to confirm" \
    "The uploader has not made this video available in your country" "log in to verify age")
STOP_PATTERNS=("log in to verify age")
SUB_LANGS="all,-live_chat"
OUTFILE_FMT="%(playlist_index|)s%(playlist_index&. |)s%(title)s - %(release_date>%Y-%m-%d %H-%M,upload_date>%Y-%m-%d %H-%M|Unknown)s.%(ext)s"
MAX_RETRY_MINS=60
TRAP_CLEANUP_FILES=()

yt_dlp_opts=(
    --write-subs
    "$($yes_playlist && echo --yes-playlist || echo --no-playlist)"
    --no-embed-metadata
    --write-description
    --audio-quality 0
    --sub-format "vtt/srt/best"
    --sub-langs "$SUB_LANGS"
    --concurrent-fragments 4
    --no-cookies
    --no-cookies-from-browser
    --rm-cache-dir
    --write-thumbnail
    --convert-thumbnails webp
    -o "$OUTFILE_FMT"
    -f 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4][protocol!*=dash][protocol^=m3u8] / bv*+ba/b'
    --ffmpeg-location="$ffmpeg"
    --progress
)

# Arguments
urls=()
yt_dlp=""
ffmpeg=""
batch_file=""
yes_playlist=false
update_script=false
show_help=false
show_version=false
ffmpeg_path=""
yt_dlp_args=()

# Argument parsing (up front)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update)
            update_script=true; shift ;;
        -u|--url|--uri)
            urls+=("$2"); shift 2 ;;
        --yes-playlist)
            yes_playlist=true; shift ;;
        -F|--ffmpeg)
            ffmpeg_path="$2"; shift 2 ;;
        -h|--help)
            show_help=true; shift ;;
        -v|--version)
            show_version=true; shift ;;
        -a|-f|--file)
            batch_file="$2"; shift 2 ;;
        --)
            shift
            yt_dlp_args=("$@")
            break
            ;;
        *)
            # If looks like a URL, assume -u; else batch file
            if [[ "$1" =~ ^https?:// ]]; then
                urls+=("$1")
            elif [[ -f "$1" ]]; then
                batch_file="$1"
            else
                printf "Unknown option or file not found: %s\n" "$1"
                show_help=true
            fi
            shift
            ;;
    esac
done

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS] [-- yt-dlp-ARGS]
Options:
  -u, --url, --uri URL    Specify a video URL
  --yes-playlist          Download playlist if URL is playlist
  -a, -f, --file FILE     Batch file for URLs (forwarded to yt-dlp)
  -F, --ffmpeg PATH       Specify ffmpeg path
  --update                Update script from repo
  -h, --help              Show help
  -v, --version           Show version
Any remaining args after '--' are forwarded to yt-dlp.
Script defaults override yt-dlp config unless --config-locations is passed.
EOF
}
show_version_fn() {
    echo "Video Downloader version $VERSION"
}

if $show_help; then show_help; exit 0; fi
if $show_version; then show_version_fn; exit 0; fi

do_update() {
    local script_path="${BASH_SOURCE[0]}"
    local backup_path="${script_path}.bak"
    echo "Checking script update from $UPDATE_URL..."
    local remote_version
    remote_version=$(curl --silent --retry 5 --connect-timeout 2 "$UPDATE_URL" | grep VERSION= | head -1 | sed 's/[^0-9.]//g')
    if [[ "$remote_version" == "$VERSION" ]]; then
        echo "Already up to date (version $VERSION)."
        return 0
    fi
    echo "Updating to version $remote_version ..."
    cp "$script_path" "$backup_path"
    if curl --silent --fail --retry 5 --connect-timeout 2 \
        -o "$script_path.tmp" "$UPDATE_URL"; then
        mv "$script_path.tmp" "$script_path"
        chmod +x "$script_path"
        rm -f "$backup_path"
        echo "Update complete. Restarting script..."
        exec "$script_path" "$@"
    else
        echo "Update failed, backup at $backup_path"
        return 1
    fi
}
if $update_script; then do_update "$@"; exit $?; fi

find_yt_dlp() {
    for loc in "${DEFAULT_YTDLP_LOCATIONS[@]}"; do
        if [ -x "$loc" ]; then
            echo "$loc"
            return
        fi
    done
    if command -v yt-dlp &>/dev/null; then
        command -v yt-dlp
        return
    fi
    echo "yt-dlp not found. Installing locally..."
    curl --silent --fail --location https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$HOME/.local/bin/yt-dlp"
    chmod +x "$HOME/.local/bin/yt-dlp"
    echo "$HOME/.local/bin/yt-dlp"
}
yt_dlp="$(find_yt_dlp)"

find_ffmpeg() {
    if [[ -n "$ffmpeg_path" ]]; then
        echo "$ffmpeg_path"
        return
    fi
    for loc in "${DEFAULT_FFMPEG_LOCATIONS[@]}"; do
        if [ -x "$loc" ]; then
            echo "$loc"
            return
        fi
    done
    if command -v ffmpeg &>/dev/null; then
        command -v ffmpeg
        return
    fi
    echo "ffmpeg not found. Please install ffmpeg to use transcoding."
    exit 1
}
ffmpeg="$(find_ffmpeg)"

cleanup() {
    # shellcheck disable=SC2317
    echo -e "\nCleaning up unfinished files..."
    # shellcheck disable=SC2317
    for f in "${TRAP_CLEANUP_FILES[@]}"; do
        if [[ -f "$f" ]]; then
            rm -f "$f"
        fi
    done
    # shellcheck disable=SC2317
    exit 130
}
trap cleanup SIGINT SIGTERM

scrub_url() {
    local url="$1"
    if [[ "$url" =~ $SCRUB_YOUTUBE_REGEX ]]; then
        if $yes_playlist; then
            if [[ "$url" =~ list=([^&]+) ]]; then
                echo "https://www.youtube.com/playlist?list=${BASH_REMATCH[1]}"
                return
            fi
        else
            if [[ "$url" =~ v=([^&]+) ]]; then
                echo "https://www.youtube.com/watch?v=${BASH_REMATCH[1]}"
                return
            elif [[ "$url" =~ youtu\.be/([^?]+) ]]; then
                echo "https://www.youtube.com/watch?v=${BASH_REMATCH[1]}"
                return
            fi
        fi
    fi
    echo "$url"
}

if [[ ${#urls[@]} -eq 0 && -z "$batch_file" && ${#yt_dlp_args[@]} -gt 0 ]]; then
    for arg in "${yt_dlp_args[@]}"; do
        if [[ "$arg" =~ ^https?:// ]]; then
            urls+=("$arg")
        elif [[ -f "$arg" ]]; then
            batch_file="$arg"
        fi
    done
    yt_dlp_args=()
fi

if [[ -n "$batch_file" ]]; then
    yt_dlp_opts+=("--batch-file" "$batch_file")
fi

if [[ ${#urls[@]} -eq 0 && -z "$batch_file" ]]; then
    echo "No URLs or batch file provided."
    show_help
    exit 1
fi

download_indicator() {
    # shellcheck disable=SC1003
    local chars=('-' '\\' '|' '/')
    local i=0
    while :; do
        # No colours, just plain animation
        echo -ne "Downloading... ${chars[$((i % 4))]} \r"
        sleep 0.1
        ((i++))
    done
}

retry_countdown() {
    local count="$1"
    local i
    for ((i=count; i>0; i--)); do
        # Only the number is coloured (cyan)
        echo -ne "Retrying in \033[0;36m$i\033[0m seconds...    \r"
        sleep 1
    done
    echo -ne "                                    \r"
}

download_video() {
    local url="$1"
    local scrubbed_url
    scrubbed_url="$(scrub_url "$url")"
    local start_time
    local retry_time=0
    local retry_count=0
    local output=""
    local indicator_pid=""
    local elapsed=0

    start_time="$(date +%s)"

    while true; do
        # Start indicator
        download_indicator &
        indicator_pid=$!
        # Run yt-dlp and capture output
        output="$("$yt_dlp" "${yt_dlp_opts[@]}" "$scrubbed_url" "${yt_dlp_args[@]}" 2>&1)"
        kill "$indicator_pid" 2>/dev/null
        wait "$indicator_pid" 2>/dev/null

        # Reuse the same line, no newline unless status changes
        echo -ne "                                                     \r"

        # Look for success
        for pat in "${SUCCESS_PATTERNS[@]}"; do
            if echo "$output" | grep -q "$pat"; then
                echo "Download successful!"
                return 0
            fi
        done
        # Look for stop pattern
        for pat in "${STOP_PATTERNS[@]}"; do
            if echo "$output" | grep -qi "$pat"; then
                elapsed=$(( ($(date +%s) - start_time) / 60 ))
                echo "Download requires authentication/age verification. Giving up after $elapsed minute(s)."
                return 2
            fi
        done
        # Look for retry pattern
        for pat in "${RETRY_PATTERNS[@]}"; do
            if echo "$output" | grep -q "$pat"; then
                retry_time=$(( RANDOM % 11 + 5 ))
                ((retry_count++))
                elapsed=$(( ($(date +%s) - start_time) / 60 ))
                if (( elapsed >= MAX_RETRY_MINS )); then
                    echo "Retried for $MAX_RETRY_MINS minute(s). Abandoning download."
                    return 1
                fi
                retry_countdown "$retry_time"
                continue 2
            fi
        done
        echo "yt-dlp encountered an error: $output" >&2
        return 1
    done
}

if [[ -n "$batch_file" ]]; then
    echo "Downloading batch file: $batch_file"
    download_indicator &
    ind_pid=$!
    "$yt_dlp" "${yt_dlp_opts[@]}" "${yt_dlp_args[@]}"
    kill "$ind_pid" 2>/dev/null
    echo ""
else
    for url in "${urls[@]}"; do
        local_cleaned_url="$(scrub_url "$url")"
        echo -e "\nDownloading: $local_cleaned_url"
        download_video "$url"
        echo ""
    done
fi

exit 0
