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
$Principal = New-ScheduledTaskPrincipal -GroupId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest 
Register-ScheduledTask -TaskName "BPUpdater_Daily_2AM" -Principal $Principal -Trigger $Trigger -Action $Action -AsJob -RunLevel Highest -Force
#checks, if not found will create share out of $PBSDataDir (admin share)
if(!(Test-Path $ShareUNC)){
    New-SmbShare -Name $PBSShareName -Path $PBSDataDir -Description "Admin Share for PBS Data Update Files" 
}