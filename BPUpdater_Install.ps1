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

#set up dir
$ProgDataDir = $env:ALLUSERSPROFILE + "\BPUpdater"
$PBSDataDir = $ProgDataDir + "\PBSData"
$LogDir = $ProgDataDir + "\Log"
$ScriptLocation = $ProgDataDir + "\BP_PBS_Updater.ps1"

#other information
$PBSShareName = "PBSData$"

#scheduled task paramaters 
$ScheduledAction = New-ScheduledTaskAction -Execute $($ScriptLocation)
$ScheduledTrigger = New-ScheduledTaskTrigger -Daily -At 2AM


#create share out of $PBSDataDir (admin share)
New-SmbShare -Name $PBSShareName -Path $PBSDataDir -Description "Admin Share for PBS Data Update Files" 


