<#
.Synopsis
Creates Scheduled Task for running BPUpdater. This runs Daily at 11PM, however this can be changed by changing $ScheduleExecuteTime
#>

<#
.Author

Matthew Russell
https://github.com/ScriptedAdventures
https://www.scriptedadventures.net/
#>

Import-Module ActiveDirectory

#Password Generator
function Make-Password {
    $PasswordSamplesArray = "!@#$%^&*()1234567890qwertyuiopasdfghjklzxcvbnm;,./{}:<>?".tochararray()
    $PasswordOut = (($PasswordSamplesArray | Get-Random -Count '24') -join '')
    return $PasswordOut
    }
$ADPassword = Make-Password

#AD User Creation for Scheduled Task
$ADUserName = "BPUpdater.svc"
$ADDescription = "Service Account For BPUpdater Scheduled Task"
$ADDisplayName = "BP Updater Service Account"
$ADUser = $env:USERDNSDOMAIN + $ADUserName

New-ADUser -Name $ADUserName -AccountPassword $ADPassword -Description $ADDescription -DisplayName $ADDisplayName -PasswordNeverExpires
Add-ADGroupMember -Identity "Domain Admins" -Members $ADUserName

#set up dir, and share name
$ProgDataDir = $env:ALLUSERSPROFILE + "\BPUpdater"
$PBSDataDir = $ProgDataDir + "\PBSData"
$LogDir = $ProgDataDir + "\Log"
$ScriptLocation = $ProgDataDir + "\BP_PBS_Updater.ps1"
$PBSShareName = "PBSData$"
$MachineName = hostname
$ShareUNC = "\\" + $MachineName + "\" + $PBSShareName

#scheduled task paramaters 
$Action = New-ScheduledTaskAction -Execute $($ScriptLocation)
$Trigger = New-ScheduledTaskTrigger -Daily -At 2AM
$Principal = $ADUser
Register-ScheduledTask -TaskName "BPUpdater Daily" -Trigger $Trigger -User $Principal -Action $Action


#checks, if not found will create share out of $PBSDataDir (admin share)
if(!(Test-Path $ShareUNC)){
    New-SmbShare -Name $PBSShareName -Path $PBSDataDir -Description "Admin Share for PBS Data Update Files" 
}


