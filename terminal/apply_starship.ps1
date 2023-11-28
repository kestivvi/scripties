# Install Starship
Write-Host "Install Starship"
winget install --id Starship.Starship
Write-Host ""

# Activate Starship in Powershell

# Check if the line already exists in $PROFILE
$profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
$lineToAdd = "Invoke-Expression (&starship init powershell)"

if ($profileContent -notcontains $lineToAdd) {
    Add-Content -Path $PROFILE -Value "`n$lineToAdd"
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
