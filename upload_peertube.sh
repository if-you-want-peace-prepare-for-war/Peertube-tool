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

# Version
version="0.9.2"

# Function to display help text
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tags <tags>          Comma-separated list of tags to add to the upload."
    echo "  -c, --channel-name <name>  Specify the channel name for the upload."
    echo "  -h, --help                 Display this help message."
    echo "  -v, --version              Show the version of the script."
    echo ""
    echo "This script uploads video files to PeerTube using peertube-cli."
}

# Initialize variables
tags=""
channel_name="" # Initialize channel name as empty
valid_channels=("audiovideos" "lyricvideos" "musicvideos" "spirillen_musi" "videos")
video_extensions=("webm" "ogv" "ogg" "mp4" "mkv" "mov" "qt" "mqv" "m4v" "flv" "f4v" "wmv" "avi" "3gp" "3gpp" "3g2" "3gpp2" "nut" "mts" "m2ts" "mpv" "m2v" "m1v" "mpg" "mpe" "mpeg" "vob" "mxf" "mp3" "wma" "wav" "flac" "aac" "m4a" "ac3")
image_extensions=("png" "jpeg" "jpg" "gif" "webp")

# Function to prompt for a valid channel name
prompt_for_channel() {
    echo "Please select a channel name from the following options:"
    for i in "${!valid_channels[@]}"; do
        echo "$((i + 1)). ${valid_channels[i]}"
    done
    while true; do
        read -p "Enter the number corresponding to your choice: " choice
        if [[ "$choice" =~ ^[1-5]$ ]]; then
            channel_name="${valid_channels[$((choice - 1))]}"
            break
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

# Parse command-line arguments
while getopts ":t:c:-:hv" opt; do
    case $opt in
    t) tags="$OPTARG" ;;
    c)
        # shellcheck disable=SC2076
        # shellcheck disable=SC2199
        if [[ " ${valid_channels[@]} " =~ " $OPTARG " ]]; then
            channel_name="$OPTARG"
        else
            echo "Invalid channel name: $OPTARG"
            prompt_for_channel
        fi
        ;;
    -) case "${OPTARG}" in
        tags)
            tags="${!OPTIND}"
            OPTIND=$(($OPTIND + 1))
            ;;
        channel-name)
            channel_name="${!OPTIND}"
            # shellcheck disable=SC2076
            # shellcheck disable=SC2199
            if [[ ! " ${valid_channels[@]} " =~ " $channel_name " ]]; then
                echo "Invalid channel name: $channel_name"
                prompt_for_channel
            fi
            OPTIND=$(($OPTIND + 1))
            ;;
        help)
            show_help
            exit 0
            ;;
        version)
            echo "$version"
            exit 0
            ;;
        *)
            echo "Invalid option: --${OPTARG}" >&2
            exit 1
            ;;
        esac ;;
    h)
        show_help
        exit 0
        ;;
    v)
        echo "$version"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
done

# If channel_name is still empty, prompt for it
if [[ -z "$channel_name" ]]; then
    prompt_for_channel
fi

# Loop through all specified video file extensions in the current directory
for ext in "${video_extensions[@]}"; do
    for filename in *."$ext"; do
        # Check if the file exists to avoid errors
        if [[ -f "$filename" ]]; then
            # Remove the file extension to get the base filename
            base_filename="${filename%.*}"

            # Check if the description file exists
            description_file="${base_filename}.description"
            if [[ -f "$description_file" ]]; then
                # Use sed to process the description file and upload using peertube-cli
                # description=$(sed ':a;N;$!ba' "$description_file")
                description=$(cat "$description_file")

                # Determine if a valid image file exists
                image_file_ext=""
                for img_ext in "${image_extensions[@]}"; do
                    if [[ -f "$PWD/$base_filename.$img_ext" ]]; then
                        image_file_ext="$img_ext"
                        break
                    fi
                done

                # Construct the image file path
                image_file_path="$PWD/$base_filename.$image_file_ext"

                # Upload using peertube-cli only if a valid image is found
                if [[ -n "$image_file_ext" ]]; then
                    if [[ -n "$tags" ]]; then
                        peertube-cli upload -d "$description" -f "$PWD/$filename" \
                            -n "$base_filename" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                            -b "$image_file_path" -t "$tags"
                    else
                        peertube-cli upload -d "$description" -f "$PWD/$filename" \
                            -n "$base_filename" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                            -b "$image_file_path"
                    fi
                else
                    echo "No valid image files were found for $base_filename."
                fi
            else
                echo "Description file $description_file does not exist."
            fi
        fi
    done
done
