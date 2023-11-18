#Requires -RunAsAdministrator

<#
.SYNOPSIS
    MS SQL Server installation script
.DESCRIPTION
    This script installs MS SQL Server unattended from the ISO image
.NOTES
    Version: 1.0
.LINK
    https://github.com/thotran90/DBAScripts/blob/master/Install-SQLServer/README.md
    https://www.microsoft.com/en-us/sql-server/sql-server-downloads
#>
param(
    # Path to ISO Image, if empty and current directory contains single ISO file, it will be used
    [string] $IsoImg = $Env:SQLSERVER_ISOPATH,

    # Path to log file
    [string] $InstallingLogDir, # = D:\Logs\

    # SQL Server features, see https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16#Feature
    # Installing SQL Engine only by default
    [ValidateSet('SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ', 'PolyBase', 'AdvancedAnalytics', 'AS', 'RS', 'DQC', 'IS', 'MDS', 'SQL_SHARED_MR', 'Tools', 'BC', 'BOL', 'Conn', 'DREPLAY_CLT', 'SNAC_SDK', 'SDK', 'LocalDB')]
    [string[]] $Features = @('SQLEngine'),

    # Service name. Mandatory, by default MSSQLSERVER
    [ValidateNotNullOrEmpty()]
    [string] $InstanceName = 'MSSQLSERVER',

    # sa user password. If empty, SQL security mode (mixed mode) is disabled
    [string] $SaPassword,

    # Username for the service account, see https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16
    # Optional, by default 'NT Service\MSSQLSERVER'
    [string] $ServiceAccountName, # = "$Env:USERDOMAIN\$Env:USERNAME"

    # Password for the service account, should be used for domain accounts only
    # Mandatory with ServiceAccountName
    [string] $ServiceAccountPassword,

    # List of system administrative accounts in the form <domain>\<user>
    # Mandatory, by default current user will be added as system administrator
    [string[]] $SystemAdminAccounts = @("$Env:USERDOMAIN\$Env:USERNAME"),

    # Product key
    [string] $ProductKey,

    # Use bits transfer to get files from the Internet
    [switch] $UseBitsTransfer,

    # Enable SQL Server protocols: TCP/IP, Named Pipes
    [switch] $EnableProtocols
)
$ErrorActionPreference = 'STOP'
$scriptName = (Split-Path -Leaf $PSCommandPath).Replace('.ps1','')

$start = Get-Date
if(!$InstallingLogDir){
    $InstallingLogDir = "$PSScriptRoot\$scriptName-$($start.ToString('s').Replace(':','-')).log"
}else{
    $InstallingLogDir = "$InstallingLogDir$scriptName-$($start.ToString('s').Replace(':','-')).log"
}
Write-Host "Installing log: $InstallingLogDir"
Start-Transcript $InstallingLogDir

if(!$IsoImg){
    Write-Host "Iso Image Path is not specified. Please download iso image by following the link:  https://www.microsoft.com/en-us/sql-server/sql-server-downloads"
    Write-Host "Exiting...."
    exit 404
}

Write-Host "Starting install MS SQL Server using ISO image: $IsoImg"
$volume = Mount-DiskImage $IsoImg -StorageType ISO -PassThru | Get-Volume
$iso_drive = if($volume){
    $volume.DriveLetter + ':'
} else{
    Get-PSDrive | ? Description -like 'sql*' | % Root
}
if(!$iso_drive) {throw "Can't find mounted ISO drive"} else {Write-Host "Mounted drive: $iso_drive"}

Get-ChildItem $iso_drive | ft -auto | Out-String
Get-CimInstance win32_process | ? { $_.CommandLine -like 'setup.exe*/ACTION=install*'} | % {
    Write-Host "Sql Server installer is already running, killing it:" $_.Path  "pid: " $_.ProcessId
    Stop-Process $_.ProcessId -Force
}

# Setting up the command to install
$cmd =@(
    "${iso_drive}setup.exe"
    '/Q'                                # Silent install
    '/INDICATEPROGRESS'                 # Specifies that the verbose Setup log file is piped to the console
    '/IACCEPTSQLSERVERLICENSETERMS'     # Must be included in unattended installations
    '/ACTION=install'                   # Required to indicate the installation workflow
    '/UPDATEENABLED=false'              # Should it discover and include product updates.

    "/FEATURES=" + ($Features -join ',')

    #Security
    "/SQLSYSADMINACCOUNTS=""$SystemAdminAccounts"""
    '/SECURITYMODE=SQL'                 # Specifies the security mode for SQL Server. By default, Windows-only authentication mode is supported.
    "/SAPWD=""$SaPassword"""            # Sa user password

    "/INSTANCENAME=$InstanceName"       # Server instance name

    "/SQLSVCACCOUNT=""$ServiceAccountName"""
    "/SQLSVCPASSWORD=""$ServiceAccountPassword"""

    # Service startup types
    "/SQLSVCSTARTUPTYPE=automatic"
    "/AGTSVCSTARTUPTYPE=automatic"
    "/ASSVCSTARTUPTYPE=manual"

    "/PID=$ProductKey"
)

# remove empty arguments
$cmd_out = $cmd = $cmd -notmatch '/.+?=("")?$'

# show all parameters but remove password details
Write-Host "Install parameters:`n"
'SAPWD', 'SQLSVCPASSWORD' | % { $cmd_out = $cmd_out -replace "(/$_=).+", '$1"****"' }
$cmd_out[1..100] | % { $a = $_ -split '='; Write-Host '   ' $a[0].PadRight(40).Substring(1), $a[1] }
Write-Host "$cmd_out"
Invoke-Expression "$cmd"
if ($LastExitCode) {
    if ($LastExitCode -ne 3010) { throw "SqlServer installation failed, exit code: $LastExitCode" }
    Write-Warning "SYSTEM REBOOT IS REQUIRED"
}

if ($EnableProtocols) {
    function Enable-Protocol ($ProtocolName) { $sqlNP | ? ProtocolDisplayName -eq $ProtocolName | Invoke-CimMethod -Name SetEnable }

    Write-Host "Enable SQL Server protocols: TCP/IP, Named Pipes"

    $sqlCM = Get-CimInstance -Namespace 'root\Microsoft\SqlServer' -ClassName "__NAMESPACE"  | ? name -match 'ComputerManagement' | Select-Object -Expand name
    $sqlNP = Get-CimInstance -Namespace "root\Microsoft\SqlServer\$sqlCM" -ClassName ServerNetworkProtocol

    Enable-Protocol 'TCP/IP'
    Enable-Protocol 'Named Pipes'

    Get-Service $InstanceName | Restart-Service -Force
}

"`nInstallation length: {0:f1} minutes" -f ((Get-Date) - $start).TotalMinutes

Dismount-DiskImage $IsoImg
Stop-Transcript
trap { Stop-Transcript; if ($IsoImg) { Dismount-DiskImage $IsoImg -ErrorAction 0 } }