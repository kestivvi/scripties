$settingsJsonPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$newSettingsJsonPath = "./terminal/newSettings.json"

# Function to perform a deep merge between two objects
function Merge-ObjectsDeeply ($target, $source) {
    foreach ($key in $source.PSObject.Properties.Name) {
        if ($target.$key -eq $null) {
            # If the target object doesn't have the property, add it
            $target | Add-Member -MemberType NoteProperty -Name $key -Value $source.$key
        }
        elseif ($key -eq "schemes" -and $source.$key -is [System.Collections.IEnumerable] -and $target.$key -is [System.Collections.IEnumerable]) {
            # If the property is "schemes", merge based on "name" property
            foreach ($newItem in $source.$key) {
                $oldItem = $target.$key | Where-Object { $_.name -eq $newItem.name }
                if ($oldItem -ne $null) {
                    $target.$key = $target.$key | Where-Object { $_.name -ne $newItem.name }
                }
                $target.$key += $newItem
            }
        }
        elseif ($key -eq "list" -and $source.$key -is [System.Collections.IEnumerable] -and $target.$key -is [System.Collections.IEnumerable]) {
            # If the property is "list", merge based on "source" property and preserve "guid"
            foreach ($newProfile in $source.$key) {
                $oldProfile = $target.$key | Where-Object { $_.source -eq $newProfile.source }
                if ($oldProfile -ne $null) {
                    $oldGuid = $oldProfile.guid  # Preserve original guid
                    $newProfileProps = $newProfile | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
                    foreach ($prop in $newProfileProps) {
                        if ($oldProfile.PSObject.Properties.Name -contains $prop) {
                            $oldProfile.$prop = $newProfile.$prop
                        }
                        else {
                            $oldProfile | Add-Member -MemberType NoteProperty -Name $prop -Value $newProfile.$prop
                        }
                    }
                    $oldProfile.guid = $oldGuid
                }
                else {
                    $target.$key += $newProfile
                }
            }
        }
        elseif ($source.$key -is [System.Collections.IEnumerable] -and $target.$key -is [System.Collections.IEnumerable] -and ($source.$key -isnot [string]) -and ($target.$key -isnot [string])) {
            # If the property is an array or list (and not a string), merge them
            $merged = @(Compare-Object -ReferenceObject $source.$key -DifferenceObject $target.$key -PassThru)
            $target.$key = $merged
        }
        elseif ($source.$key -is [System.Management.Automation.PSCustomObject]) {
            # If the property is an object, merge it recursively
            Merge-ObjectsDeeply $target.$key $source.$key
        }
        else {
            # Otherwise, update the property in the target object
            $target.$key = $source.$key
        }
    }
}


# Read contents of settings.json and newSettings.json
$settings = Get-Content -Path $settingsJsonPath -Raw | ConvertFrom-Json
$newSettings = Get-Content -Path $newSettingsJsonPath -Raw | ConvertFrom-Json

# Merge the settings deeply
Merge-ObjectsDeeply $settings $newSettings

# Convert the merged object back to JSON and save it to the settings.json file
$settingsJson = $settings | ConvertTo-Json -Depth 10
$settingsJson | Set-Content -Path $settingsJsonPath
