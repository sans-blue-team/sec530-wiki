# Comment out lines 3, 4, and 10 if running on a local system
# These lines are for remotely running this script against systems

$computer = Get-ADComputer -SearchBase "dc=test,dc=int" -Filter * | Select-Object -ExpandProperty Name
Invoke-Command -ComputerName $computer -ScriptBlock {
    $adapters=(gwmi win32_networkadapterconfiguration )
    Foreach ($adapter in $adapters){
        Write-Host $adapter
        $adapter.settcpipnetbios(2) # 1 is enable 2 is disable
    }
}