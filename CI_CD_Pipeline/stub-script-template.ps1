#2/27/2025
#https://github.com/COMPANY/DATA/SCRIPT_NAME.ps1
#MUST RUN Get-GithubScript.ps1 first to retrieve this script.  
#This script will run the [Confirm-Windows11UpdateLogic.ps1] script and then remove it from the system.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('IncludedCheck', 'EligibleCheck', 'OrgEnabledCheck', 'ValidScheduleCheck', 'RunAllChecks')]
    [string]$Check
)

$scriptPath = "$env:systemdrive/COMPANY/DATA/SCRIPT_NAME.ps1"
$arguments = "-File `"$scriptPath`" -Check `"$Check`""
$result = Start-Process powershell.exe -ArgumentList $arguments -Wait -PassThru
Remove-Item -Path $scriptPath -Force
exit $result.ExitCode
