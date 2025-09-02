# Peertube-tool

Welcome to a collection of utility scripts designed for PeerTube 
(https://joinpeertube.org/, https://github.com/Chocobozzz/PeerTube). While 
primarily tailored for this platform, some of these scripts may also prove beneficial for other applications.

To fully utilise the download script, it is essential to configure your own defaults for [yt-dlp](https://github.com/yt-dlp/yt-dlp?tab=readme-ov-file#configuration) in the `~/yt-dlp.conf` file. In particular, ensure that you set the following option:

```ini
--proxy socks5://localhost:9050
```

This configuration allows you to route your traffic through your Tor proxy. Without this setup, the scripts may not function as intended.

-- Enjoy our privacy and **BLEEP** Google's >>**_Do be evil_**<<

## Requirements

To use these scripts, you will need the following third-party tools. **Please do not** use the versions provided by your operating system; instead, download them directly from the official sources to ensure you have the latest stable and secure versions.

1. **yt-dlp**: You can find it here: [yt-dlp GitHub Repository](https://github.com/yt-dlp/yt-dlp).

2. **FFmpeg**: I recommend using the modified version of FFmpeg provided by yt-dlp for downloading. You can get it from: [yt-dlp FFmpeg Builds](https://github.com/yt-dlp/FFmpeg-Builds). Alternatively, you can use the nightly builds compiled by John Vansickle, available at: [John Vansickle's FFmpeg Builds](https://johnvansickle.com/ffmpeg/).

3. **peertube-cli**: More information can be found here: [PeerTube CLI Documentation](https://docs.joinpeertube.org/support/doc/tools#remote-peertube-cli). Please ensure you configure your PeerTube account in advance, as these scripts are designed to work with a single PeerTube account.

## Support and Contact

For support, please use our tracking-free and privacy-respecting issue platform, sponsored by JetBrains S.R.L.

- For issues related to these tools, please visit: [Tool Issues](https://kb.mypdns.org/projects/TBX/issues).
- For general inquiries, you can reach us at: [General Inquiries](https://kb.mypdns.org/projects/MPDNS/issues).

---------------------

## Video Downloader Script
### Introduction

Welcome to the Video Downloader script — a compact, robust Bash utility that uses yt-dlp for fetching videos and ffmpeg for post-processing. It's designed for both experienced sysadmins and newcomers: configurable, shellcheck-friendly, and suitable for single-URL downloads or batch lists.


### What’s new in 1.2.0

- **Version:** **1.2.0** (2025-09-02)
- Spinner and retry UI simplified to a plain ASCII spinner (`-\|/`) and now reuse a single terminal line for progress and retry indicators to reduce noisy output.
- The script now prints the **scrubbed (cleaned) URL** in the "Downloading:" line (no raw input shown).
- Multiple shellcheck compliance improvements and parsing robustness fixes.
- Minor internal fixes (see changelog).


### Features

1. Dynamic PATH management: automatically prepends user-specific binary directories (`~/.local/bin` and `~/bin`) so local installs of `yt-dlp` or `ffmpeg` are found without extra setup.
2. Robust error handling and retry logic: handles common HTTP/geolocation issues and retries with randomized backoff to mitigate transient failures and rate limits.
3. Customizable output naming: configure output filename templates for consistent library organization.
4. Subtitle support: download subtitles in specified languages and formats.
5. Clean terminal UI: progress, spinner, and retry messages reuse the same terminal line for a tidy output experience.
6. ffmpeg integration: convert/normalize media, generate thumbnails, or adjust audio/video parameters after download.


### Requirements

- bash (POSIX-compatible; tested with bash v4+)
- yt-dlp
- ffmpeg (optional, required for conversion/thumbnail tasks)
- coreutils (standard on most Linux/macOS systems)


### Quick start

1. Ensure dependencies are installed (example):
    - yt-dlp: pip install -U yt-dlp or use packaged release
    - ffmpeg: package manager or static build
2. Make the script executable:
    ```shell
    chmod +x video-downloader.sh
    ```
3. Single URL:
    ```shell
    ./video-downloader.sh -u "https://example.com/watch?v=abc123"
    ```
4. From a file (one URL per line):
    ```shell
    ./video-downloader.sh -f urls.txt
    ```
5. Show help:
    ```shell
    ./video-downloader.sh -h
    ```


### CLI options (common)

- -u, --url <URL>         Download a single URL
- -f, --file <FILE>       Read list of URLs from FILE (one per line)
- -o, --output <TEMPLATE> Set yt-dlp output template
- -s, --sub-lang <LANG>   Download subtitles for language (comma-separated)
- -v, --version           Print script version (now **1.2.0**)
- -h, --help              Display usage information

(Exact flags and behavior are implemented in-script; run -h for the complete list.)


### Behavior & UX notes

- The script sanitizes and prints a cleaned URL when starting a download to avoid exposing raw user input or extraneous whitespace.
- Terminal feedback (spinner/retry) is intentionally minimal and uses a single-line spinner `-\|/` for broad compatibility (no colour).
- Retry attempts display on the same line to avoid flooding logs with transient failure messages.


### Development & compliance

- Script aims for strong shellcheck compliance; notable annotations remain where traps or intentionally-unreachable functions would otherwise raise warnings (explicitly annotated with shellcheck disables where required).
- Contributions and issues: please follow the repository’s contributing guidelines and include shellcheck output for any changes that affect parsing or error handling.


### Changelog (summary)

- 1.2.0 (2025-09-02): UI simplification (plain spinner, single-line reuse), scrubbed URL printing, shellcheck/hardening improvements, version bump.
- previous main (1.1.3): The basics to repeatedly retry download fro youtube

---------------------

## PeerTube upload script

### Introduction

Introducing the PeerTube Video Uploader script, a streamlined and efficient tool designed for both experienced system administrators and enthusiastic newcomers. This Bash script simplifies the process of uploading video files to PeerTube, a decentralized video hosting platform, using the `peertube-cli` command-line interface. With its user-friendly options and robust functionality, this script empowers users to manage their video content effortlessly, making it an essential tool for anyone looking to share media online.

### Deeper Dive

The PeerTube Video Uploader script is crafted to cater to a diverse audience, from seasoned tech professionals who appreciate command-line efficiency to novices eager to explore video sharing. This script not only facilitates video uploads but also ensures that users can easily manage associated metadata, such as tags and channel names, enhancing the overall user experience.

#### Key Features:

1. **User-Friendly Command-Line Interface**: The script provides clear command-line options for specifying tags and channel names, making it accessible for users of all skill levels. The help and version options ensure that users can quickly find the information they need.

2. **Channel Name Validation**: Users can specify a channel name from a predefined list, ensuring that uploads are organized and consistent. If an invalid channel name is entered, the script prompts the user to select from valid options, reducing errors and confusion.

3. **Dynamic File Handling**: The script automatically scans the current directory for video files with supported extensions, allowing users to upload multiple videos in one go. This batch processing capability saves time and effort, especially for users with extensive media libraries.

4. **Description and Image File Integration**: Each video can have an associated description file, which the script reads and uploads alongside the video. Additionally, if a corresponding image file is found, it is uploaded as a thumbnail, enhancing the visual appeal of the video on the platform.

5. **Extensive Format Support**: The script supports a wide range of video and image file formats, ensuring compatibility with various media types. This flexibility allows users to upload their content without worrying about format restrictions.

6. **Error Handling and Feedback**: The script includes checks for file existence and provides informative error messages, guiding users through any issues that may arise during the upload process. This feedback loop is crucial for maintaining a smooth user experience.

In summary, the PeerTube Video Uploader script is a powerful and versatile tool that simplifies the video uploading process while providing essential features for effective media management. Its combination of user-friendly design and robust functionality makes it an invaluable resource for both experienced users and those new to video sharing. With this script, users can confidently share their content on PeerTube, contributing to a decentralized and vibrant media ecosystem.
