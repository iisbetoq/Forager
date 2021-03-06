param(
    [Parameter(Mandatory = $true)][String]$Key,
    [Parameter(Mandatory = $true)][String]$WorkerName,
    [Parameter(Mandatory = $true)]$ActiveMiners,
    [Parameter(Mandatory = $true)]$MinerStatusURL
)

$Profit = 0
$MinerReport = ConvertTo-Json @($ActiveMiners.SubMiners | Where-Object Status -eq 'Running' | ForEach-Object {
        $Profit += [decimal]$_.RevenueLive + [decimal]$_.RevenueLiveDual

        $Type = $ActiveMiners[$_.IdF].DeviceGroup.GroupName

        [pscustomobject]@{
            Name           = $ActiveMiners[$_.IdF].Name
            # Path           = Resolve-Path -Relative $_.Path
            Path           = $ActiveMiners[$_.IdF].Symbol + $(
                if (![string]::IsNullOrEmpty($ActiveMiners[$_.IdF].AlgorithmDual)) {'|' + $ActiveMiners[$_.IdF].SymbolDual}
            )
            Type           = $ActiveMiners[$_.IdF].DeviceGroup.GroupName
            # Active         = "{0:N1} min" -f ($_.TimeSinceStartInterval.TotalMinutes)
            Active         = $(if ($_.Stats.Activetime.TotalMinutes -le 60) {"{0:N1} min" -f ($_.Stats.ActiveTime.TotalMinutes)} else {"{0:N1} hours" -f ($_.Stats.ActiveTime.TotalHours)})
            Algorithm      = $ActiveMiners[$_.IdF].Algorithm + $ActiveMiners[$_.IdF].AlgoLabel + $(
                if (![string]::IsNullOrEmpty($ActiveMiners[$_.IdF].AlgorithmDual)) {'|' + $ActiveMiners[$_.IdF].AlgorithmDual}
            ) + $ActiveMiners[$_.IdF].BestBySwitch
            Pool           = $ActiveMiners[$_.IdF].PoolAbbName + $(
                if (![string]::IsNullOrEmpty($ActiveMiners[$_.IdF].AlgorithmDual)) {'|' + $ActiveMiners[$_.IdF].PoolAbbNameDual}
            )
            CurrentSpeed   = (ConvertTo_Hash $_.SpeedLive) + '/s' + $(
                if (![string]::IsNullOrEmpty($ActiveMiners[$_.IdF].AlgorithmDual)) {'|' + (ConvertTo_Hash $_.SpeedLiveDual) + '/s'}
            ) -replace ",", "."
            EstimatedSpeed = (ConvertTo_Hash $_.Hashrate) + '/s' + $(
                if (![string]::IsNullOrEmpty($ActiveMiners[$_.IdF].AlgorithmDual)) {'|' + (ConvertTo_Hash $_.HashrateDual) + '/s'}
            ) -replace ",", "."
            PID            = $ActiveMiners[$_.IdF].Process.Id
            StatusMiner    = $(if ($_.NeedBenchmark) {"Benchmarking($([string](($ActiveMiners | Where-Object {$_.DeviceGroup.GroupName -eq $Type}).count)))"} else {$_.Status})
            'BTC/day'      = [decimal]$_.RevenueLive + [decimal]$_.RevenueLiveDual
        }
    })
try {
    Invoke-RestMethod -Uri $MinerStatusURL -Method Post -Body @{address = $Key; workername = $WorkerName; miners = $MinerReport; profit = $Profit} | Out-Null
} catch {}
# $MinerReport | Set-Content report.txt
