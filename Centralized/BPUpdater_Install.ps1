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

#set location to wherever script has run from, need this to copy files to target directory
Push-Location

#copy script into programdata folder

#set up dir, and share name
$ProgDataDir = $env:ALLUSERSPROFILE + "\BPUpdater"
$PBSDataDir = $ProgDataDir + "\PBSData"
$LogDir = $ProgDataDir + "\Log"
$ScriptLocation = $ProgDataDir + "\BP_PBS_Updater.ps1"
$PBSShareName = "PBSData$"
$MachineName = HOSTNAME.EXE
$ShareUNC = "\\" + $MachineName + "\" + $PBSShareName

#tests if program data path exists, if not creates it and subfolders
IF (!(Test-Path -Path $ProgDataDir)) {
    New-Item -ItemType Directory -Path $ProgDataDir
    New-Item -ItemType Directory -Path $PBSDataDir
    New-Item -ItemType Directory -Path $LogDir
    Copy-Item -Path .\BP_PBS_Updater.ps1 -Destination $ProgDataDir
    
}

#scheduled task paramaters 
$TaskName = "BPUpdater_Daily_2AM"
$TaskAction = New-ScheduledTaskAction -Execute Powershell.exe -Argument "PowerShell -ExecutionPolicy Bypass -File $($ScriptLocation) -NonInteractive"
$TaskTrigger = New-ScheduledTaskTrigger -Daily -At 2AM
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest 
Register-ScheduledTask -TaskName $TaskName -Principal $TaskPrincipal -Trigger $TaskTrigger -Action $TaskAction -Force
#checks, if not found will create share out of $PBSDataDir (admin share)
if (!(Test-Path $ShareUNC)) {
    New-SmbShare -Name $PBSShareName -Path $PBSDataDir -Description "Admin Share for PBS Data Update Files" -ReadAccess "Everybody"
}