$ESXiHost = Ninja-Property-Get vmwaredelegatehostip
$Username = "root" # or your ESXi username
$KeyPath = "$env:SystemDrive\your_path\ssh_key\esxi_key"
$hostname = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "esxcli system hostname get"
$network = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "esxcli network ip interface ipv4 get"
$hostname = $hostname | Select-String "Fully Qualified Domain Name:"
$hostname = $hostname.Line.Trim()
$cleanhostname = ($hostname -split "Fully Qualified Domain Name: ")[1]
$ip = $network.get(2)
$ip = $ip.Split("  ") | Select-Object -Index 2

# Check which RAID CLI tool is available
$raidTool = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "ls /opt/lsi"

# Initialize the command variable
$raidCommand = ""

# Set the appropriate command based on the available tool
if ($raidTool -match "storcli") {
    $raidCommand = "./storcli"
} elseif ($raidTool -match "perccli64") {
    $raidCommand = "./perccli64"
} elseif ($raidTool -match "perccli") {
    $raidCommand = "./perccli"
}
else {
    Write-Error "No supported RAID CLI tool found in /opt/lsi"
    exit 1
}

# Store the full command for later use
$fullRaidCommand = "$raidCommand /c0 show J"

$raidStatus = ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" "cd /opt/lsi/$raidcommand && $fullRaidCommand"

# Create the data structure with metadata
$result = @{
    metadata = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        hostname = $ESXiHost
        host_ip = $ip
        orgname = $env:NINJA_ORGANIZATION_NAME
        hostnamefqdn = $cleanhostname
    }
    data = $raidStatus | ConvertFrom-Json
}

# Convert to JSON
$jsonBody = $result | ConvertTo-Json -Depth 10

# Get webhook URL from Ninja
$webhookUrl = Ninja-Property-Get rewstlocationRaidWebhookUrl

# Set headers for the request
$headers = @{
    "Content-Type" = "application/json"
}

# Send the request
$response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $jsonBody -Headers $headers