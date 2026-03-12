param(
  [string]$Dir = "$env:LOCALAPPDATA\\Microsoft\\WindowsApps",
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$SourceBat = Join-Path $RootDir 'kpp.bat'
$SourcePs1 = Join-Path $RootDir 'kpp.ps1'

if (-not (Test-Path $SourceBat) -or -not (Test-Path $SourcePs1)) {
  Write-Error '[K++] 오류: kpp.bat 또는 kpp.ps1 파일을 찾을 수 없습니다.'
}

New-Item -ItemType Directory -Path $Dir -Force | Out-Null

$TargetBat = Join-Path $Dir 'kpp.bat'
$TargetPs1 = Join-Path $Dir 'kpp.ps1'

if ((Test-Path $TargetBat -or Test-Path $TargetPs1) -and -not $Force) {
  Write-Host "[K++] 이미 설치 파일이 존재합니다: $Dir" -ForegroundColor Yellow
  Write-Host '[K++] 덮어쓰려면 --force 옵션을 사용하세요.' -ForegroundColor Yellow
  exit 1
}

Copy-Item -Path $SourceBat -Destination $TargetBat -Force
Copy-Item -Path $SourcePs1 -Destination $TargetPs1 -Force

Write-Host "[K++] 설치 완료: $TargetBat"
Write-Host '[K++] 새 터미널에서 확인: kpp --help'
