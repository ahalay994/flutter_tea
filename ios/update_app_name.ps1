# PowerShell script to update the app name in Info.plist from .env file

$envFile = "..\.env"
$infoPlistFile = ".\Runner\Info.plist"

# Check if .env file exists
if (Test-Path $envFile) {
    # Read the content of .env file
    $envContent = Get-Content $envFile
    
    # Find the APP_NAME line
    $appNameLine = $envContent | Where-Object { $_ -match "^APP_NAME=" }
    
    if ($appNameLine) {
        # Extract the value after the equals sign
        $appName = ($appNameLine -split '=', 2)[1]
        
        # Remove surrounding quotes if present
        if ($appName.StartsWith('"') -and $appName.EndsWith('"')) {
            $appName = $appName.Substring(1, $appName.Length - 2)
        }
        elseif ($appName.StartsWith("'") -and $appName.EndsWith("'")) {
            $appName = $appName.Substring(1, $appName.Length - 2)
        }
        
        if ($appName) {
            # Load the Info.plist file
            [xml]$infoPlist = Get-Content $infoPlistFile
            
            # Update CFBundleDisplayName
            $displayNameNode = $infoPlist.plist.dict.SelectSingleNode("key[text()='CFBundleDisplayName']")
            if ($displayNameNode) {
                $nextNode = $displayNameNode.NextSibling
                if ($nextNode -and $nextNode.LocalName -eq "string") {
                    $nextNode.InnerText = $appName
                    Write-Host "Updated CFBundleDisplayName to: $appName"
                }
            } else {
                Write-Host "CFBundleDisplayName key not found in Info.plist"
            }
            
            # Update CFBundleName
            $bundleNameNode = $infoPlist.plist.dict.SelectSingleNode("key[text()='CFBundleName']")
            if ($bundleNameNode) {
                $nextNode = $bundleNameNode.NextSibling
                if ($nextNode -and $nextNode.LocalName -eq "string") {
                    $nextNode.InnerText = $appName
                    Write-Host "Updated CFBundleName to: $appName"
                }
            } else {
                Write-Host "CFBundleName key not found in Info.plist"
            }
            
            # Save the updated Info.plist
            $infoPlist.Save($infoPlistFile)
            Write-Host "Info.plist updated successfully"
        } else {
            Write-Host "APP_NAME not found or empty in .env file"
        }
    } else {
        Write-Host "APP_NAME not found in .env file"
    }
} else {
    Write-Host ".env file not found at $envFile"
}