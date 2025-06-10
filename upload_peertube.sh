#!/bin/bash

# Version
version="0.9.7"

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

# Print version
# node --trace-deprecation $(which peertube-cli)

# Function to prompt for a valid channel name
prompt_for_channel() {
    echo "Please select a channel name from the following options:"
    for i in "${!valid_channels[@]}"; do
        echo "$((i + 1)). ${valid_channels[i]}"
    done
    while true; do
        read -r -p "Enter the number corresponding to your choice: " choice
        if [[ "$choice" =~ ^[1-5]$ ]]; then
            channel_name="${valid_channels[((choice - 1))]}"
            break
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

peertube-cli() {
  node --trace-deprecation "$(which peertube-cli)" "$@"
}

# Parse command-line arguments
while getopts ":t:c:-:hv" opt; do
    case $opt in
    t) tags="$OPTARG" ;;
    c)
        found=0
        for item in "${valid_channels[@]}"; do
            if [[ "$item" == "$OPTARG" ]]; then
                found=1
                channel_name="$OPTARG"
                break
            fi
        done
        if (( !found )); then
            echo "Invalid channel name: $OPTARG"
            prompt_for_channel
        fi
        ;;
    -) case "${OPTARG}" in
        tags)
            tags="${!OPTIND}"
            ((OPTIND=OPTIND+1))
            ;;
        channel-name)
            channel_name="${!OPTIND}"
            found=0
            for item in "${valid_channels[@]}"; do
                if [[ "$item" == "$channel_name" ]]; then
                    found=1
                    break
                fi
            done
            if (( !found )); then
                echo "Invalid channel name: $channel_name"
                prompt_for_channel
            fi
            ((OPTIND=OPTIND+1))
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
                description=$(cat "$description_file")

                # Determine if a valid image file exists
                image_file_ext=""
                for img_ext in "${image_extensions[@]}"; do
                    if [[ -f "$PWD/$base_filename.$img_ext" ]]; then
                        image_file_ext="$img_ext"
                        break
                    fi
                done

                image_file_path="$PWD/$base_filename.$image_file_ext"

                # Upload using peertube-cli only if a valid image is found
                if [[ -n "$image_file_ext" ]]; then
                    upload_output=""
                    if [[ -n "$tags" ]]; then
                        upload_output=$(peertube-cli upload -d "$description" -f "$PWD/$filename" \
                            -n "$base_filename" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                            -b "$image_file_path" -t "$tags" --verbose 4 2>&1)
                    else
                        upload_output=$(peertube-cli upload -d "$description" -f "$PWD/$filename" \
                            -n "$base_filename" -c 1 -l 4 -L en -P 3 -C "$channel_name" \
                            -b "$image_file_path" --verbose 4 2>&1)
                    fi

                    # Check for success message and delete files if successful
                    if [[ "$upload_output" == *"Video $base_filename uploaded."* ]]; then
                        printf "Upload successful. Deleting\n  - $filename\n  - $description_file\n"
                        rm -f -- "$filename" "$description_file"
                    else
                        echo "Upload failed for $base_filename. Output:"
                        echo "$upload_output"
                        echo
                    fi

                    # Add a 5-second countdown in random rainbow colors between uploads
                    for i in {10..1}; do
                        color=$((RANDOM % 7 + 31)); printf "\033[1;${color}m%ds \033[0m" "$i"; sleep 1; done; echo
                else
                    echo "No valid image files were found for $base_filename."
                fi
            else
                echo "Description file $description_file does not exist."
            fi
        fi
    done
done
