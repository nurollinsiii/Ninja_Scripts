# General Info
# What is this?
# This is a means to check a vmware host individual card status using a language that speaks directly with the raid controller. This has been automated using ImageNet's tool stack

# Tools used:
# NinjaOne Rmm
# Rewst

# Optional tools that may be used:
# WinSCP
# Azure blob (anon access)
# Pre-reqs
# Before starting, please check the following:
# Company is added fully in Rewst
# you have ample servers (NOT DOMAIN CONTROLLERS), jboxes, or bdraas's to accommodate you being able to run this script as it will be a 1:1 ratio in machine to vmware host that runs this script.
# Automated process
# Delegate Device steps
# Depending on what type of device it is you will want to make the device role one of the following that should give you the proper custom field in ninja to signify that whatever particular device we are using points to our specific vmwarehost ip. The Custom Field name is "vmwaredelegatehostip"

# Server
# Server - ImageNet BDR Server
# Server - Virtual Machine
# Workstation
# Wrkstn - JumpBox
# Windows VmwareHost Delegate
# Esxi pwless login steps
# IMPORTANT NOTE: Do not do this on a domain controller, you will have to use a local administrator account & this will not work with a domain administrator account. 

# Steps:

# Log into Esxi host
# Change directory to
# cd /usr/lib/vmware/openssh/bin
# Run command to create both public and private key
# [root@zckl-vsrv-101:/usr/lib/vmware/openssh/bin]  ./ssh-keygen -t rsa -f ~/.ssh/esxi_key -N ""
# You might need to create the ~/.ssh directory first
# Add the public key to "authorized keys"
# [root@zckl-vsrv-101:/etc/ssh/keys-root] cp //.ssh/esxi_key.pub /etc/ssh/keys-root/authorized_keys
# Restart SSH service
# [root@zckl-vsrv-101:/etc/ssh/keys-root] /etc/init.d/SSH restart
# Copy the private key to data store to then download to your delegate machine
#  [root@zckl-vsrv-101:~] cp //.ssh/esxi_key /your_local_path/esxi_key
# Remove permissions from private key if needed
# I had to remove "everyone" & "authenticated users", then add my specific user to the permission. This probably would have been mitigated by copying the private key to my windows users "/.ssh/" location
# Powershell from delegate machine
# $ESXiHost = "yourHostMachineIP"
# $Username = "yourHostMachineUsername" # or your ESXi username
# $KeyPath = "C:\Imagenet\ssh_key\esxi_key" # Path to your private key file
# Try to SSH into esxi host from delegate
# ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}" 
# Wi ndows PowerShe11 
# Copyright (C) Microsoft Corporation. All rights reserved. 
# PS C: ssh root-@172. 
# 17.2.2Ø 
# (root@172.17.2.2ø) password: 
# The time and date of this login have 
# been sent to the system logs. 
# Vhware offers supported, powerful system administration tools. Please 
# see For details. 
# The ESXi Shell can be disabled by an administrative user. See the 
# '"Sphere Security documentation for more information. 
# Croot@localhost:—] cd lusr/lib/vmware/openssh/bin 
# ./ssh-keygen -t rsa -f . ssh/esxi_key -N 
# Generating publ rsa key pair. 
# directory 'I/ .ssh' . 
# tYour identification has been saved in // . ssh/esxi_key. 
# Your public key has been saved in .ssh/esxi_key. pub. 
# The key fingerprint is: 
# . local 
# The key's randomart image is: 
# oooX.@ * 
# 0 
# . .00 
# --[SHA2561--- 
# cp //.ssh/esxi_key.pub /etc/ssh/keys-root/authorized_keys 
# /etc/init .d/SSH restart 
# SSH login disabled 
# SSH login enabled 
# : I usr/ 1 ib/vmuare/openssh/bi n]



# supporting documents: https://knowledge.broadcom.com/external/article/313767/allowing-ssh-access-to-vmware-vsphere-es.html

# Vmware Physical disk investigation
# SSH into vmware host
# Can do this by hitting a delegate machine then launching a cmd and running the "ssh root@ipaddress"
# You might also have to ssh a different way if ssh-rsa,ssh-dss is enable by running "ssh -oHostKeyAlgorithms=+ssh-rsa root@ipaddress"
# Check the information about mounted VMFS volumes:
# "esxcli storage vmfs extent list"
# List all storage devices and locate the unique device name
# "esxcli storage core device list"
# Check to see what "vibs" are installed?
# "esxcli software vib list"
# You are going to want to look for you specific raid adapter vib
# Assuming your vib isn't there, you will next create a temp directory
# Mkdir name
# Download the zipped file
# Wget "urlToGetYourFile.com"
# I currently have the .tar.gz file on an Azure ImageNet Storage account via anonymous blob which worked for one machine and not for another so I had to manually upload it to the datastore
# Or you can download the file on a machine that has host level access, and upload it to the datastore manually.
# Or you may need to do so by using WinSCP. You can use that program to transfer the files.
# Unzip the zipped file
# "tar -xf theZippedFiles.tar.gz  -C /path_you_want/"
# Install the vib
# "esxcli software vib install -d /full_path/to_your/file.vib"
# Use the commands
# Change you directory by going to "/opt/lsi"
# From here you will find either storcli / perccli etc
# Example
# "./storcli /c0 show J"
 

# handy vib list and helpful docs
# Url:

#  Manage PERCCLI / good info:

# https://vmadminthoughts.wordpress.com/2020/10/26/manage-perc-controller-from-cli-on-esxi/

#  VMware PERCCLI Utility For All Dell HBA/PERC Controllers: https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=17ngt

# DELL OMSA download: https://www.dell.com/support/home/en-us/drivers/driversdetails?driverId=82C83

# Useful / help doc on esxcli: https://www.nakivo.com/blog/most-useful-esxcli-esxi-shell-commands-vmware-environment/

# PERCCLI tar download on Imagenet Strg acct: https://imagenetmit.blob.core.windows.net/sec-stack-installers/PERCCLI_4H10X_7.1327.0_A09_VMware.tar.gz

# Dell PERCCLI download:

# https://www.dell.com/support/home/en-ca/drivers/driversdetails?driverid=4h10x

# STORCLI for vmware: https://datacentersupport.lenovo.com/us/en/products/servers/system-x/system-x3650-m5/8871/8871ac1/j11ghgg/downloads/ds505424-storcli-command-line-tool-for-vmware

# MEGARAID StorCLI:

# https://techdocs.broadcom.com/us/en/storage-and-ethernet-connectivity/enterprise-storage-solutions/storcli-12gbs-megaraid-tri-mode/1-0/v11869215/v11673477.html

# MEGA CLI:

# https://www.broadcom.com/support/knowledgebase/1211161501080/capturing-lsiget-under-esx-server

# HP Smart array cli commands: https://www.cloudhosting.lv/eng/faq/HP-Smart-array-CLI-commands

# Rewst Steps
# Rewst steps to get webhook URL
# Ensure the customer is full on setup in rewst before proceeding
# Log into Rewst & go to the workflows section
# select this workflow - "Vmware Normal health reporting & ticket creation"
# select the Trigger settings cog button at the top right

# then scroll down to the bottom section "Activate Trigger To Run For" & select inside of the box to then add your new company

# Click Submit
# Then scroll back up in the same section to the "Trigger Configuration" and click the "View Webhook URLs" button to see what your webhook urls are

# Copy and paste this into the "rewstlocationRaidWebhookUrl" Custom Field. See more below.
# Ninja Steps
# add your local account password to ninja
# You will need to go to your organization in Ninja under the Administration -> Organization & then go to the credentials section

# Here you will add 2 different sets of credentials.
# Local Administrator
# vmware host credentials
# Then you will want to make sure you switch to the "Defaults" section under the credentials & ensure you have selected your new local admin creds for the "Windows Script Local Admin" option

# add vmware host as a device in ninja
# To add the vmware host device to ninja do the following:

# Log into NinjaOne RMM
# Click the top right + button to add a new device to Ninja & click the "add device" then the "Virtual Infrastructure" button

# Then you will need to fill out the info requested. Below is an example of what I used for Ryan Whaley's .11 vmware host. This assumes you have already added the credentials to the organization. If you have not added the credentials, please see the section above "add your local account password to ninja" to do so.

# Then you will want to Test host -> then Add host if it comes back successful.
# Ninja Custom Field edits
# You will need to add a few things to ninja custom fields. First you will need to add the "vmwaredelegatehostip" information. Then you will need to add the "rewstlocationRaidWebhookUrl" to your location.

# "vmwaredelegatehostip" steps:
# This is to be used by the device that will run the scripts and log into the host via passwordless ssh.
# go to that device in ninja and navigate to the Custom Fields section for your device.
# then you will want to minimize the global custom fields, and go to your role based custom fields and look for the "vmwaredelegatehostip"

# You will then want to plug in your ip of the esxi host you want to target
# if you don't see this custom field, it is likely because you havn't given your delegate machine the proper custom role. Please see the "Delegate Device steps" section for more info on this

# "rewstlocationRaidWebhookUrl" steps:
# Here you will want to go to the organization from the regular dashboard view
# then you will want to go to the Custome Field section at the top
# From here you will want to add the proper rewst webhook url to the location section Custom Field named "rewstlocationRaidWebhookUrl", NOT the organizational section

# Test / dry-run
# By this point you should
# have your device selected to use as a delegate
# have both custom fields filled out
# your administration credentials filled in for your org & the defaults set
# the vmware host added in NinjaOne
# The "esxi_key" in the proper location with the proper settings

# Now you can do a dry run. PLEASE EDIT THIS TO YOUR SPECIFICS BELOW.
# log into your delegate machine with your local administrator account
# Open up powersehll NOT AS AN ADMINISTRATOR ACCOUNT and run the follwing with your own supplied info
# #change for your own info
# $ESXiHost = "plugInYourEsxiHostIP"
# $Username = "root" # or your ESXi username
# $KeyPath = "C:\Imagenet\ssh_key\esxi_key"

# ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -i $KeyPath "${Username}@${ESXiHost}"
# If this logs you in, then you move to the next step. If not, please see the above section "Esxi pwless login steps"
# The actual ninja script that we will want to run is the "get-NormalVMwareRaidHealth" script in ninja. You will now want to run this script to ensure that it comes back all clear. At the end of this script, you should just see a "SUCCESS" but if you go to your esxi host device in ninja, and go to the custom fields, you should see some new information that has been pulled and loaded relating to the physical & virtual disks health.
# if this script runs & gets an Error 1326: Know that this means that The username or password is incorrect
# add delegate machine to ninja task
# After the dry run is good and you get your expected data, we want to add this delegate machine to the automation that will check daily. To do this you will do the following:

# Log into NinjaOne RMM
# go to Administration -> Tasks
# select this task "get-NormalVmwareRaidHealth"
# go to the Targets section on the left
# then add your desired delegate machine accordingly
## END OF DOCUMENTATION

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