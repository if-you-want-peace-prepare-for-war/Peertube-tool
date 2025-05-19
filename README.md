# Peertube-tool

Welcome to a collection of utility scripts designed for PeerTube. While primarily tailored for this platform, some of these scripts may also prove beneficial for other applications.

To fully utilise the download script, it is essential to configure your own defaults for [yt-dlp](https://github.com/yt-dlp/yt-dlp?tab=readme-ov-file#configuration) in the `~/yt-dlp.conf` file. In particular, ensure that you set the following option:

```ini
--proxy socks5://localhost:9050
```

This configuration allows you to route your traffic through your Tor proxy. Without this setup, the scripts may not function as intended.

-- Enjoy our privacy and **** Google's >>**Do be evil**<<

---------------------

## Video Downloader Script
### Introduction

Welcome to the Video Downloader script, a powerful and flexible tool designed for both seasoned system administrators and aspiring tech enthusiasts. This Bash script leverages the capabilities of `yt-dlp`, a popular command-line utility for downloading videos from various platforms, and integrates it with `ffmpeg` for enhanced media processing. Whether you're looking to archive your favorite videos, create a personal media library, or simply experiment with video downloading, this script provides a straightforward yet robust solution.

### Deeper Dive

The Video Downloader script is structured to cater to a wide range of users, from experienced system admins who appreciate the nuances of command-line tools to newcomers eager to learn. At its core, the script is designed to download videos from specified URLs or from a list contained in a file, making it versatile for different use cases.

#### Key Features:

1. **Dynamic Path Management**: The script automatically adds user-specific binary directories (`~/.local/bin` and `~/bin`) to the `PATH`, ensuring that custom installations of `ffmpeg` and `yt-dlp` are recognized without additional configuration.

2. **Error Handling and Retry Logic**: Robust error handling is implemented to manage common issues such as HTTP errors or geographical restrictions. The script includes a retry mechanism that waits for a random interval before attempting to download again, which can be particularly useful when dealing with rate limits or temporary server issues.

3. **Customizable Output**: Users can specify the output filename format, allowing for organized storage of downloaded videos. The script supports various subtitle languages and formats, enhancing accessibility for users who prefer or require subtitles.

4. **Command-Line Options**: The script provides a user-friendly interface with clear command-line options for specifying URLs, reading from a file, and displaying help or version information. This makes it easy for users to get started without needing to dive deep into the code.

5. **Real-Time Feedback**: As videos are downloaded, users receive real-time feedback in the terminal, including progress updates and error messages, which helps in monitoring the download process effectively.

6. **Compatibility with `ffmpeg`**: The integration with `ffmpeg` allows for advanced processing of downloaded media, such as converting thumbnail formats and managing audio quality, making this script not just a downloader but a comprehensive media management tool.

In summary, the Video Downloader script is a well-crafted tool that balances functionality and ease of use, making it suitable for both experienced users and those new to the world of video downloading. With its robust features and user-friendly design, it empowers users to take control of their media consumption in a way that is both efficient and effective.

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
