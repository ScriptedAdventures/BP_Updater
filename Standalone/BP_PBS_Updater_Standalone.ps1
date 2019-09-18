<#
.Synopsis

Checks all objects with the "links.href" property on the BPSoftware Premier Downloads Page
Finds the newest update by selecting strings containing "inc.exe" (inc = incremental)
Selects first result, stores in variable (BP Use a YYMMDD format for the updates, latest update will always be the highest number)
Download file from URI to C:\TEMP\BPDrugUpdates\PBSData
#>

<#
.Author

Matthew Russell
https://github.com/ScriptedAdventures
https://www.scriptedadventures.net/

#>


# Prepare Default Variables
$RunDate = Get-Date -Format ddMMyy
$Hostname = HOSTNAME.EXE
$LogName = "Log.file"
$InstallDir = "C:\ProgramData\BPUpdater\"
$LogDir = $InstallDir + "Log\"
$LogFile = $LogDir + $LogName
$PBSVerLogName = "PBSVersionReport" + ".csv"
$PBSFolder = $InstallDir + "PBSData\"
$PBSVerLog = $LogDir + $PBSVerLogName
$DLPageBP = "https://bpsoftware.net/resources/bp-premier-downloads/"

IF (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir
}

IF (!(Test-Path $PBSFolder)) {
    New-Item -ItemType Directory $PBSFolder
}

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
$functionTime = Get-Date -Format g 
Add-Content $LogFile "$functionTime > Adding TLS 1.1 & 1.2 to allow communication with BPSoftware.net"
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls11 ;

# Create empty table for recording
$Table = @()

# Create Ordered Hashtable for data collection
$Record = [ordered] @{
    "Run Date" = ""
    "PBS Update Version" = ""
    "Needs Update" = ""
    "Update Downloaded" = ""
    "Install Run" = ""
}

# Function to get Current PBS Version
function Get-PBSVersion {
    Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Best Practice Software\Best Practice\General" -Name "PBS"
}
$functionTime = Get-Date -Format g 
Add-Content $LogFile "$functionTime > Checking $DLPageBP for Updates"
$DLQuery = @((Invoke-WebRequest $DLPageBP ).links.href | Select-String -Pattern "inc.exe")
$DLQResult = $DLQuery | Select-Object -First 1
$FileName = Split-Path $DLQResult -Leaf
$OutFile = $PBSFolder + $FileName
$functionTime = Get-Date -Format g
Add-Content $LogFile "$functionTime > Update Found at $DLQResult"

#Clean up version number for comparison
$Clean1 = $FileName -replace "BPS_Data_" , ""
$Clean2 = $Clean1 -replace "_inc.exe" , ""
$LatestVersion = $($Clean2)

IF (!(Test-Path $OutFile)) { 
    $functionTime = Get-Date -Format g
    $DLStartTime = Get-Date
    Add-Content $LogFile "$functionTime > $FileName Download Started "
    (New-Object System.Net.WebClient).DownloadFile("$DLQResult" , "$OutFile")
    Add-Content $LogFile "$functionTime > $FileName SUCCESS: Download Completed in $((Get-Date).subtract($DLStartTime).seconds) Second(s) "
    $Record["Update Downloaded"] = "Yes"
}

$functionTime = Get-Date -Format g 
Add-Content $LogFile "$functionTime > Querying Currently installed PBSData Version"
$PBSVersion = Get-PBSVersion
Add-Content $LogFile "$functionTime > Found PBSVersion to be $PBSVersion.PBS"
IF ($PBSVersion -match $LatestVersion) {
    $NeedsUpdate = "No"
} ELSE {
    $NeedsUpdate = "Yes"
}
$Record["Run Date"] = $RunDate
$Record["PBS Update Version"] = $PBSVersion.PBS
$Record["Needs Update"] = $($NeedsUpdate)
IF ($NeedsUpdate -match "Yes") {
    $functionTime = Get-Date -Format g 
    Add-Content $LogFile "$functionTime > Installing Update"
    Start-Process "$OutFile" -ArgumentList "/s" -Wait
    $functionTime1 = Get-Date -Format g 
    Add-Content $LogFile "$functionTime1 > Installation Completed"
    $Record["Install Run"] = $functionTime
}
$objRecord = New-Object PSObject -Property $Record
$Table += $objRecord

$Table | Export-CSV -Path ($($PBSVerLog)) -NoClobber -NoTypeInformation -Append