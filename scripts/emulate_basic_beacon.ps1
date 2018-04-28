# Author: Justin Henderson
# Version: 1.0
# Last Update: 06/2017
#
# This script is a simple method of simulating network beaconing
#

$beacon_interval = 555
$count = 1
Do {
    if(Test-NetConnection -ComputerName www.sec555.com -Port 80) {
        $time = Get-Date -Format T
        Write-Host "Connection Successful at $time - Count of $count" -ForegroundColor Cyan
    } else {
        $time = Get-Date -Format T
        Write-Host "Connection Failed at $time - Count of $count" -ForegroundColor Red
    }
    $count++
    Sleep -Seconds $beacon_interval
} While (1 -eq 1)