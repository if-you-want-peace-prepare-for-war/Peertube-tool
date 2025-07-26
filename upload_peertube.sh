#!/bin/bash

# Version
version="0.10.2"

# Function to display help text
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tags <tags>             Comma-separated list of tags to add to the upload."
    echo "  -c, --channel-name <name>     Specify the channel name for the upload."
    echo "  --skip-description-check      Skip checking for the description file."
    echo "  --skip-image-check            Skip checking for image files."
    echo "  -h, --help                    Display this help message."
    echo "  -v, --version                 Show the version of the script."
    echo ""
    echo "This script uploads video files to PeerTube using peertube-cli."
}

# Initialize variables
tags=""
channel_name="" # Initialize channel name as empty
skip_description_check=0
skip_image_check=0
valid_channels=("audiovideos" "lyricvideos" "musicvideos" "spirillen_musi" "videos" "nsfw")
video_extensions=("webm" "ogv" "ogg" "mp4" "mkv" "mov" "qt" "mqv" "m4v" "flv" "f4v" "wmv" "avi" "3gp" "3gpp" "3g2" "3gpp2" "nut" "mts" "m2ts" "mpv" "m2v" "m1v" "mpg" "mpe" "mpeg" "vob" "mxf" "mp3" "wma" "wav" "flac" "aac" "m4a" "ac3")
image_extensions=("png" "jpeg" "jpg" "gif" "webp")

# Function to prompt for a valid channel name
prompt_for_channel() {
    echo "Please select a channel name from the following options:"
    for i in "${!valid_channels[@]}"; do
        echo "$((i + 1)). ${valid_channels[i]}"
    done
    while true; do
        read -r -p "Enter the number corresponding to your choice: " choice
        if [[ "$choice" =~ ^[1-6]$ ]]; then
            channel_name="${valid_channels[((choice - 1))]}"
            break
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

pcli() {
  node --trace-deprecation "$(which peertube-cli)" "$@"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--tags)
            tags="$2"
            shift 2
            ;;
        -c|--channel-name)
            found=0
            for item in "${valid_channels[@]}"; do
                if [[ "$item" == "$2" ]]; then
                    found=1
                    channel_name="$2"
                    break
                fi
            done
            if (( !found )); then
                echo "Invalid channel name: $2"
                prompt_for_channel
            fi
            shift 2
            ;;
        --skip-description-check)
            skip_description_check=1
            shift
            ;;
        --skip-image-check)
            skip_image_check=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "$version"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
        *)
            # Not an option, break for positional arguments
            break
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
            base_filename="${filename%.*}"

            description_file="${base_filename}.description"
            description=""
            # Check if the description file exists, unless skipped
            if [[ $skip_description_check -eq 0 ]]; then
                if [[ -f "${description_file}" ]]; then
                    description=$(cat "${description_file}")
                else
                    echo "Description file ${description_file} does not exist."
                    continue
                fi
            else
                # Use empty description if skipping
                description=""
            fi

            image_file_ext=""
            image_file_path=""
            if [[ $skip_image_check -eq 0 ]]; then
                # Determine if a valid image file exists
                for img_ext in "${image_extensions[@]}"; do
                    if [[ -f "$PWD/${base_filename}.$img_ext" ]]; then
                        image_file_ext="$img_ext"
                        break
                    fi
                done
                image_file_path="$PWD/${base_filename}.$image_file_ext"

                if [[ -z "$image_file_ext" ]]; then
                    echo "No valid image files were found for ${base_filename}."
                    continue
                fi
            fi

            upload_output=""
            # Build the upload command
            if [[ $skip_image_check -eq 0 ]]; then
                # With image
                if [[ -n "$tags" ]]; then
                    upload_output=$(pcli upload -d "${description}" -f "$PWD/${filename}" \
                        -n "${base_filename}" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                        -b "{$image_file_path}" -t "$tags" --verbose 4 2>&1)
                else
                    upload_output=$(pcli upload -d "${description}" -f "$PWD/${filename}" \
                        -n "${base_filename}" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                        -b "${image_file_path}" --verbose 4 2>&1)
                fi
            else
                # Without image
                if [[ -n "$tags" ]]; then
                    upload_output=$(pcli upload -d "${description}" -f "$PWD/${filename}" \
                        -n "{$base_filename}" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                        -t "$tags" --verbose 4 2>&1)
                else
                    upload_output=$(pcli upload -d "${description}" -f "$PWD/${filename}" \
                        -n "${base_filename}" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                        --verbose 4 2>&1)
                fi
            fi

            # Check for success message and delete files if successful
            if [[ "$upload_output" == *"Video ${base_filename} uploaded."* ]]; then
                echo -e "Upload successful. Deleting\n  - ${filename}"
                rm -f -- "${filename}"
                if [[ $skip_description_check -eq 0 ]]; then
                    echo "  - ${description_file}"
                    rm -f -- "${description_file}"
                fi
                echo
            else
                echo "Upload failed for ${base_filename}. Output:"
                echo "$upload_output"
                echo
            fi

            # Add a 5-second countdown in random rainbow colors between uploads
            for i in {10..1}; do
                color=$((RANDOM % 7 + 31)); printf "\033[1;${color}m%ds \033[0m" "$i"; sleep 1; done; echo

        fi
    done
done
