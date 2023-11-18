#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Mount ISO image with specific drive letter
.DESCRIPTION
    This script mount the ISO image with the specific drive letter
.NOTES
    Version: 1.0
#>
param(
    # Path to ISO file, if empty and current directory contains single ISO file, it will be used.
    [string] $isoImg = $ENV:SQLSERVER_ISOPATH,

    # Drive Letter
    [string] $driveLetter = "X:\" # note the added ending backslash: mount fails if its not there :(
    
)
    
#Check if elevated
[Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
$Admin = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    
if ($Admin) 
{
    Write-Host "Administrator rights detected, continuing install.";
        
    Write-Host "Mount the ISO, without having a drive letter auto-assigned";
    $diskImg = Mount-DiskImage -ImagePath $isoImg  -NoDriveLetter -PassThru;
    
    #Write-Host "Get mounted ISO volume";
    $volInfo = $diskImg | Get-Volume
    
    #Write-Host "Mount volume with specified drive letter";
    mountvol $driveLetter $volInfo.UniqueId
      
    #Start-Sleep -Seconds 1
    #<do work>
    #Start-Sleep -Seconds 1
    
    #Write-Host "DisMount ISO volume"; 
    #DisMount-DiskImage -ImagePath $isoImg  # not used because SQL install is in an other powershell session
    
    Write-Host "Done";
    exit 0;
    
}
else
{
    Write-Error "This script must be executed as Administrator.";
    exit 1;
}