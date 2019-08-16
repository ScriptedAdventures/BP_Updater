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
$global:CentralServerName = "\\" + $Hostname + "\"
$global:InstallDir = $env:ALLUSERSPROFILE + "\" + "BPUpdater\"
$global:Dir = $global:InstallDir + "BPDrugUpdates\"
$LogName = "Log.file"
$LogDir = $global:InstallDir + "Log\"
$LogFile = $LogDir + $LogName
$PBSVerLogName = "PBSVersionReport" + "_" + $RunDate + ".csv"
$PBSFolder = $global:InstallDir + "PBSData\"
$global:PBSUpdates = $PBSFolder
$BPU_ShareName = "PBSData$\"
$BPU_SharePath = $PBSFolder
$TargetMachineADGroup = "BPAutoUpdate"
$global:TargetMachines = Get-ADGroupMember -Identity $TargetMachineADGroup
$PBSVerLog = $LogDir + $PBSVerLogName
$global:PBSDataServ = $global:CentralServerName + $BPU_ShareName
$global:DLPageBP = "https://bpsoftware.net/resources/bp-premier-downloads/"

$global:PBSDir = $PBSFolder
IF (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir
}
IF (!(Test-Path $global:PBSDir)) {
    New-Item -ItemType Directory -Path $global:PBSDir
}

# Set up environment for script to run in, installs necessary modules
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
Import-Module ActiveDirectory
# Enable TLS1.1 and TLS1.2 to allow communication with bpsoftware.net
$functionTime = Get-Date -Format g 
Add-Content $LogFile "$functionTime > Adding TLS 1.1 & 1.2 to allow communication with BPSoftware.net"
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls11 ;

# Create empty array for recording
$global:Table = @()
# Create Ordered Hashtable for data collection
$Record = [ordered] @{
    "Server"             = ""
    "PBS Update Version" = ""
    "Needs Update"       = ""
    "Files Sent"         = ""
    "Install Sent"       = ""
    "Error"              = ""
}

# Creates Function for querying current PBSVersion
function Get-PBSVersion {
    Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Best Practice Software\Best Practice\General" -Name "PBS"
}

# Query if paths exists, if it does not, creates it
If (!(Test-Path $global:Dir)) {
    $functionTime = Get-Date -Format g 
    New-Item -ItemType Directory -Force -Path $global:Dir
    Add-Content $LogFile "$functionTime > WARNING: Directory $($global:Dir) Not Found, Created automatically"
}
else {
    $functionTime = Get-Date -Format g
    Add-Content $LogFile "$functionTime > Directory $($global:Dir) OK"
}

# Query all links on site that contain inc.exe, save uri in variable and split path to set filename in a variable
$functionTime = Get-Date -Format g
Add-Content $LogFile "$functionTime > Checking $global:DLPageBP for Updates"
$DLQuery = @((Invoke-WebRequest $global:DLPageBP ).links.href | Select-String -Pattern "inc.exe")
$DLQResult = $DLQuery | Select-Object -First 1
$global:FileName = Split-Path $URI -Leaf
$OutFile = $PBSFolder + $global:FileName
$functionTime = Get-Date -Format g
Add-Content $LogFile "$functionTime > Found Update At $URI "

# Clean up version number for comparison
$Clean1 = $global:FileName -replace "BPS_Data_" , ""
$Clean2 = $Clean1 -replace "_inc.exe" , ""
$global:LatestVersion = $($Clean2)

# Downloads Drug Updates if file does not already exist
IF (!(Test-Path $OutFile)) {
    $functionTime = Get-Date -Format g
    $DLStartTime = Get-Date
    Add-Content $LogFile "$functionTime > $global:FileName Downloaded Started "
    (New-Object System.Net.WebClient).DownloadFile("$DLQResult" , $OutFile)
    Add-Content $LogFile "$functionTime > $global:FileName SUCCESS: Download Completed in $((Get-Date).subtract($DLStartTime).seconds) Second(s) "
}
else {
    Add-Content $LogFile "$functionTime > WARNING: File $global:FileName Already Exists in Directory, latest version of BP Drug Updates already Downloaded "
}


# Checks PBS Version for all members of BPAutoUpdate
foreach ($TargetMachine in $global:TargetMachines) {
    Add-Content $LogFile "$functionTime > Targeting $($TargetMachine.Name)"
    $global:PBSVersion = Invoke-Command -ComputerName $TargetMachine.Name -ScriptBlock ${function:Get-PBSVersion}
    Add-Content $LogFile "$functionTime > Retreived PBS Version from $($TargetMachine.Name) , found version to be $global:PBSVersion"
    if ($global:PBSVersion -match $global:LatestVersion) {
        $NeedsUpdate = "No"
    }
    else { $NeedsUpdate = "Yes" }
    $Record["Server"] = $TargetMachine.Name 
    $Record["PBS Update Version"] = $global:PBSVersion.PBS
    $Record["Needs Update"] = $($NeedsUpdate)
    if ($NeedsUpdate -match "Yes") {
        $localPath = $env:ALLUSERSPROFILE + "\BPUpdater\PBSData\" 
        Invoke-Command -ComputerName $TargetMachine.Name -ScriptBlock {
            if (!(Test-Path $Using:localPath)) {
                mkdir $Using:localPath -Force
            }
        }
        $DestStr = "\\" + $TargetMachine.Name + "\C$\ProgramData\BPUpdater\PBSData\" + $global:FileName
        $SrcStr = $global:PBSDataServ + $global:FileName
        if (!(Test-Path $DestStr)) {
            Start-BitsTransfer -Source $SrcStr -Destination $DestStr
            Add-Content $LogFile "$functionTime > Copying $global:FileName to $($TargetMachine.Name), location on target = $DestStr"
        }
        else {
            $Record["Error"] = "File already exists on target"
        }        
        $FileSentTime = (Get-Date -Format g)
        $FilesSent = $true
        
    }
    $Record["Files Sent"] = $FileSentTime
    if ($NeedsUpdate -match "Yes" -AND $FilesSent -eq $true) {
        $PBSexePath = $DestStr
        Add-Content $LogFile "$functionTime > Install invoked on $($TargetMachine.Name) "
        ([WMICLASS]"\\$($TargetMachine.Name)\ROOT\CIMV2:win32_process").Create("$($PBSexePath) /s") | Out-Null
        $InstallSent = $true
        $InstallSentTime = (Get-Date -Format g)
        $Record["Install Sent"] = $InstallSentTime}
    
    $objRecord = New-Object PSObject -Property $Record
    $global:Table += $objRecord
}
$Table | Export-Csv -Path $($PBSVerLog) -NoClobber -NoTypeInformation