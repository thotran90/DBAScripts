function New-Job{
    [CmdletBinding()]
    param()
    begin{}
    process{
        Write-Host "Hello World! This is my first PS module."

        $msg = Get-PrivateMessage

        Write-Host $msg
    }
}

New-Alias -Name nj -Value New-Job