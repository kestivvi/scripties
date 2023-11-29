# Install Nerd Font
Write-Host "Install Nerd Fonts"
scoop bucket add nerd-fonts
scoop install IosevkaTerm-NF
Write-Host ""

# Install Starship
Write-Host "Install Starship"
winget install --id Starship.Starship
Write-Host ""

# Check if $PROFILE file exists
$profilePath = $PROFILE
if (-not (Test-Path -Path $profilePath)) {
    # If $PROFILE file doesn't exist, create the file
    New-Item -Path $profilePath -ItemType File -Force
    Write-Host "Created $PROFILE file"
}

# Activate Starship in Powershell
$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue
$lineToAdd = "Invoke-Expression (&starship init powershell)"

if ($profileContent -notcontains $lineToAdd) {
    Add-Content -Path $profilePath -Value "`n$lineToAdd"
    Write-Host "Added activation script to $PROFILE"
}
else {
    Write-Host "Activation script already exists in $PROFILE"
}

# Copy config
$sourcePath = "./terminal/starship.toml"
$destinationPath = "$env:USERPROFILE\.config\starship.toml"

try {
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force
    Write-Host "File copied successfully from $sourcePath to $destinationPath"
}
catch {
    Write-Host "An error occurred while copying the file: $_.Exception.Message"
}
