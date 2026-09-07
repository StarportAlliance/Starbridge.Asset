$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = 'https://asset.starbridge.ink/regionInfo.json'
$dest = [System.IO.Path]::GetFullPath((Join-Path $env:APPDATA '..\LocalLow\Innersloth\Among Us\regionInfo.json'))
$exitCode = 0

$osInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
if ($null -eq $osInfo) {
    $osVersion = [System.Environment]::OSVersion.Version
    $osInfo = [PSCustomObject]@{
        CurrentMajorVersionNumber = [int]$osVersion.Major
        CurrentMinorVersionNumber = [int]$osVersion.Minor
        CurrentBuildNumber        = [int]$osVersion.Build
    }
}
$osMajor = [int]$osInfo.CurrentMajorVersionNumber
$osMinor = [int]$osInfo.CurrentMinorVersionNumber
$osBuild = [int]$osInfo.CurrentBuildNumber

if ($osMajor -eq 6 -and $osMinor -eq 1) {
    Write-Error 'Starbridge 安装脚本不支持当前操作系统版本，请升级至 Windows 10 或更高版本后再试。'
    Write-Host ''
    Write-Error '您仍然可以尝试手动安装 Starbridge 服务器。参见 https://starbridge.ink/docs/guide#win。'
    Write-Host ''
    Write-Host '按下 Enter 键退出...'
    Read-Host
    exit 1
}

try {
    Write-Host '欢迎使用 Starbridge 服务器配置文件安装器！当前脚本版本为 v1.1.1。'

    if ($osMajor -eq 10 -and $osBuild -lt 22000) {
        Write-Warning 'Microsoft 已于 2025 年 10 月停止对 Windows 10 的支持，Starbridge 安装脚本可能在此设备上无法正常工作。'
        Write-Host ''
        Write-Warning 'Starbridge 将不会处理在 Windows 10 系统上发送问题的报告，我们建议您升级至 Windows 11。'
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null

    Write-Host '开始下载服务器配置文件...'

    # 使用同步 HttpWebRequest 分块读取并在当前线程显示进度，
    # 避免异步回调运行在线程池线程（无 Runspace）而导致崩溃。
    $request = [System.Net.HttpWebRequest]::Create($url)
    $request.UserAgent = 'StarbridgeInstaller/1.1.0'
    $response = $request.GetResponse()
    try {
        $stream = $response.GetResponseStream()
        $totalBytes = [long]$response.ContentLength
        $buffer = New-Object byte[] 65536
        $memStream = New-Object System.IO.MemoryStream
        try {
            while (($readCount = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $memStream.Write($buffer, 0, $readCount)
                $downloaded = $memStream.Length
                if ($downloaded -gt 1024) { throw '下载内容大小异常。' }
                if ($totalBytes -gt 0) {
                    $pct = [Math]::Min([int]($downloaded * 100 / $totalBytes), 100)
                    Write-Host ("`r下载进度：{0,3}%  ({1:N2} KB / {2:N2} KB)" -f $pct, ($downloaded / 1KB), ($totalBytes / 1KB)) -NoNewline
                }
                else {
                    Write-Host ("`r已下载：{0:N2} KB" -f ($downloaded / 1KB)) -NoNewline
                }
            }
        }
        finally {
            $stream.Close()
        }
        $bytes = $memStream.ToArray()
        Write-Host ''
        if ($null -eq $bytes) { throw '下载内容为空。' }
        if ($bytes.Length -gt 5242880) { throw '下载内容大小异常。' }
    }
    finally {
        $response.Close()
    }

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