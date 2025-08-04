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
#

VERSION="1.1.3"

# Add ~/.local/bin and ~/bin to PATH if they exist
if [ -d "$HOME/.local/bin" ]; then
export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
export PATH="$HOME/bin:$PATH"
fi

# Initialize variables
yt_dlp=""
urls=()
source_file=""
ffmpeg=""
outpuFileName=""

# Set ffmpeg path
ffmpeg="/usr/local/bin/ffmpeg"

# $outpu File Name
outpuFileName="%(playlist_index|)s%(playlist_index&. |)s%(title)s - %(release_date>%Y-%m-%d,upload_date>%Y-%m-%d|Unknown)s 00:01.%(ext)s"

# Check for /usr/local/bin/yt-dlp first
if command -v /usr/local/bin/yt-dlp &> /dev/null; then
yt_dlp="/usr/local/bin/yt-dlp"
# If not found, check /usr/bin/yt-dlp
elif command -v /usr/bin/yt-dlp &> /dev/null; then
yt_dlp="/usr/bin/yt-dlp"
else
echo "yt-dlp not found. Please install it to use this script."
exit 1
fi

# Display help
show_help() {
cat << EOF
Usage: $0 [OPTIONS]

Options:
-u, --url, --uri      Specify a video URL (can be used multiple times for multiple URLs)
-a, -f, --file        Specify a file containing URLs (one per line)
-h, --help            Show this help message and exit
-v, --version         Show version information and exit

Example:
$0 -u "https://www.youtube.com/watch?v=video1" -u "https://www.youtube.com/watch?v=video2"
$0 -a urls.txt
EOF
}

# Display version
show_version() {
echo "Video Downloader version $VERSION"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
case "$1" in
-u|--url|--uri)
urls+=("$2")
shift 2
;;
-a|-f|--file)
source_file="$2"
shift 2
;;
-h|--help)
show_help
exit 0
;;
-v|--version)
show_version
exit 0
;;
*)
echo "Unknown option: $1"
show_help
exit 1
;;
esac
done

# Read URLs from the source file if specified
if [[ -n "$source_file" ]]; then
if [[ -f "$source_file" ]]; then
while IFS= read -r line || [[ -n "$line" ]]; do
urls+=("$line")
done < "$source_file"
else
echo "Source file '$source_file' not found."
exit 1
fi
fi

# Ensure at least one URL is provided
if [[ ${#urls[@]} -eq 0 ]]; then
echo "No URLs provided. Use -u/--url or -a/-f/--file to specify URLs."
show_help
exit 1
fi

# Define the subtitle languages
sub_langs="en,en-nP7*,fr-*,da-*,de-*,pt-*,es-*,en-nP7-2PuUl7o,fr-rSJfcHgCuhE,de-hrwxFetOmHM,pt-BR-ykZLUhi1BHQ,es-y1SAwy5xd4g"

# Function to download a single video
download_video() {
local input_url="$1"
local video_id="${input_url#*v=}"
video_id="${video_id%%&*}"
local download_url="https://www.youtube.com/watch?v=${video_id}"

echo -e "\nVideo ID: $video_id"
echo "Downloading URL: $download_url"

# Retry logic
while true; do
# Download the video using yt-dlp and capture the output
output=$("$yt_dlp" "$download_url" \
--write-subs \
--no-playlist \
--no-embed-metadata \
--write-description \
--audio-quality 0 \
--write-subs \
--sub-format "vtt/srt/best" \
--sub-langs "$sub_langs" \
--concurrent-fragments 4 \
--no-cookies \
--no-cookies-from-browser \
--rm-cache-dir \
--write-thumbnail \
--convert-thumbnails webp \
-o "$outpuFileName" \
-f 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4][protocol!*=dash][protocol^=m3u8] / bv*+ba/b' \
--progress 2>&1)

# Print the output in real-time
echo "$output"

# Check for success
if echo "$output" | grep -q "Merging formats into"; then
echo "Download successful!"
break
fi

# Check for specific error messages
if echo "$output" | grep -q "HTTP Error 403: Forbidden" || echo "$output" | grep -q "Sign in to confirm" || echo "$output" | grep -q "The uploader has not made this video available in your country"; then
# Generate a random sleep time between 5 and 15 seconds
sleep_time=$((RANDOM % 11 + 5))
echo "Encountered an error. Retrying in $sleep_time seconds..."
sleep "$sleep_time"
else
echo "yt-dlp encountered an error: $output" >&2
exit 1
fi
done

# Optional: Print the video ID and download URL
echo -e "\nVideo ID: $video_id"
echo -e "Download URL: $download_url\n"
}

# Process each URL
for url in "${urls[@]}"; do
download_video "$url"
done

exit 0
