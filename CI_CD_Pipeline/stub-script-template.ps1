#    Windows 11 Upgrade Checks
#
#Author: Neal Rollins, John Stringer
#2/27/2025
#https://github.com/COMPANYmit/ninja-scripts/blob/main/Utility_scripts/Windows11/Confirm-Windows11UpdateLogic.ps1
#MUST RUN Get-GithubScript.ps1 first to retrieve this script.  
#This script will run the [Confirm-Windows11UpdateLogic.ps1] script and then remove it from the system.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('IncludedCheck', 'EligibleCheck', 'OrgEnabledCheck', 'ValidScheduleCheck', 'RunAllChecks')]
    [string]$Check
)
#scriptpath.. add this as an environment variable in ninja & plug in the script path from github
$scriptPath = $env:githubScriptPath
#run get-githubscript.ps1 to get the script
& "$env:systemdrive\COMPANY\scripts\get-githubscript.ps1" -scriptPath $scriptPath

$scriptPath = "$env:systemdrive\COMPANY\scripts\Confirm-Windows11UpdateLogic.ps1"
$arguments = "-File `"$scriptPath`" -Check `"$Check`""
$result = Start-Process powershell.exe -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\win11check_output.txt" -RedirectStandardError "$env:TEMP\win11check_error.txt"

# Display the output
Write-Host "`n=== Windows 11 Check Output ==="
Get-Content "$env:TEMP\win11check_output.txt"
Write-Host "`n=== Windows 11 Check Errors ==="
Get-Content "$env:TEMP\win11check_error.txt"

# Clean up
Remove-Item -Path $scriptPath -Force
Remove-Item -Path "$env:TEMP\win11check_output.txt" -Force
Remove-Item -Path "$env:TEMP\win11check_error.txt" -Force

exit $result.ExitCode