# Install-SQLServer

[![](https://img.shields.io/badge/version-1.0-blue)](https://github.com/thotran90/DBAScripts)

This script installs MS SQL Server on Window OS silently from ISO image that can be available locally or downloaded from the internet.  

The script lists paramerters provided to the native setup but hides sensitve data.  
## Prerequisites  

1. Windows OS  
2. Administrive rights  
3. MS SQL Server ISO image [optional]  

## Usage  
The fastest way to install SQL server engine is to run in administrative shell:  
```ps
.\Install-SQLServer.ps1 -EnableProtocols
```  
This will download and install **SQL Server Developer Edition** and enable all protocols. Provide your own ISO image of any edition using IsoImg.  
## Notes  


## Troubleshooting  
**Installing on remote machine using Powershell remote session**  

>The following errors may occur:  
 There was an error generating the XML document  
        ... Access denied  
        ... The computer must be trusted for delegation and the current user account must be configured to allow delegation

**The solution**: Use WinRM session parameter `-Authentication CredSSP`.

To be able to use it, the following settings needs to be done on both local and remote machine:

1. On local machine using `gpedit.msc`, go to *Computer Configuration -> Administrative Templates -> System -> Credentials Delegation*.<br>
Add `wsman/*.<domain>` (set your own domain) in the following settings
    1. *Allow delegating fresh credentials with NTLM-only server authentication*
    2. *Allow delegating fresh credentials*
1. The remote machine must be set to behave as CredSSP server with `Enable-WSManCredSSP -Role server`   

## Links  
- [Install SQL Server from the Command Prompt](https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16)
    - [Features](https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16#Feature)
    - [Accounts](https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16#Accounts)
- [Download SQL Server Management Studio](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
- [Editions and features](https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022?view=sql-server-ver16&preserve-view=true)