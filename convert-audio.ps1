# Parameters:
# inputAudioPath: The path to the input audio file or directory. It should be a string representing a valid file or directory path.
# outputAudioPath: The path where the output audio will be saved. It should be a string representing a valid file or directory path.
# audioBitrate: The bitrate for the audio stream in the output file. It should be a string in the format like "192k", "128k", etc. If not specified, it will be the same as the original file.
# overwrite: A switch to control whether to overwrite existing output files. If true, existing files will be overwritten without asking.
param (
    [string]$inputAudioPath, # Path to input audio or directory
    [string]$outputAudioPath, # Path to output audio or directory
    [string]$audioBitrate = '128k', # Audio bitrate like '192k', '128k', etc.
    [switch]$overwrite = $false  # Overwrite existing files
)

# Check if FFmpeg is available
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "Error: FFmpeg is not installed or not in the system PATH."
    exit 1
}

# Check if input and output paths are provided and if input file or directory exists
if ([string]::IsNullOrEmpty($inputAudioPath) -or [string]::IsNullOrEmpty($outputAudioPath)) {
    Write-Error "Error: Input and output audio paths are required."
    exit 1
}

if (-not (Test-Path -Path $inputAudioPath)) {
    Write-Error "Error: Input audio file or directory not found."
    exit 1
}

# Get all audio files in the input directory if it's a directory
$audioFiles = if (Test-Path -Path $inputAudioPath -PathType Container) {
    Get-ChildItem -Path $inputAudioPath -File | Where-Object { $_.Extension -in @('.mp3', '.wav', '.flac', '.m4a', '.ogg') }
}
else {
    Get-Item -Path $inputAudioPath
}

foreach ($audioFile in $audioFiles) {
    # Prepare FFmpeg command
    $ffmpegCommand = "ffmpeg "
    
    if ($overwrite) {
        $ffmpegCommand += "-y "
    }

    $ffmpegCommand += "-i '$($audioFile.FullName)' -c:a libopus -b:a $audioBitrate "


    # Prepare output file path
    $outputFilePath = if (Test-Path -Path $outputAudioPath -PathType Container) {
        Join-Path -Path $outputAudioPath -ChildPath ($audioFile.BaseName + ".ogg")
    }
    else {
        $outputAudioPath
    }

    $ffmpegCommand += "'$outputFilePath'"

    # Convert audio with specified bitrate (if provided)
    Invoke-Expression -Command:$ffmpegCommand

    # Check the exit code of the FFmpeg command (error handling)
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: FFmpeg command failed."
        exit $LASTEXITCODE
    }
}
