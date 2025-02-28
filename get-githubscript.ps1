#for ninja testpush
#you should totally env variable this guy below
$accessToken = "Insert_ya_own"

# Replace scriptPath with the path to the script you want to download.  Retrieve this from the github repo's individual script page by clicking on the copy path button.
# Example script page:  https://github.com/COMPANY/DATA/SCRIPT_NAME.ps1

#you should set this up in ninja as a script variable
$scriptPath = $env:githubscriptpath

# Split script path into directory and filename
$scriptFileName = Split-Path $scriptPath -Leaf
# $scriptDirectory = Split-Path $scriptPath -Parent

# Validate script path
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    throw "Script path cannot be empty"
}

try {
    $scriptbaseUrl = "https://api.github.com/repos/COMPANY/DATA/contents"
    $scriptUrl = $scriptbaseUrl + "/" + $scriptPath

    $downloadPath = "$env:systemdrive\temp"
    $filePath = Join-Path $downloadPath $scriptFileName

    # Create all necessary directories in the path
    if (-not (Test-Path $downloadPath)) {
        New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
    }


    
    # Add error handling for API calls
    $response = Invoke-RestMethod $scriptUrl -Method Get -Headers @{
        "Authorization" = "Bearer $accessToken"
        "Accept" = "application/vnd.github.v3+json"
    } -ErrorAction Stop
    
    $url = $response.download_url
    Invoke-WebRequest $url -OutFile $filePath -ErrorAction Stop

    if (Test-Path $filePath) {
        Write-Host "File downloaded successfully: $filePath"
    } else {
        throw "File was not created after download attempt"
    }
} catch {
    Write-Error "Error occurred: $_"
    exit 1
}

