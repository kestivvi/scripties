# Parameters:
# inputVideoPath: The path to the input video file or directory. It should be a string representing a valid file or directory path.
# outputVideoPath: The path where the output video will be saved. It should be a string representing a valid file or directory path.
# crf: The Constant Rate Factor (CRF) value used for the H.265/HEVC video encoding process. It should be an integer between 0 (lossless) and 51 (worst quality). Default is 25.
# audioBitrate: The bitrate for the audio stream in the output file. It should be a string in the format like "192k", "128k", etc. If not specified, it will be the same as the original file.
# videoResolution: The resolution for the output video. It should be a string in the format like "1280x720", "1920x1080", etc. If not specified, it will be the same as the original file.
# overwrite: A switch to control whether to overwrite existing output files. If true, existing files will be overwritten without asking.
param (
    [string]$inputVideoPath, # Path to input video or directory
    [string]$outputVideoPath, # Path to output video or directory
    [int]$crf = 25, # CRF value for H.265/HEVC encoding. Range: 0-51
    [string]$audioBitrate, # Audio bitrate like '192k', '128k', etc.
    [string]$videoResolution, # Video resolution like '1280x720', '1920x1080', etc.
    [switch]$overwrite = $false  # Overwrite existing files
)

# Check if FFmpeg is available
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "Error: FFmpeg is not installed or not in the system PATH."
    exit 1
}

# Check if input and output paths are provided and if input file or directory exists
if ([string]::IsNullOrEmpty($inputVideoPath) -or [string]::IsNullOrEmpty($outputVideoPath)) {
    Write-Error "Error: Input and output video paths are required."
    exit 1
}

if (-not (Test-Path -Path $inputVideoPath)) {
    Write-Error "Error: Input video file or directory not found."
    exit 1
}

# Get all video files in the input directory if it's a directory
$videoFiles = if (Test-Path -Path $inputVideoPath -PathType Container) {
    Get-ChildItem -Path $inputVideoPath -File | Where-Object { $_.Extension -in @('.mp4', '.avi', '.mkv', '.mov') }
}
else {
    Get-Item -Path $inputVideoPath
}

foreach ($videoFile in $videoFiles) {
    # Prepare FFmpeg command
    $ffmpegCommand = "ffmpeg "
    
    if ($overwrite) {
        $ffmpegCommand += "-y "
    }

    $ffmpegCommand += "-i '$($videoFile.FullName)' -c:v libx265 -crf $crf -c:a libopus "

    if ($audioBitrate) {
        $ffmpegCommand += "-b:a $audioBitrate "
    }

    if ($videoResolution) {
        $ffmpegCommand += "-s:v $videoResolution "
    }

    # Prepare output file path
    $outputFilePath = if (Test-Path -Path $outputVideoPath -PathType Container) {
        Join-Path -Path $outputVideoPath -ChildPath $videoFile.Name
    }
    else {
        $outputVideoPath
    }

    $ffmpegCommand += "'$outputFilePath'"

    # Convert video without adjusting audio volume but with specified audio bitrate and video resolution (if provided)
    Invoke-Expression -Command:$ffmpegCommand

    # Check the exit code of the FFmpeg command (error handling)
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: FFmpeg command failed."
        exit $LASTEXITCODE
    }
}
