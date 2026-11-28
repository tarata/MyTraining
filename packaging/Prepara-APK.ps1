$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$tools = Join-Path $root 'strumenti'
$keys = Join-Path $env:LOCALAPPDATA 'RUOSS\FirmaTest'
$p12 = Join-Path $keys 'test.p12'
$pass = Join-Path $keys 'password.dpapi'
$pin = Join-Path $keys 'certificato.sha256'
$java = Join-Path $tools 'java\bin\java.exe'
$keytool = Join-Path $tools 'java\bin\keytool.exe'
$jar = Join-Path $tools 'apksigner.jar'
$mutex = [Threading.Mutex]::new($false,'Local\RUOSS_FirmaTest')
if (!$mutex.WaitOne(0)) { throw 'Firma in corso.' }
try {
    if (!(Test-Path $keys)) {
        New-Item -ItemType Directory $keys | Out-Null
        $bytes = New-Object byte[] 48
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        $cred = ConvertTo-SecureString ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
        ConvertFrom-SecureString $cred | Set-Content -Encoding ASCII $pass
        $create = $true
    }
    $secure = (Get-Content -Raw $pass).Trim() | ConvertTo-SecureString
    $env:RUOSS_TEST_PASSWORD = [PSCredential]::new('ruoss',$secure).GetNetworkCredential().Password
    if ($create) {
        & $keytool -genkeypair -storetype PKCS12 -keystore $p12 -storepass:env RUOSS_TEST_PASSWORD -alias ruoss-test -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=RUOSS APK Test'
        if ($LASTEXITCODE) { throw 'Creazione chiave fallita.' }
    }
    $pending = Join-Path $root 'RUOSS-in-preparazione.apk'
    & $java -jar $jar sign --ks $p12 --ks-key-alias ruoss-test --ks-pass env:RUOSS_TEST_PASSWORD --v4-signing-enabled false --out $pending "$tools\base.apk"
    if ($LASTEXITCODE) { throw 'Firma fallita.' }
    $result = & $java -jar $jar verify --verbose --print-certs $pending
    if ($LASTEXITCODE) { throw 'Verifica fallita.' }
    $digest = [regex]::Match(($result -join ' '),'certificate SHA-256 digest: ([a-fA-F0-9]{64})').Groups[1].Value
    if (!$digest) { throw 'Certificato illeggibile.' }
    if (Test-Path $pin) {
        if ((Get-Content -Raw $pin).Trim() -ne $digest) { throw 'Firma diversa dalla precedente.' }
    } else { Set-Content -Encoding ASCII $pin -Value $digest }
    $out = Join-Path $root 'RUOSS-3.2.apk'
    Move-Item -Force -LiteralPath $pending -Destination $out
    Write-Host "APK verificato: $out"
    Write-Host "Firma per gli aggiornamenti: $keys"
} finally {
    Remove-Item Env:RUOSS_TEST_PASSWORD -ErrorAction SilentlyContinue
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}