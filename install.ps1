$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = 'https://asset.starbridge.ink/regionInfo.json'
$dest = [System.IO.Path]::GetFullPath((Join-Path $env:APPDATA '..\LocalLow\Innersloth\Among Us\regionInfo.json'))
$exitCode = 0

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add('User-Agent', 'StarbridgeInstaller/1.0.0')
    $bytes = $wc.DownloadData($url)
    if ($bytes.Length -eq 0) { throw '下载内容为空。' }
    if ($bytes.Length -gt 5242880) { throw '下载内容大小异常。' }
    Set-ItemProperty -LiteralPath $dest -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    [System.IO.File]::WriteAllBytes($dest, $bytes)
    Write-Host '[Starbridge] 服务器配置文件安装完成！'
    Write-Host '[Starbridge] 如果你已启动 Among Us，需要重新启动后服务器列表才会显示。'
} catch {
    Write-Host ('[Starbridge] 安装服务器配置文件时发生错误：' + $_.Exception.Message)
    $exitCode = 1
} finally {
    Write-Host ''
    Write-Host '按下 Enter 键退出...'
    Read-Host
}
exit $exitCode