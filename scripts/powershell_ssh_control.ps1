$credential = Get-Credential
$session = New-SSHSession -ComputerName "10.0.0.1" -Credential $credential
Get-SSHSession
$stream = New-SSHShellStream -SSHSession $session
Invoke-SSHStreamExpectAction -ShellStream $stream -Command "config firewall address" -ExpectString "FGT50E3U16006093" -Action "`n"
Get-SSHSession | Out-Null
Invoke-SSHStreamExpectAction -ShellStream $stream -Command "get devwks01" -ExpectString "FGT50E3U16006093" -Action "`n"
Sleep -Seconds 2
$stream.Read()
Get-SSHSession | Remove-SSHSession