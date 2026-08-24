$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = 'https://asset.starbridge.ink/regionInfo.json'
$dest = [System.IO.Path]::GetFullPath((Join-Path $env:APPDATA '..\LocalLow\Innersloth\Among Us\regionInfo.json'))
$exitCode = 0

function Show-DownloadProgress {
    param($e)
    if ($e.TotalBytesToReceive -gt 0) {
        $pct = [Math]::Min($e.ProgressPercentage, 100)
        Write-Host ("`r下载进度：{0,3}%  ({1:N2} KB / {2:N2} KB)" -f $pct, ($e.BytesReceived / 1KB), ($e.TotalBytesToReceive / 1KB)) -NoNewline
    }
    else {
        Write-Host ("`r已下载：{0:N2} KB" -f ($e.BytesReceived / 1KB)) -NoNewline
    }
}

try {
    Write-Host '欢迎使用 Starbridge 服务器配置文件安装器！当前脚本版本为 v1.1.0。'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null

    Write-Host '开始下载服务器配置文件...'

    $done = New-Object System.Threading.AutoResetEvent $false
    $script:dlError = $null
    $script:dlBytes = $null

    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add('User-Agent', 'StarbridgeInstaller/1.1.0')
    $wc.add_DownloadProgressChanged({
            param($s, $e)
            Show-DownloadProgress $e
        })
    $wc.add_DownloadDataCompleted({
            param($s, $e)
            if ($e.Error) { $script:dlError = $e.Error }
            if (-not $e.Cancelled) { $script:dlBytes = $e.Result }
            $done.Set()
        })

    $wc.DownloadDataAsync($url)
    $done.WaitOne() | Out-Null

    if ($script:dlError) { throw $script:dlError }
    $bytes = $script:dlBytes
    Write-Host ''
    if ($null -eq $bytes) { throw '下载内容为空。' }
    if ($bytes.Length -gt 5242880) { throw '下载内容大小异常。' }

    Set-ItemProperty -LiteralPath $dest -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    [System.IO.File]::WriteAllBytes($dest, $bytes)
    # 固定添加只读保护
    Set-ItemProperty -LiteralPath $dest -Name IsReadOnly -Value $true
    Write-Host '服务器配置文件安装完成！'
    Write-Host '如果你已启动 Among Us，需要重新启动后服务器列表才会显示。'
}
catch {
    Write-Host ('安装服务器配置文件时发生错误：' + $_.Exception.Message)
    Write-Host '请复制错误信息或截图此窗口并向 StarportAlliance 成员报告此问题。'
    $exitCode = 1
}
finally {
    Write-Host ''
    Write-Host '按下 Enter 键退出...'
    Read-Host
}
exit $exitCode