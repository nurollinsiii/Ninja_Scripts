# Function to parse HP Smart Array output to JSON
function Convert-HPArrayToJson {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [object[]]$inputText
    )

    # Initialize the main object with ordered hashtables
    $result = [ordered]@{
        controller = [ordered]@{
            name = ""
            serial = ""
            arrays = @()
        }
    }

    # First pass: Categorize lines
    $categories = @{
        controller = @()
        arrays = @()
        logicaldrives = @()
        physicaldrives = @()
    }

    $currentArray = $null
    # Process each line directly from input array
    foreach ($line in $inputText) {
        $line = $line.ToString().Trim()
        
        if ($line -match 'Smart Array') {
            $categories.controller += $line
        }
        elseif ($line -match '^array [A-Z]') {
            $categories.arrays += $line
            # Store which array this is for the next drives
            if ($line -match 'array ([A-Z])') {
                $currentArray = $matches[1]
            }
        }
        elseif ($line -match '^logicaldrive') {
            # Add array letter to the line for later processing
            $categories.logicaldrives += "$currentArray|$line"
        }
        elseif ($line -match '^physicaldrive') {
            # Add array letter to the line for later processing
            $categories.physicaldrives += "$currentArray|$line"
        }
    }

    # Parse controller info
    if ($categories.controller[0] -match '(Smart Array.*?)\s*\(sn:\s*([\w]+)\)') {
        $result.controller.name = $matches[1].Trim()
        $result.controller.serial = $matches[2].Trim()
    }

    # Process arrays and create the structure
    foreach ($arrayLine in $categories.arrays) {
        if ($arrayLine -match '^array ([A-Z])\s*\((.*?),\s*Unused Space:\s*(\d+)\s*MB\)') {
            $arrayName = $matches[1]
            
            # Create array with ordered properties
            $array = [ordered]@{
                name = $arrayName
                type = $matches[2]
                unusedSpace = "$($matches[3]) MB"
                arrays = @()
                logicalDrives = @()
                physicalDrives = @()
            }

            # Add logical drives for this array
            $arrayLogicalDrives = $categories.logicaldrives | Where-Object { $_.StartsWith("$arrayName|") }
            $arrayPhysicalDrives = $categories.physicaldrives | Where-Object { $_.StartsWith("$arrayName|") }

            foreach ($driveLine in $arrayLogicalDrives) {
                $line = $driveLine.Split('|')[1]
                
                if ($line -match 'logicaldrive\s+(\d+)\s*\(([\d.]+)\s*GB,\s*RAID\s*(\d+),\s*(\w+)\)') {
                    # Store matches in variables first
                    $driveId = $matches[1].ToString()
                    $driveSize = $matches[2].ToString()
                    $driveRaid = $matches[3].ToString()
                    $driveStatus = $matches[4].ToString()

                    # Count physical drives for this array (excluding spares)
                    $driveCount = ($arrayPhysicalDrives | Where-Object { 
                        $_ -notmatch 'spare' 
                    }).Count

                    # Create drive object using stored values
                    $logicalDrive = [ordered]@{
                        id = $driveId
                        size = "$driveSize GB"
                        raidLevel = $driveRaid
                        status = $driveStatus
                        driveCount = $driveCount
                    }

                    $array.logicalDrives += $logicalDrive
                }
            }

            # Add physical drives for this array
            foreach ($driveLine in $arrayPhysicalDrives) {
                $line = $driveLine.Split('|')[1]
                if ($line -match 'physicaldrive\s+([\w:]+)\s*\(port\s+([\w:]+:[^,]+),\s*(.*?),\s*([\d.]+)\s*(?:GB|TB),\s*([^)]*)\)') {
                    $array.physicalDrives += [ordered]@{
                        id = $matches[1]
                        port = $matches[2]
                        type = $matches[3]
                        size = "$($matches[4]) " + $(if ($line -match 'TB') { "TB" } else { "GB" })
                        status = if ($matches[5]) { 
                            # If it's a spare drive, clean up the status to not show "OK, spare"
                            $status = $matches[5].Trim()
                            if ($line -match 'spare' -and $status -eq "OK, spare") {
                                "OK"
                            } else {
                                $status
                            }
                        } else { 
                            "OK" 
                        }
                        spare = $line -match 'spare'
                    }
                }
            }

            # Remove empty arrays property
            $array.Remove('arrays')

            $result.controller.arrays += $array
        }
    }

    return $result | ConvertTo-Json -Depth 10
}

# Add this function after the Convert-HPArrayToJson function

function Convert-ArrayDataToHtml {
    param (
        [Parameter(Mandatory = $true)]
        [string]$JsonData
    )

    $data = $JsonData | ConvertFrom-Json
    $sb = New-Object System.Text.StringBuilder

    # Start with metadata - using Ninja-supported styles
    [void]$sb.AppendLine('<div style="margin-bottom: 20px;">')
    [void]$sb.AppendLine('<h2 style="color: #2c3e50; margin-bottom: 10px;">RAID Array Status</h2>')
    [void]$sb.AppendLine('<div style="background-color: #f8f9fa; padding: 10px; border: 1px solid #dee2e6; border-radius: 4px;">')
    [void]$sb.AppendLine("<p><strong>Hostname:</strong> <span style='color: #0056b3;'>$($data.metadata.hostname)</span></p>")
    [void]$sb.AppendLine("<p><strong>Timestamp:</strong> $($data.metadata.timestamp)</p>")
    [void]$sb.AppendLine("<p><strong>Controller:</strong> <span style='color: #0056b3;'>$($data.data.controller.name)</span></p>")
    [void]$sb.AppendLine('</div></div>')

    # For each array
    foreach ($array in $data.data.controller.arrays) {
        [void]$sb.AppendLine("<h3 style='color: #2c3e50; margin-top: 20px;'>Array $($array.name)</h3>")
        [void]$sb.AppendLine("<p style='margin-bottom: 10px;'>Type: <span style='color: #0056b3;'>$($array.type)</span>, Unused Space: $($array.unusedSpace)</p>")

        # Logical Drives Table
        if ($array.logicalDrives.Count -gt 0) {
            [void]$sb.AppendLine('<div style="margin-bottom: 20px;">')
            [void]$sb.AppendLine('<h4 style="color: #495057;">Logical Drives</h4>')
            [void]$sb.AppendLine('<table style="width: 100%; border-collapse: collapse; margin-bottom: 10px;">')
            [void]$sb.AppendLine('<thead><tr style="background-color: #e9ecef;">')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">ID</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Size</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">RAID Level</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Status</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Drive Count</th>')
            [void]$sb.AppendLine('</tr></thead><tbody>')
            
            foreach ($ld in $array.logicalDrives) {
                # Color coding for status
                $statusColor = switch ($ld.status) {
                    "OK" { "#28a745" }  # Green for OK
                    "Degraded" { "#ffc107" }  # Yellow for Degraded
                    "Failed" { "#dc3545" }  # Red for Failed
                    default { "#6c757d" }  # Gray for unknown
                }
                $bgColor = if ($ld.status -ne "OK") { "#fff3cd" } else { "#ffffff" }
                
                [void]$sb.AppendLine("<tr style='background-color: $bgColor;'>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($ld.id)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($ld.size)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>RAID $($ld.raidLevel)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px; color: $statusColor; font-weight: bold;'>$($ld.status)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($ld.driveCount)</td>")
                [void]$sb.AppendLine('</tr>')
            }
            [void]$sb.AppendLine('</tbody></table></div>')
        }

        # Physical Drives Table
        if ($array.physicalDrives.Count -gt 0) {
            [void]$sb.AppendLine('<div style="margin-bottom: 20px;">')
            [void]$sb.AppendLine('<h4 style="color: #495057;">Physical Drives</h4>')
            [void]$sb.AppendLine('<table style="width: 100%; border-collapse: collapse; margin-bottom: 10px;">')
            [void]$sb.AppendLine('<thead><tr style="background-color: #e9ecef;">')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">ID</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Port</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Type</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Size</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Status</th>')
            [void]$sb.AppendLine('<th style="border: 1px solid #dee2e6; padding: 8px; text-align: left; color: #495057;">Spare</th>')
            [void]$sb.AppendLine('</tr></thead><tbody>')
            
            foreach ($pd in $array.physicalDrives) {
                # Color coding for status
                $statusColor = switch ($pd.status) {
                    "OK" { "#28a745" }  # Green for OK
                    "Degraded" { "#ffc107" }  # Yellow for Degraded
                    "Failed" { "#dc3545" }  # Red for Failed
                    default { "#6c757d" }  # Gray for unknown
                }
                $bgColor = if ($pd.status -ne "OK") { "#fff3cd" } else { "#ffffff" }
                
                [void]$sb.AppendLine("<tr style='background-color: $bgColor;'>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($pd.id)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($pd.port)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($pd.type)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px;'>$($pd.size)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px; color: $statusColor; font-weight: bold;'>$($pd.status)</td>")
                [void]$sb.AppendLine("<td style='border: 1px solid #dee2e6; padding: 8px; color: $(if ($pd.spare) { '#0056b3' } else { '#6c757d' });'>$(if ($pd.spare) { '✓' } else { '−' })</td>")
                [void]$sb.AppendLine('</tr>')
            }
            [void]$sb.AppendLine('</tbody></table></div>')
        }
    }

    return $sb.ToString()
}
#$sshprivkey = ninja-property-get sshprivatekey
#$sshprivkey | out-file -path "$env:SystemDrive\ImageNet\ssh_key\sshprivatekey"
#$ESXiHost = "192.168.100.120"
$ESXiHost = $env:host_ip
$Username = "root" # or your ESXi username
$KeyPath = "$env:SystemDrive\ImageNet\ssh_key\sshprivatekey"
#$KeyPath = "$env:SystemDrive\ImageNet\ssh_key\esxi_key" 
$output = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "/opt/hp/hpssacli/bin/hpssacli ctrl all show config"
$hostname = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "esxcli system hostname get"
$network = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "esxcli network ip interface ipv4 get"
$hostname = $hostname | Select-String "Fully Qualified Domain Name:"
$hostname = $hostname.Line.Trim()
$cleanhostname = ($hostname -split "Fully Qualified Domain Name: ")[1]
$ip = $network.get(2)
$ip = $ip.Split("  ") | Select-Object -Index 2
#write-host $output
#Write-Host $network

# Get the JSON from the function
$arrayData = Convert-HPArrayToJson($output)
#write-host $arrayData
# Create the final structure with metadata
$result = @{
    metadata = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        hostname = $ESXiHost
        host_ip = $ip
        orgname = $env:NINJA_ORGANIZATION_NAME
        hostnamefqdn = $cleanhostname
    }
    data = $arrayData | ConvertFrom-Json
}

# Convert the final structure to JSON
$jsonBody = $result | ConvertTo-Json -Depth 10

# Example usage:
#$htmlOutput = Convert-ArrayDataToHtml -JsonData $json
#Ninja-Property-Set raidtablestatus $htmlOutput


# Send to webhook
$webhookUrl = Ninja-Property-get rewstlocationRaidWebhookUrl
$headers = @{
    "Content-Type" = "application/json"
}

# Send the request
$response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $jsonBody -Headers $headers