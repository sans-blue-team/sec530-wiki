Import-Module Posh-SSH

$debug = 0
$script:user = "admin"
$script:password = $password = Get-Content C:\cred.txt | ConvertTo-SecureString
$firewall = "10.0.0.1"
# How many minutes back in time to search for alerts
$minutes = 2
# How long to sleep before starting over
$sleep_time = 10
#region Fortigate functions
function New-FortigateSession($firewall){
    $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $script:user,$script:password
    $script:session = New-SSHSession -ComputerName $firewall -Credential $credentials -AcceptKey:$true -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
    $script:stream = New-SSHShellStream -SSHSession $script:session -InformationAction SilentlyContinue
}
function Remove-FortigateSession($script:session){
    Remove-SSHSession -SessionId $script:session.SessionId | Out-Null
}
function Remove-NormalAssets($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall addrgrp" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit Variable\ Trust\ -\ Normal" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "unselect member $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function Set-NormalAssets($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall addrgrp" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit Variable\ Trust\ -\ Normal" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "append member $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function Remove-LowRiskAssets($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall addrgrp" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit Variable\ Trust\ -\ Low" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "unselect member $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function Set-LowRiskAssets($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall addrgrp" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit Variable\ Trust\ -\ Low" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "append member $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function Remove-HighRiskAssets($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall addrgrp" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit Variable\ Trust\ -\ High" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "unselect member $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function Set-HighRiskAssets($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall addrgrp" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit Variable\ Trust\ -\ High" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "append member $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function New-Asset($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall address" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "edit $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "set type ipmask" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "set subnet $asset/32" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
function Remove-Asset($firewall, $asset){
    New-FortigateSession $firewall
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "config firewall address" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "delete $asset" -ExpectString "#" -Action `n
    $null = Invoke-SSHStreamExpectAction -ShellStream $script:stream -Command "end" -ExpectString "#" -Action `n
    Remove-FortigateSession $script:session
}
#endregion

#region Elastic functions
function Get-ElasticAlertCountByHost($elasticsearch, $minutes){
    $beginTimestamp = ((Get-Date).ToUniversalTime().AddMinutes("-$minutes")) | Get-Date -Format s
    $endTimestamp = (Get-Date).ToUniversalTime() | Get-Date -Format s
    $query = Invoke-WebRequest -Uri "http://192.168.2.201:9200/elastalert_status/_search?q=alert_sent:true AND @timestamp:[$beginTimestamp TO $endTimestamp]"
    $json = $query.Content | ConvertFrom-Json
    $ips = $json.hits.hits._source.match_body.source_ip
    $dns_names = $json.hits.hits._source.match_body.beat.hostname
    foreach($dns_entry in $dns_names){
        $ip = (Resolve-DnsName -Server "192.168.2.101" -DnsOnly -Name "$dns_entry.labmeinc.internal").IPAddress
        $ips += $ip
    }
    return $ips | Group-Object -NoElement
}
#endregion

$naughtyList = @{}
while(1 -eq 1){
    $risky_systems = Get-ElasticAlertCountByHost "192.168.2.101" $minutes
    $date = Get-date -Format "yyyy-MM-dd HH:mm:ss"
    if($debug -eq 1){
        Write-Host "Naughty list contains: "
        $naughtyList
        Write-Host "Risky systems contains: "
        $risky_systems
    }
    # Remove hosts no longer found to be risky
    if($risky_systems -eq $null -or ($risky_systems).Count -eq 0){
        if($naughtyList.Count -gt 0){
            $remove = @()
            $naughtyList.keys | ForEach-Object {
                $remove += $_
                $name = $_
                Remove-LowRiskAssets $firewall $name
                Remove-HighRiskAssets $firewall $name
                Set-NormalAssets $firewall $name
                Write-Host "$date - Removing $name from High and Low Risk Assets and adding to Normal Assets"
            }
            foreach($item in $remove){
                $naughtyList.Remove($item)
            }
        }
    } elseif($naughtyList.Count -gt 0){
        $remove = @()
        $naughtyList.keys | ForEach-Object {
            $name = $_
            if($name -ne ""){
                if($name -notin $risky_systems.Name){
                    Remove-LowRiskAssets $firewall $name
                    Remove-HighRiskAssets $firewall $name
                    Set-NormalAssets $firewall $name
                    Write-Host "$date - Removing $name from High and Low Risk Assets and adding to Normal Assets"
                    $remove += $_
                }
            }
        }
        if($remove.Count -gt 0){
            foreach($item in $remove){
                $naughtyList.Remove($item)
            }
        }
    }
    foreach($system in $risky_systems){
        $name = $system.name
        New-Asset $firewall $name
        if($naughtyList.ContainsKey($name)){
            # Previously seen find new risk level and remove from old
            $previous_count = $naughtyList[$name]
            $current_count = $system.Count
            if($debug -eq 1){
                Write-Host "Previous count is : $previous_count"
                Write-Host "Current count is : $current_count"
            }
            if($previous_count -ne $current_count){
                $naughtyList[$name] = $current_count
                if($previous_count -eq 1 -and $current_count -ge 2){
                    Write-Host "$date - Adding $name to High Risk Assets and removing from Low Risk Assets"
                    Set-HighRiskAssets $firewall $name
                    Remove-LowRiskAssets $firewall $name
                }
                if($previous_count -ge 2 -and $current_count -eq 1){
                    Write-Host "$date - Adding $name to Low Risk Assets and removing from High Risk Assets"
                    Set-LowRiskAssets $firewall $name
                    Remove-HighRiskAssets $firewall $name
                }
            }
        } else {
            # First observence - set proper risk level
            $naughtyList.add($name, $system.Count )
            if($system.Count -eq 1){
                Write-Host "$date - Adding $name to Low Risk Assets and removing from Normal Assets"
                Set-LowRiskAssets $firewall $name
                Remove-NormalAssets $firewall $name
            }
            if($system.Count -ge 2){
                Write-Host "$date - Adding $name to High Risk Assets and removing from Normal Assets"
                Set-HighRiskAssets $firewall $name
            }
        }
    }
    Write-Host "$date - Sleeping $sleep_time seconds"
    Start-Sleep -Seconds $sleep_time
}