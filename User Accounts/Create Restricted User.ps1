#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates a restricted standard local user on Windows 11 Home.

.DESCRIPTION
    Runs three discrete jobs:
      Job 1 - Create standard local account (not Microsoft; no admin rights)
      Job 2 - Harden C:\Users ACL so sibling profiles are hidden
      Job 3 - Create per-user Programs dir with FullControl

    Each job reports its own status. A failed job halts execution.

.NOTES
    Must be run as Administrator.

.INPUTS
    Username  String
    DisplayName String
    Passwword SecureString
#>

# Configuration
$Username = Read-Host -Prompt "Provide a Username for the Restricted Account"
$DisplayName = Read-Host -Prompt "Provide a display name for '$Username'"
$Password = Read-Host -Prompt "  Set password for '$Username'" -AsSecureString
Write-Host ""

# job runner
function Invoke-Job {
    param(
        [string]   $Name,
        [string]   $Description,
        [scriptblock] $Action
    )

    Write-Host ""
    Write-Host ("JOB: {0,-53}" -f $Name) -ForegroundColor Cyan
    Write-Host ("{0,-57}" -f $Description) -ForegroundColor DarkGray
    Write-Host $("___"*33) -ForegroundColor DarkGray

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        & $Action
        $stopwatch.Stop()
        $elapsed = "{0:N2}s" -f $stopwatch.Elapsed.TotalSeconds
        Write-Host "  DONE  ($elapsed)" -ForegroundColor Green
    }
    catch {
        $stopwatch.Stop()
        Write-Host ""
        Write-Host "  FAILED" -ForegroundColor Red
        Write-Host "     $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Halting — fix the error above and re-run." -ForegroundColor Yellow
        exit 1
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host ("  →  {0}" -f $Message) -ForegroundColor DarkCyan
}

function Write-OK {
    param([string]$Message)
    Write-Host ("     {0}" -f $Message) -ForegroundColor Gray
}


Write-Host ""
Write-Host "  Setup-RestrictedUser" -ForegroundColor White
Write-Host "  Windows 11 Home · 3 jobs · target: $Username" -ForegroundColor DarkGray
Write-Host ""


# ══════════════════════════════════════════════════════════════════════════════
# Job 1 — Create local account
# ══════════════════════════════════════════════════════════════════════════════
Invoke-Job -Name "Create local account" `
           -Description "New-LocalUser + add to BUILTIN\Users" `
           -Action {

    Write-Step "Checking if account already exists..."
    if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
        throw "Account '$Username' already exists. Remove it first or choose a different username."
    }
    Write-OK "Account does not exist — safe to create"

    Write-Step "Creating local user '$Username'..."
    New-LocalUser -Name $Username `
                  -Password $Password `
                  -FullName $DisplayName `
                  -PasswordNeverExpires `
                  -UserMayNotChangePassword:$false | Out-Null
    Write-OK "Account created"

    Write-Step "Adding '$Username' to BUILTIN\Users group..."
    Add-LocalGroupMember -Group "Users" -Member $Username
    Write-OK "Group membership confirmed"

    Write-Step "Verifying account is NOT in Administrators group..."
    $isAdmin = (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue) |
               Where-Object { $_.Name -like "*$Username" }
    if ($isAdmin) {
        throw "Account was unexpectedly found in Administrators. Aborting."
    }
    Write-OK "Confirmed: no admin rights"
}


# ══════════════════════════════════════════════════════════════════════════════
# Job 2 — Harden C:\Users ACL
# ══════════════════════════════════════════════════════════════════════════════
Invoke-Job -Name "Harden C:\Users ACL" `
           -Description "Deny ListDirectory + ReadAttributes for $Username only (no inheritance)" `
           -Action {

    $usersDir  = "C:\Users"
    $identity  = New-Object System.Security.Principal.NTAccount("$env:COMPUTERNAME\$Username")

    Write-Step "Reading current ACL on '$usersDir'..."
    $acl = Get-Acl -Path $usersDir
    Write-OK ("Current ACE count: {0}" -f $acl.Access.Count)

    Write-Step "Checking for existing Deny rule..."
    $existing = $acl.Access | Where-Object {
        $_.IdentityReference -like "*$Username*" -and
        $_.AccessControlType -eq "Deny"
    }
    if ($existing) {
        Write-OK "Deny rule already present — skipping"
    }
    else {
        Write-Step "Building Deny ACE (ListDirectory, ReadAttributes, no inheritance)..."
        $rights    = [System.Security.AccessControl.FileSystemRights]"ListDirectory,ReadAttributes"
        $inherit   = [System.Security.AccessControl.InheritanceFlags]"None"
        $propagate = [System.Security.AccessControl.PropagationFlags]"None"
        $type      = [System.Security.AccessControl.AccessControlType]"Deny"

        $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $identity, $rights, $inherit, $propagate, $type
        )

        $acl.AddAccessRule($denyRule)

        Write-Step "Applying ACL..."
        Set-Acl -Path $usersDir -AclObject $acl
        Write-OK "Deny ACE applied — sibling profiles hidden from '$Username'"
    }

    Write-Step "Verifying ACE was written..."
    $verify = (Get-Acl -Path $usersDir).Access | Where-Object {
        $_.IdentityReference -like "*$Username*" -and
        $_.AccessControlType -eq "Deny"
    }
    if (-not $verify) {
        throw "Verification failed — Deny ACE not found after Set-Acl."
    }
    Write-OK "Verified: Deny ACE present for '$Username'"
}


# ══════════════════════════════════════════════════════════════════════════════
# Job 3 — Create per-user Programs directory
# ══════════════════════════════════════════════════════════════════════════════
Invoke-Job -Name "Create per-user Programs dir" `
           -Description "AppData\Local\Programs with FullControl for $Username" `
           -Action {

    $installDir = "C:\Users\$Username\AppData\Local\Programs"
    $identity   = New-Object System.Security.Principal.NTAccount("$env:COMPUTERNAME\$Username")

    Write-Step "Creating directory '$installDir'..."
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-OK "Directory ready"

    Write-Step "Reading current ACL..."
    $aclProg = Get-Acl -Path $installDir

    Write-Step "Building FullControl Allow ACE (ContainerInherit + ObjectInherit)..."
    $fullRights = [System.Security.AccessControl.FileSystemRights]"FullControl"
    $inheritAll = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
    $propAll    = [System.Security.AccessControl.PropagationFlags]"None"
    $allow      = [System.Security.AccessControl.AccessControlType]"Allow"

    $allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $identity, $fullRights, $inheritAll, $propAll, $allow
    )

    $aclProg.AddAccessRule($allowRule)

    Write-Step "Applying ACL..."
    Set-Acl -Path $installDir -AclObject $aclProg
    Write-OK "FullControl granted — '$Username' can install apps here without elevation"

    Write-Step "Verifying ACE..."
    $verify = (Get-Acl -Path $installDir).Access | Where-Object {
        $_.IdentityReference -like "*$Username*" -and
        $_.AccessControlType -eq "Allow" -and
        $_.FileSystemRights   -match "FullControl"
    }
    if (-not $verify) {
        throw "Verification failed — FullControl ACE not found after Set-Acl."
    }
    Write-OK "Verified: FullControl ACE present"
}


# Summary
Write-Host ""
Write-Host "  ══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  All jobs completed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "  Account  : $Username" -ForegroundColor White
Write-Host "  Type     : Standard local user (no admin, no MS account)" -ForegroundColor Gray
Write-Host "  Privacy  : C:\Users siblings hidden" -ForegroundColor Gray
Write-Host "  Install  : C:\Users\$Username\AppData\Local\Programs" -ForegroundColor Gray
Write-Host "  ══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Verify the Deny ACE anytime with:" -ForegroundColor DarkGray
Write-Host "  (Get-Acl 'C:\Users').Access | Where-Object { `$_.IdentityReference -like '*$Username*' }" -ForegroundColor DarkCyan
Write-Host ""