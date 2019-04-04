# BPUpdater

Requirements:
- Domain Joined Database/Application Servers
- Application Servers Added to Security Group
    - This, by default, is set to BPAutoUpdate. This can be changed as per your AD Naming Convention, just make sure you update the value for $TarverMachineADGroup
- Script must be launched as an account with Domain Administrator Permissions, so that command invocation works natively and script can create folders and write data to files without permissions issues
- Central server for this to run on (Suggested: Management Server that is on domain)


Logic:
- Gets members of AD Group containing Database/Application Servers
- Queries "https://bpsoftware.net/resources/bp-premier-downloads/", checking HREF tags that include *inc.exe (this indicates an Incremental Update)
- Checks folder "PBSData" - created by script - to see if this file is already downloads
    - IF different, starts a BITS Transfer to download the file to PBSData folder (Site uses TLS1.2, so had to add this protocol in script to allow communication with site)
- Starts foreach Loop, for each discovered member of AD Group
- Invokes command to query registry key that holds current PBS/MBS Update Version
- Logs results to hash table
- Compares table fields for the "new" PBS file, and the existing PBS registry key on TargetMachine
    - IF Same, creates field value "NO" for the "Needs Update" field
    - IF Different, creates field value "YES" for the "Needs Update field
- Compares current PBS value (from query), to file name from BPSoftware.net and logs
    - IF same, do nothing - proceed
    - IF different, copies PBS Update file from server to TargetMachine
- Checks "Needs Update" field for TargetMachine
    - IF Needs Update -match YES, Invokes install using silent arguments on TargetMachine
    - IF Needs Update -match NO, does nothing


WIP: 
- "Last Known" drug update, if TargetMachine does not match current or last known, requires Comprehensive Update (if you try to install an incremental update when the software is out of date, update will fail to install)
- HTML Formatting for Weekly Report
- Weekly Emailed Reports (report as attachment in HTML Format)
- Install script to run Daily as Scheduled Task


Maybe to come: 
- Integration with Sharepoint Lists instead of local .csv file
- MS Flows for Update Approval