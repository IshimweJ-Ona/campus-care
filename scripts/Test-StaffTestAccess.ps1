[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectId = 'campuscare-61579'
$authBase = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1'
$firestoreBase = 'http://127.0.0.1:8080'
$apiKey = 'fake-api-key'
$ownerHeaders = @{ Authorization = 'Bearer owner' }

function Read-TestPassword([string] $prompt) {
    $securePassword = Read-Host $prompt -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Get-VerifiedEmulatorAccount([string] $email, [string] $password) {
    $accountBody = @{
        email = $email
        password = $password
        returnSecureToken = $true
    } | ConvertTo-Json
    try {
        return Invoke-RestMethod -Method Post `
            -Uri "$authBase/accounts:signInWithPassword?key=$apiKey" `
            -ContentType 'application/json' -Body $accountBody
    }
    catch {
        if ($_.ErrorDetails.Message -notmatch 'EMAIL_NOT_FOUND') {
            throw
        }
        return Invoke-RestMethod -Method Post `
            -Uri "$authBase/accounts:signUp?key=$apiKey" `
            -ContentType 'application/json' -Body $accountBody
    }
}

function Set-EmulatorDocument(
    [string] $path,
    [hashtable] $fields
) {
    $encodedFields = @{}
    foreach ($field in $fields.GetEnumerator()) {
        if ($field.Value -is [string]) {
            $encodedFields[$field.Key] = @{ stringValue = $field.Value }
        }
        else {
            $encodedFields[$field.Key] = $field.Value
        }
    }
    $body = @{ fields = $encodedFields } | ConvertTo-Json -Depth 8
    Invoke-RestMethod -Method Patch `
        -Uri "$firestoreBase/v1/projects/$projectId/databases/(default)/documents/$path" `
        -Headers $ownerHeaders -ContentType 'application/json' -Body $body | Out-Null
}

function Assert-Denied([scriptblock] $request, [string] $description) {
    try {
        & $request | Out-Null
    }
    catch {
        $status = [int]$_.Exception.Response.StatusCode
        if ($status -eq 403) {
            Write-Host "PASS: $description was denied."
            return
        }
        throw "Expected a Firestore permission denial for '$description', got HTTP $status. $($_.Exception.Message)"
    }
    throw "Expected a Firestore permission denial for '$description', but the request succeeded."
}

$staffPassword = Read-TestPassword 'Staff Test password'
$studentEmail = 'rules.student@alustudent.com'
$studentPassword = Read-TestPassword "Password for $studentEmail"
$staff = Get-VerifiedEmulatorAccount 'staff.test@campuscare.dev' $staffPassword
$student = Get-VerifiedEmulatorAccount $studentEmail $studentPassword

$verifiedStaff = @{
    idToken = $staff.idToken
    emailVerified = $true
    displayName = 'Staff Test'
    returnSecureToken = $true
} | ConvertTo-Json
$staff = Invoke-RestMethod -Method Post `
    -Uri "$authBase/accounts:update?key=$apiKey" `
    -ContentType 'application/json' -Body $verifiedStaff

$verifiedStudent = @{
    idToken = $student.idToken
    emailVerified = $true
    displayName = 'Rules Student'
    returnSecureToken = $true
} | ConvertTo-Json
$student = Invoke-RestMethod -Method Post `
    -Uri "$authBase/accounts:update?key=$apiKey" `
    -ContentType 'application/json' -Body $verifiedStudent

Set-EmulatorDocument "users/$($staff.localId)" @{
    name = 'Staff Test'
    email = 'staff.test@campuscare.dev'
    role = 'staff'
    accountStatus = 'active'
}
Set-EmulatorDocument "users/$($student.localId)" @{
    name = 'Rules Student'
    email = $studentEmail
    role = 'student'
    accountStatus = 'active'
}

$incidentId = "staff-access-$([Guid]::NewGuid().ToString('N'))"
$now = [DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")
Set-EmulatorDocument "incidents/$incidentId" @{
    category = 'Maintenance'
    location = 'Test location'
    description = 'Staff access rules test'
    status = 'pending'
    createdAt = @{ timestampValue = $now }
    updatedAt = @{ timestampValue = $now }
    photoUrl = @{ nullValue = $null }
}
Set-EmulatorDocument "incident_reporters/$incidentId" @{
    incidentId = $incidentId
    reporterId = $student.localId
    reporterName = 'Rules Student'
    reporterEmail = $studentEmail
    createdAt = @{ timestampValue = $now }
}

$incidentsUri = "$firestoreBase/v1/projects/$projectId/databases/(default)/documents/incidents"
$reporterUri = "$firestoreBase/v1/projects/$projectId/databases/(default)/documents/incident_reporters/$incidentId"
$staffHeaders = @{ Authorization = "Bearer $($staff.idToken)" }
$studentHeaders = @{ Authorization = "Bearer $($student.idToken)" }

Invoke-RestMethod -Method Get -Uri $incidentsUri -Headers $staffHeaders | Out-Null
Write-Host 'PASS: Staff Test can list all incident reports.'
Invoke-RestMethod -Method Get -Uri $reporterUri -Headers $staffHeaders | Out-Null
Write-Host 'PASS: Staff Test can read private reporter information.'

$commitUri = "$firestoreBase/v1/projects/$projectId/databases/(default)/documents:commit"
$staffUpdate = @{
    writes = @(@{
        update = @{
            name = "projects/$projectId/databases/(default)/documents/incidents/$incidentId"
            fields = @{ status = @{ stringValue = 'in_progress' } }
        }
        updateMask = @{ fieldPaths = @('status') }
        updateTransforms = @(@{
            fieldPath = 'updatedAt'
            setToServerValue = 'REQUEST_TIME'
        })
        currentDocument = @{ exists = $true }
    })
} | ConvertTo-Json -Depth 8
Invoke-RestMethod -Method Post -Uri $commitUri -Headers $staffHeaders `
    -ContentType 'application/json' -Body $staffUpdate | Out-Null
Write-Host 'PASS: Staff Test can update incident status.'

Invoke-RestMethod -Method Get -Uri $incidentsUri -Headers $studentHeaders | Out-Null
Write-Host 'PASS: Active students can read incident reports.'

Assert-Denied {
    Invoke-RestMethod -Method Get -Uri $reporterUri -Headers $studentHeaders
} 'student access to private reporter information'

$studentUpdate = @{
    writes = @(@{
        update = @{
            name = "projects/$projectId/databases/(default)/documents/incidents/$incidentId"
            fields = @{ status = @{ stringValue = 'resolved' } }
        }
        updateMask = @{ fieldPaths = @('status') }
        updateTransforms = @(@{
            fieldPath = 'updatedAt'
            setToServerValue = 'REQUEST_TIME'
        })
        currentDocument = @{ exists = $true }
    })
} | ConvertTo-Json -Depth 8
Assert-Denied {
    Invoke-RestMethod -Method Post -Uri $commitUri -Headers $studentHeaders `
        -ContentType 'application/json' -Body $studentUpdate
} 'student incident status updates'

Write-Host 'All Staff Test access checks passed.'
