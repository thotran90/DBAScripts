#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Perform database checklist base on Standard for Enterprise database instance
.DESCRIPTION
    Perform database checklist base on Standard for Enterprise database instance
.NOTES
    Version: 1.0
.LINK
    
#>
param(
    # Path to log file
    [string] $InstallingLogDir # = D:\Logs\
)
$ErrorActionPreference = 'STOP'
$line = "=================================== Tho Tran ====================================="
$scriptName = (Split-Path -Leaf $PSCommandPath).Replace('.ps1','')

$start = Get-Date
if(!$InstallingLogDir){
    $InstallingLogDir = "$PSScriptRoot\$scriptName-$($start.ToString('s').Replace(':','-')).log"
}else{
    $InstallingLogDir = "$InstallingLogDir$scriptName-$($start.ToString('s').Replace(':','-')).log"
}
Write-Host "Installing log: $InstallingLogDir"
Start-Transcript $InstallingLogDir

Import-Module sqlps -DisableNameChecking
Write-Host "Loading the standard configuration from configuration.json"
## Retrieve the list of configuration
$config = Get-Content '.\configuration.json' | Out-String | ConvertFrom-Json
Write-Host "The standard configuration:  "
Write-Host $config | ConvertFrom-Json

## Get the Instance Name 
$dbInstance = (Invoke-Sqlcmd -ServerInstance "localhost" -Query "select @@SERVICENAME as ServiceName").ServiceName
Write-Host "Database Instance: $dbInstance"

## Step 1: Changing database default location
Write-Host "Step 1: Changing database default location"
$registryPath = "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Microsoft SQL Server\*$dbInstance\MSSQLServer"

Set-ItemProperty -Path $registryPath -Name "DefaultData" -Value $config.DataFile 
Set-ItemProperty -Path $registryPath -Name "DefaultLog" -Value $config.LogFile
Set-ItemProperty -Path $registryPath -Name "BackupDirectory" -Value $config.BackupFile
Write-Host "Changing database default location: Done"
Write-Host $line


Get-Service -Name "*$dbInstance" | Restart-Service -Confirm -Force


Stop-Transcript