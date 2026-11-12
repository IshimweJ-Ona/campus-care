[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectId = 'campuscare-61579'
$email = 'staff.test@campuscare.dev'
$authBase = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1'
$firestoreBase = 'http://127.0.0.1:8080'
$apiKey = 'fake-api-key'
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Read-AccountPassword {
    $securePassword = Read-Host 'Enter a password for the local Staff Test account' -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

$password = Read-AccountPassword
if ($password.Length -lt 8) {
    throw 'The emulator password must contain at least 8 characters.'
}

$signUpUri = "$authBase/accounts:signUp?key=$apiKey"
$signInUri = "$authBase/accounts:signInWithPassword?key=$apiKey"
$authBody = @{
    email = $email
    password = $password
    returnSecureToken = $true
}

try {
    $auth = Invoke-RestMethod -Method Post -Uri $signUpUri `
        -ContentType 'application/json' -Body ($authBody | ConvertTo-Json)
}
catch {
    if ($_.ErrorDetails.Message -notmatch 'EMAIL_EXISTS') {
        throw "Could not create the Staff Test account in the Auth emulator: $($_.ErrorDetails.Message)"
    }

    $auth = Invoke-RestMethod -Method Post -Uri $signInUri `
        -ContentType 'application/json' -Body ($authBody | ConvertTo-Json)
}

$verifiedAccount = @{
    idToken = $auth.idToken
    emailVerified = $true
    displayName = 'Staff Test'
    returnSecureToken = $true
}
$auth = Invoke-RestMethod -Method Post `
    -Uri "$authBase/accounts:update?key=$apiKey" `
    -ContentType 'application/json' `
    -Body ($verifiedAccount | ConvertTo-Json)

$rules = Get-Content -Raw -Path (Join-Path $repositoryRoot 'firestore.rules')
$productionGate = @'
    function hasVerifiedAluEmail() {
      return request.auth != null &&
        request.auth.token.email is string &&
        request.auth.token.email_verified == true &&
        request.auth.token.email.matches(
          '^[^@]+@(alustudent\\.com|alustaff\\.com)$'
        );
    }
'@
$emulatorGate = @'
    function hasVerifiedAluEmail() {
      return request.auth != null &&
        request.auth.token.email is string &&
        request.auth.token.email_verified == true &&
        (
          request.auth.token.email.matches(
            '^[^@]+@(alustudent\\.com|alustaff\\.com)$'
          ) ||
          request.auth.token.email == 'staff.test@campuscare.dev'
        );
    }
'@

$normalizedRules = $rules.Replace("`r`n", "`n")
$normalizedProductionGate = $productionGate.Replace("`r`n", "`n")
$normalizedEmulatorGate = $emulatorGate.Replace("`r`n", "`n")
if (-not $normalizedRules.Contains($normalizedProductionGate)) {
    throw 'The production email rule differs from the expected rule; refusing to alter emulator authorization.'
}
$emulatorRules = $normalizedRules.Replace(
    $normalizedProductionGate,
    $normalizedEmulatorGate
)

$rulesPayload = @{
    rules = @{
        files = @(
            @{
                name = 'firestore.rules'
                content = $emulatorRules
            }
        )
    }
} | ConvertTo-Json -Depth 5 -Compress
try {
    Invoke-RestMethod -Method Put `
        -Uri "$firestoreBase/emulator/v1/projects/${projectId}:securityRules" `
        -ContentType 'application/json' `
        -Body $rulesPayload | Out-Null
}
catch {
    $errorDetails = $_.ErrorDetails.Message
    if (-not $errorDetails) {
        $errorDetails = $_.Exception.Message
    }
    throw "Could not load the development-only rules into the Firestore emulator. Start Auth and Firestore emulators first. $errorDetails"
}

$profileUri = "$firestoreBase/v1/projects/$projectId/databases/(default)/documents/users/$($auth.localId)?updateMask.fieldPaths=name&updateMask.fieldPaths=email&updateMask.fieldPaths=role&updateMask.fieldPaths=accountStatus&updateMask.fieldPaths=createdAt"
$profile = @{
    fields = @{
        name = @{ stringValue = 'Staff Test' }
        email = @{ stringValue = $email }
        role = @{ stringValue = 'staff' }
        accountStatus = @{ stringValue = 'active' }
        createdAt = @{ timestampValue = [DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'") }
    }
} | ConvertTo-Json -Depth 6

try {
    Invoke-RestMethod -Method Patch -Uri $profileUri `
        -Headers @{ Authorization = 'Bearer owner' } `
        -ContentType 'application/json' -Body $profile | Out-Null
}
catch {
    throw "Could not initialize the Staff Test Firestore profile: $($_.Exception.Message)"
}

Write-Host "Staff Test is ready in the local emulators (UID $($auth.localId))."
Write-Host 'Sign in with staff.test@campuscare.dev and the password entered above.'
Write-Host 'The temporary email rule exists only in this running Firestore emulator.'
