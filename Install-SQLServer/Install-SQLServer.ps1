#Requires -RunAsAdministrator

<#
.SYNOPSIS
    MS SQL Server installation script
.DESCRIPTION
    This script installs MS SQL Server unattended from the ISO image
.NOTES
    Version: 1.0
.LINK
    https://github.com/thotran90/DBAScripts/blob/main/README.md
#>
param(
    # Path to ISO Image, if empty and current directory contains single ISO file, it will be used
    [string] $IsoImg = $Env:SQLSERVER_ISOPATH,

    # SQL Server features, see https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16#Feature
    # Installing SQL Engine only by default
    [ValidateSet('SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ', 'PolyBase', 'AdvancedAnalytics', 'AS', 'RS', 'DQC', 'IS', 'MDS', 'SQL_SHARED_MR', 'Tools', 'BC', 'BOL', 'Conn', 'DREPLAY_CLT', 'SNAC_SDK', 'SDK', 'LocalDB')]
    [string[]] $Features = @('SQLEngine'),

    # Specifies a nondefault installation directory
    [string] $InstallDir,

    # Data directory, by default "$Env:ProgramFiles\Microsoft SQL Server"
    [string] $DataDir,

    # Service name. Mandatory, by default MSSQLSERVER
    [ValidateNotNullOrEmpty()]
    [string] $InstanceName = 'MSSQLSERVER',

    # sa user password. If empty, SQL security mode (mixed mode) is disabled
    [SecureString] $SaPassword = "P@ssw0rd",

    # Username for the service account, see https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16
    # Optional, by default 'NT Service\MSSQLSERVER'
    [string] $ServiceAccountName, # = "$Env:USERDOMAIN\$Env:USERNAME"

    # Password for the service account, should be used for domain accounts only
    # Mandatory with ServiceAccountName
    [SecureString] $ServiceAccountPassword,

    # List of system administrative accounts in the form <domain>\<user>
    # Mandatory, by default current user will be added as system administrator
    [string[]] $SystemAdminAccounts = @("$Env:USERDOMAIN\$Env:USERNAME"),

    # Product key, if omitted, evaluation is used unless VL edition which is already activated
    [string] $ProductKey,

    # Use bits transfer to get files from the Internet
    [switch] $UseBitsTransfer,

    # Enable SQL Server protocols: TCP/IP, Named Pipes
    [switch] $EnableProtocols
)