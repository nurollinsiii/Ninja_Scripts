# Check for DellBOSS disk drives
$dellBossDisks = Get-PhysicalDisk | Where-Object { $_.FriendlyName -like "*DELLBOSS*" }

if ($dellBossDisks) {
    Write-Host "DellBOSS card(s) found:"
    Ninja-Property-Set bosscardfound "Found"
    $dellBossDisks | Format-Table FriendlyName, Size, HealthStatus

    # Define the paths
    $ImageNetPath = "$env:SystemDrive\ImageNet"
    $staticPath = "$env:SystemDrive\ImageNet\extracted\i386\static"
    $url = "https://imagenetmit.blob.core.windows.net/sec-stack-installers/mvsetup_5.0.13.1109_A00.zip"
    $downloadPath = Join-Path $ImageNetPath "download.zip"
    $extractPath = Join-Path $ImageNetPath "extracted"

    # Check to see if device has ImageNet path & create if not
    if (!(Test-Path -Path $ImageNetPath)) {
        New-Item -ItemType Directory -Path $ImageNetPath -Force
        Write-Host "Directory created successfully at: $ImageNetPath"
    } else {
        Write-Host "Directory already exists at: $ImageNetPath"
    }

    # Check if static path exists for mvsetup
    if (Test-Path -Path $staticPath) {
        Write-Host "Static path already exists at: $staticPath - proceeding with existing files"
    } else {
        Write-Host "Static path does not exist. Creating directory and downloading required files..."
        New-Item -ItemType Directory -Path $staticPath -Force

        try {
            # Download the zip file
            Write-Host "Downloading zip file..."
            Invoke-WebRequest -Uri $url -OutFile $downloadPath

            # Create extraction directory if it doesn't exist
            if (-not (Test-Path $extractPath)) {
                New-Item -ItemType Directory -Path $extractPath | Out-Null
            }

            # Extract the zip file
            Write-Host "Extracting zip file..."
            Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        }
        catch {
            Write-Host "An error occurred during the download or extraction: $_"
        }
    }

    try {
        # Change to the extracted directory
        Push-Location (Join-Path $extractPath "i386\static")

        # Get physical and virtual disk info
        $virtual_disk_info = .\mvsetup info -o vd
        $physical_disk_info = .\mvsetup info -o pd
        $physical_disk0_smart_info = @{
            "SMART STATUS" = ((.\mvsetup smart -p 0 | Select-String -Pattern "^SMART STATUS RETURN: (.*?)\.?$").Matches.Groups[1].Value).Trim()
        }
        $physical_disk1_smart_info = @{
            "SMART STATUS" = ((.\mvsetup smart -p 1 | Select-String -Pattern "^SMART STATUS RETURN: (.*?)\.?$").Matches.Groups[1].Value).Trim()
        }

        # Get physical disk info and convert to structured JSON
        $pdInfoArray = @()
        $currentDisk = [ordered]@{}
        
        # Skip header lines and process disk info
        ($physical_disk_info -split "`n" | Select-String -Pattern "^[A-Za-z].*?:\s+.*$").Matches.Value | ForEach-Object {
            $line = $_.Trim()
            if ($line -match "^Adapter:\s+") {
                if ($currentDisk.Count -gt 0) {
                    $pdInfoArray += $currentDisk
                    $currentDisk = [ordered]@{}
                }
            }
            if ($line -match "^(.*?):\s+(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $currentDisk[$key] = $value
            }
        }
        
        # Add the last disk
        if ($currentDisk.Count -gt 0) {
            $pdInfoArray += $currentDisk
        }

        # Store the raw JSON data
        $physical_disk_json = $pdInfoArray | ConvertTo-Json -Depth 10

        # Create formatted summary data
        $diskSummary = @()
        foreach ($disk in $pdInfoArray) {
            $diskSummary += [PSCustomObject]@{
                'Physical Disk ID' = $disk.'PD ID'
                'SMART Status'     = $disk.SMART
                'Running OS'       = $disk.'Running OS'
                'Model'            = $disk.'Model'  # Added Model to the summary
            }
        }

        # Parse the virtual disk info output
        if ($virtual_disk_info) {
            # Create a custom object to store the parsed values
            $status = ($virtual_disk_info | Select-String "status:\s+(\w+)").Matches.Groups[1].Value
            if ($status -eq "functional") {
                $status = "OK"
            }
            
            $vdiskinfo = [PSCustomObject]@{
                Status   = $status
                RaidMode = ($virtual_disk_info | Select-String "RAID mode:\s+(\w+\d*)").Matches.Groups[1].Value
                NumPDs   = ($virtual_disk_info | Select-String "# of PDs:\s+(\d+)").Matches.Groups[1].Value
                TotalVDs = ($virtual_disk_info | Select-String "Total # of VD:\s+(\d+)").Matches.Groups[1].Value
            }
        }


        # Create a combined status object for Ninja
        $combinedStatus = @{
            VirtualDiskInfo     = $vdiskinfo
            PhysicalDiskSummary = $diskSummary
            SmartStatus         = @{
                Disk0 = $physical_disk0_smart_info.'SMART STATUS'
                Disk1 = $physical_disk1_smart_info.'SMART STATUS'
            }
        }

        # make new variable to store pertinent statusinfo
        $statusReportedtoNinja = "Last Updated: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')`nVirtual Disk Status:$($vdiskinfo.Status) `nDisk 0 SMART Status:$($physical_disk0_smart_info.'SMART STATUS') `nDisk 1 SMART Status:$($physical_disk1_smart_info.'SMART STATUS') "

        # Set the combined status
        $combinedStatusJson = $combinedStatus | ConvertTo-Json -Depth 10

        # Set the bosscardstatus status in Ninja
        Ninja-Property-Set bosscardstatus $statusReportedtoNinja

        # Return to original directory
        Pop-Location
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
else {
    Write-Host "No DellBOSS card found in the system"
    Ninja-Property-Set bosscardfound "Not Found"
    exit 1
}