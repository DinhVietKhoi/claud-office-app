& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

  $repo = 'DinhVietKhoi/claud-office-app'
  $port = if ($env:OFFICE_PORT) { $env:OFFICE_PORT } else { '4777' }
  if (-not [Environment]::Is64BitOperatingSystem) { throw 'Claude Office chỉ có bản Windows 64-bit' }

  $version = $env:CLAUDE_OFFICE_VERSION
  if (-not $version) {
    $latest = Invoke-WebRequest "https://github.com/$repo/releases/latest" -UseBasicParsing
    $final = if ($latest.BaseResponse.ResponseUri) { $latest.BaseResponse.ResponseUri.AbsoluteUri } else { $latest.BaseResponse.RequestMessage.RequestUri.AbsoluteUri }
    $version = ($final -split '/v')[-1]
  }
  if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Không tìm được bản phát hành mới nhất' }
  $name = "Claude-Office-$version-win-x64.zip"
  $base = "https://github.com/$repo/releases/download/v$version"
  $work = Join-Path $env:TEMP ("claude-office-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work | Out-Null

  try {
    Write-Host "↓ Tải Claude Office v$version"
    $zip = Join-Path $work $name
    Invoke-WebRequest "$base/$name" -OutFile $zip -UseBasicParsing
    Invoke-WebRequest "$base/$name.sha256" -OutFile "$zip.sha256" -UseBasicParsing
    $expected = ((Get-Content "$zip.sha256" -Raw).Trim() -split '\s+')[0].ToLower()
    $actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) { throw 'File tải về không khớp checksum, hãy chạy lại lệnh' }

    try {
      Invoke-RestMethod -Method Post "http://127.0.0.1:$port/api/shutdown" -Headers @{ 'X-Office' = '1' } -TimeoutSec 3 | Out-Null
      Write-Host '• Tắt Claude Office đang chạy (các phòng sẽ tự mở lại)'
      for ($i = 0; $i -lt 20; $i++) {
        try { Invoke-WebRequest "http://127.0.0.1:$port/style.css" -UseBasicParsing -TimeoutSec 1 | Out-Null; Start-Sleep -Milliseconds 500 } catch { break }
      }
      Start-Sleep -Milliseconds 500
    } catch {}

    Unblock-File $zip
    Expand-Archive $zip -DestinationPath (Join-Path $work 'out') -Force
    $target = if ($env:CLAUDE_OFFICE_DIR) { $env:CLAUDE_OFFICE_DIR } else { $env:LOCALAPPDATA }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    $dir = Join-Path $target 'Claude Office'
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
    Move-Item (Join-Path $work 'out\Claude Office') $dir
    Get-ChildItem $dir -Recurse -File | Unblock-File

    $programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    New-Item -ItemType Directory -Force -Path $programs | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut((Join-Path $programs 'Claude Office.lnk'))
    $link.TargetPath = "$env:WINDIR\System32\wscript.exe"
    $link.Arguments = '"' + (Join-Path $dir 'Claude Office.vbs') + '"'
    $link.WorkingDirectory = $dir
    $link.IconLocation = Join-Path $dir 'app\assets\icon.ico'
    $link.Save()
    Write-Host "✓ Đã cài vào $dir, có lối tắt Claude Office trong Start Menu"

    if ($env:CLAUDE_OFFICE_NO_OPEN) {
      & (Join-Path $dir 'node.exe') (Join-Path $dir 'app\bin\office.mjs') start
      if ($LASTEXITCODE) { throw 'Không bật được Claude Office' }
    } else {
      Start-Process "$env:WINDIR\System32\wscript.exe" -ArgumentList ('"' + (Join-Path $dir 'Claude Office.vbs') + '"')
    }
    Write-Host 'Lần đầu mở app, tick Kết nối Claude Code ở màn thiết lập để văn phòng thấy Claude đang làm gì.'
  } finally {
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
  }
}
