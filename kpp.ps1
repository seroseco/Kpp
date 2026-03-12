$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $RootDir 'generated/bin'
$CppDir = Join-Path $RootDir 'generated/cpp'
$KppBin = Join-Path $BinDir 'kppc.exe'

$SourceFiles = @(
  (Join-Path $RootDir 'src/main.cpp'),
  (Join-Path $RootDir 'src/transpiler.cpp'),
  (Join-Path $RootDir 'src/dictionary.cpp'),
  (Join-Path $RootDir 'include/transpiler.hpp'),
  (Join-Path $RootDir 'include/dictionary.hpp')
)

$KeywordRegex = '(포함|사용|범위|표준|정수|짧은|긴|매우긴|뜨다|실수|숯|불|참|거짓|빈|자동|부호없는|부호있는|상수|정적|새로|삭제|널|출력|입력|끝줄|반환|진입|반복|동안|실행|만약|아니면|스위치|경우|기본|멈춰|계속|이동|시도|잡기|던지기|문자열|클래스|구조체|공개|비공개|보호|가상|템플릿|자료형|벡터|배열|목록|덱|큐|스택|우선큐|맵|집합|순서없는맵|순서없는집합|쌍|정렬|역정렬|교환|중복제거|찾기|개수|누적|최소값|최대값|시작|끝|크기|비었나|비우기|뒤에추가|앞에추가|뒤에서제거|앞에서제거)'
$TypeRegex = '(정수|짧은|긴|매우긴|뜨다|실수|숯|불|문자열|자동|벡터|배열|목록|덱|큐|스택|우선큐|맵|집합|순서없는맵|순서없는집합|쌍)'

function Show-Usage {
  @'
Usage:
  .\kpp.bat init [file.kpp]
  .\kpp.bat <input.kpp> [-o output.cpp] [--stdout] [--run] [--safe]

Examples:
  .\kpp.bat init
  .\kpp.bat init practice.kpp
  .\kpp.bat examples\kpp\hello.kpp
  .\kpp.bat examples\kpp\hello.kpp --run
  .\kpp.bat examples\kpp\hello.kpp --safe
  .\kpp.bat examples\kpp\hello.kpp --stdout
'@ | Write-Host
}

function New-InitFile([string]$Target = 'main.kpp') {
  if (-not $Target.EndsWith('.kpp')) {
    $Target = "$Target.kpp"
  }

  if (Test-Path $Target) {
    Write-Error "[K++] 오류: 이미 파일이 존재합니다: $Target"
  }

  $dir = Split-Path -Parent $Target
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  @'
#포함 <iostream>

사용 범위 표준;

정수 진입() {
  출력 << "K++ 시작!" << 끝줄;
  반환 0;
}
'@ | Set-Content -Path $Target -Encoding UTF8

  Write-Host "[K++] 생성 완료: $Target"
  Write-Host "[K++] 실행 예시: .\kpp.bat --run $Target"
}

function Needs-Rebuild {
  if (-not (Test-Path $KppBin)) {
    return $true
  }

  $binTime = (Get-Item $KppBin).LastWriteTime
  foreach ($f in $SourceFiles) {
    if ((Get-Item $f).LastWriteTime -gt $binTime) {
      return $true
    }
  }

  return $false
}

function Build-Kppc {
  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  New-Item -ItemType Directory -Force -Path $CppDir | Out-Null

  & g++ -std=c++17 "-I$($RootDir)/include" (Join-Path $RootDir 'src/main.cpp') (Join-Path $RootDir 'src/transpiler.cpp') (Join-Path $RootDir 'src/dictionary.cpp') -o $KppBin

  if ($LASTEXITCODE -ne 0) {
    Write-Error '[K++] 오류: kppc 자동 빌드에 실패했습니다. g++ 설치를 확인하세요.'
  }
}

function Find-KeywordCollisions([string]$SourceFile) {
  $content = Get-Content -Path $SourceFile
  $hits = @()

  for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]

    if ($line -match "${TypeRegex}\s+${KeywordRegex}\b") {
      if ($line -notmatch "${TypeRegex}\s+진입\s*\(") {
        $hits += @{ Line = $i + 1; Text = $line }
      }
    }

    if ($line -match "(클래스|구조체)\s+${KeywordRegex}\b") {
      $hits += @{ Line = $i + 1; Text = $line }
    }
  }

  if ($hits.Count -gt 0) {
    Write-Host '[K++] 키워드 충돌 감지(--safe):' -ForegroundColor Red
    foreach ($h in $hits) {
      Write-Host "  - ${SourceFile}:$($h.Line) -> $($h.Text)" -ForegroundColor Red
    }
    Write-Host '  팁: 변수/함수/클래스 이름을 키워드와 겹치지 않게 바꿔주세요.' -ForegroundColor Yellow
    return $false
  }

  return $true
}

function Ensure-RequiredHeaders([string]$CppPath) {
  $raw = Get-Content -Raw -Path $CppPath
  $required = New-Object System.Collections.Generic.List[string]

  $rules = @(
    @{ Header = 'iostream'; Pattern = '\b(cout|cin|endl)\b' },
    @{ Header = 'string'; Pattern = '\bstring\b' },
    @{ Header = 'vector'; Pattern = '\bvector\b' },
    @{ Header = 'array'; Pattern = '\barray\b' },
    @{ Header = 'list'; Pattern = '\blist\b' },
    @{ Header = 'deque'; Pattern = '\bdeque\b' },
    @{ Header = 'queue'; Pattern = '\b(queue|priority_queue)\b' },
    @{ Header = 'stack'; Pattern = '\bstack\b' },
    @{ Header = 'map'; Pattern = '\bmap\b' },
    @{ Header = 'set'; Pattern = '\bset\b' },
    @{ Header = 'unordered_map'; Pattern = '\bunordered_map\b' },
    @{ Header = 'unordered_set'; Pattern = '\bunordered_set\b' },
    @{ Header = 'utility'; Pattern = '\bpair\b' },
    @{ Header = 'algorithm'; Pattern = '\b(sort|unique|find|min_element|max_element|reverse|swap|count)\b' },
    @{ Header = 'numeric'; Pattern = '\baccumulate\b' },
    @{ Header = 'exception'; Pattern = '\b(exception|runtime_error|logic_error|out_of_range)\b' },
    @{ Header = 'stdexcept'; Pattern = '\b(runtime_error|logic_error|out_of_range|invalid_argument)\b' }
  )

  foreach ($r in $rules) {
    $includePattern = "(?m)^\s*#include\s*<$($r.Header)>\s*$"
    if ($raw -match $includePattern) {
      continue
    }
    if ($raw -match $r.Pattern) {
      [void]$required.Add($r.Header)
    }
  }

  $unique = @($required | Select-Object -Unique)
  if ($unique.Count -eq 0) {
    return
  }

  $prefix = ($unique | ForEach-Object { "#include <$_>" }) -join "`n"
  $updated = "$prefix`n$raw"
  Set-Content -Path $CppPath -Value $updated -Encoding UTF8
  Write-Host "[K++] 누락 헤더 자동 추가: $($unique -join ' ')"
}

function Show-KoreanCompileError([string]$ErrorPath) {
  $line = (Select-String -Path $ErrorPath -Pattern 'error:' | Select-Object -First 1)
  if (-not $line) {
    Get-Content $ErrorPath | Write-Error
    return
  }

  $text = $line.Line
  if ($text -match '^(.*?):(\d+):(\d+):\s*error:\s*(.*)$') {
    Write-Host '[K++] 컴파일 실패' -ForegroundColor Red
    Write-Host "  위치: $($matches[1]):$($matches[2]):$($matches[3])" -ForegroundColor Red
    Write-Host "  원인: $($matches[4])" -ForegroundColor Red
    Write-Host '  팁: 문법, 세미콜론, 괄호, 필요한 헤더를 확인해보세요.' -ForegroundColor Yellow
  } else {
    Write-Host '[K++] 컴파일 실패' -ForegroundColor Red
    Get-Content $ErrorPath | Write-Host
  }
}

if ($args.Count -lt 1) {
  Show-Usage
  exit 1
}

$runAfter = $false
$safeMode = $false
$toStdout = $false
$inputFile = ''
$outputCpp = ''
$kppcArgs = New-Object System.Collections.Generic.List[string]

$i = 0
while ($i -lt $args.Count) {
  $arg = $args[$i]
  switch ($arg) {
    'init' {
      $target = 'main.kpp'
      if ($i + 1 -lt $args.Count -and -not $args[$i + 1].StartsWith('-')) {
        $target = $args[$i + 1]
      }
      New-InitFile $target
      exit 0
    }
    '--help' { Show-Usage; exit 0 }
    '-h' { Show-Usage; exit 0 }
    '--run' { $runAfter = $true; $i++; continue }
    '--safe' { $safeMode = $true; $i++; continue }
    '--collision-check' { $safeMode = $true; $i++; continue }
    '--stdout' { $toStdout = $true; [void]$kppcArgs.Add($arg); $i++; continue }
    '-o' {
      if ($i + 1 -ge $args.Count) {
        Write-Error '[K++] 오류: -o 값이 필요합니다.'
      }
      $outputCpp = $args[$i + 1]
      [void]$kppcArgs.Add($arg)
      [void]$kppcArgs.Add($outputCpp)
      $i += 2
      continue
    }
    default {
      if ($arg.StartsWith('-')) {
        [void]$kppcArgs.Add($arg)
      } else {
        if (-not $inputFile) {
          $inputFile = $arg
        }
        [void]$kppcArgs.Add($arg)
      }
      $i++
      continue
    }
  }
}

if (-not $inputFile) {
  Write-Host '[K++] 오류: input.kpp 파일이 필요합니다.' -ForegroundColor Red
  Show-Usage
  exit 1
}

if ($runAfter -and $toStdout) {
  Write-Host '[K++] 오류: --run 과 --stdout 은 함께 사용할 수 없습니다.' -ForegroundColor Red
  exit 1
}

if ($safeMode) {
  if (-not (Find-KeywordCollisions $inputFile)) {
    exit 1
  }
}

if (Needs-Rebuild) {
  Write-Host '[K++] kppc 자동 빌드 중...'
  Build-Kppc
}

& $KppBin @kppcArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if ($runAfter) {
  if ($outputCpp) {
    $cppPath = $outputCpp
  } else {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
    $cppPath = Join-Path $CppDir "$baseName.cpp"
  }

  Ensure-RequiredHeaders $cppPath

  $stem = [System.IO.Path]::GetFileNameWithoutExtension($cppPath)
  $exePath = Join-Path $BinDir "$stem.exe"

  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  $compileLog = [System.IO.Path]::GetTempFileName()

  try {
    & g++ -std=c++17 $cppPath -o $exePath 2> $compileLog
    if ($LASTEXITCODE -ne 0) {
      Show-KoreanCompileError $compileLog
      exit 1
    }
  } finally {
    Remove-Item -ErrorAction SilentlyContinue $compileLog
  }

  Write-Host "[K++] 실행 파일: $exePath"
  & $exePath
  exit $LASTEXITCODE
}
