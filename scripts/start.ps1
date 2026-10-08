# 개발 서버 실행: venv 생성 → 패키지 설치 → .env 준비 → uvicorn
# 사용: powershell -ExecutionPolicy Bypass -File scripts\start.ps1 [-Port 8081] [-NoReload] [-Lan]
#   -Lan: 휴대폰·에뮬레이터 앱이 접속할 수 있게 0.0.0.0으로 실행 (같은 Wi-Fi)
param(
    [int]$Port = 8081,
    [switch]$NoReload,
    [switch]$Lan
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$py = ".venv\Scripts\python.exe"

if (-not (Test-Path $py)) {
    # Python 3.11 이상 확인 후 venv 생성
    python -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)"
    if ($LASTEXITCODE -ne 0) { throw "Python 3.11 이상이 필요합니다." }
    python -m venv .venv
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host ".env를 만들었습니다. 실제 호출하려면 CLOVA_API_KEY와 MOCK_MODE=0을 설정하세요."
}

# 필요한 패키지가 없을 때만 설치 (첫 실행은 인터넷 필요)
# PowerShell 5.1은 Stop 상태에서 native 명령의 stderr를 오류로 보고 멈추므로 이 확인만 Continue로 실행
$ErrorActionPreference = "Continue"
& $py -c "import fastapi, uvicorn, httpx, dotenv, yaml, multipart, PIL, jsonschema" 2>$null
$installed = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = "Stop"
if (-not $installed) {
    & $py -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw "패키지 설치 실패" }
}

$bindHost = "127.0.0.1"
if ($Lan) {
    $bindHost = "0.0.0.0"
    # 앱에 넣을 주소 안내: 기본 게이트웨이가 있는 실제 네트워크(Wi-Fi·이더넷)만 표시 (WSL 등 가상 어댑터 제외)
    $nets = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
        Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq "Up" }
    Write-Host "앱에서 접속할 주소:"
    Write-Host "  Android 에뮬레이터: http://10.0.2.2:$Port"
    foreach ($net in $nets) {
        foreach ($ip in $net.IPv4Address.IPAddress) { Write-Host "  같은 Wi-Fi 휴대폰:  http://${ip}:$Port  ($($net.InterfaceAlias))" }
    }
    Write-Host "휴대폰에서 안 되면 방화벽을 허용하세요 (README 참고)."
}

$uvicornArgs = @("-m", "uvicorn", "app.main:app", "--host", $bindHost, "--port", $Port)
if (-not $NoReload) { $uvicornArgs += "--reload" }
& $py @uvicornArgs
