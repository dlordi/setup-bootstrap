<#
.SYNOPSIS
  Set a registry value (idempotent)

.PARAMETER FullPath
  Full registry path, es:
    - HKCU\SOFTWARE\MyApp\SubKey
    - HKEY_CURRENT_USER\SOFTWARE\MyApp\SubKey
    - HKLM\SOFTWARE\MyApp
    - HKEY_LOCAL_MACHINE\SOFTWARE\MyApp

.PARAMETER Name
  Name of the registry value (stringa). Use '' for the Default value.

.PARAMETER Value
  Value (supported types: string, int, string[] for MultiString, byte[] for Binary).

.PARAMETER Type
  Type: 'DWord', 'String', 'ExpandString', 'MultiString', 'Binary'.

.EXAMPLE
  PS> Import-Module .\Set-RegistryValue.psm1; Set-RegistryValue `
    -FullPath 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
    -Name 'ForceClassicControlPanel' -Type DWord -Value 1
#>

function Set-RegistryValue {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][AllowNull()][Object]$Value,
        [Parameter(Mandatory = $true)][ValidateSet('DWord', 'String', 'ExpandString', 'MultiString', 'Binary')][string]$Type
    )

    # Normalize FullPath and split it into hive + subpath
    $pattern = '^(HKEY_CURRENT_USER|HKCU|HKEY_LOCAL_MACHINE|HKLM)\\(.*)$'
    if ($FullPath -notmatch $pattern) {
        throw 'FullPath invalid. Expected format: HKCU\Sub\Path or HKEY_CURRENT_USER\Sub\Path (case-insensitive).'
    }

    $hiveToken = $matches[1].ToUpper()
    $subPath = $matches[2].TrimStart('\')

    switch ($hiveToken) {
        'HKCU' { $hiveCanonical = 'HKCU' }
        'HKEY_CURRENT_USER' { $hiveCanonical = 'HKCU' }
        'HKLM' { $hiveCanonical = 'HKLM' }
        'HKEY_LOCAL_MACHINE' { $hiveCanonical = 'HKLM' }
        default { throw "Hive not supported: $hiveToken" }
    }

    # Map hive into provider root and .NET root
    switch ($hiveCanonical) {
        'HKCU' {
            $psRoot = 'HKCU:'
            $dotNetRoot = [Microsoft.Win32.Registry]::CurrentUser
        }
        'HKLM' {
            $psRoot = 'HKLM:'
            $dotNetRoot = [Microsoft.Win32.Registry]::LocalMachine
        }
    }

    $psPath = Join-Path -Path $psRoot -ChildPath $subPath

    try {
        # Ensure key exists (PowerShell provider)
        Invoke-WithRetry -Action {
            if (-not (Test-Path -Path $psPath)) {
                New-Item -Path $psPath -Force | Out-Null
            }
        } -OperationName "Ensure-Key-$psPath"

        # Get existing value (if present) by provider
        $existing = Invoke-WithRetry -Action {
            Get-ItemProperty -Path $psPath -Name $Name -ErrorAction SilentlyContinue
        } -OperationName "Get-ItemProperty-$psPath-$Name"

        # Map Type -> RegistryValueKind
        $kindMap = @{
            'DWord'        = [Microsoft.Win32.RegistryValueKind]::DWord
            'String'       = [Microsoft.Win32.RegistryValueKind]::String
            'ExpandString' = [Microsoft.Win32.RegistryValueKind]::ExpandString
            'MultiString'  = [Microsoft.Win32.RegistryValueKind]::MultiString
            'Binary'       = [Microsoft.Win32.RegistryValueKind]::Binary
        }
        $expectedKind = $kindMap[$Type]

        if ($null -eq $existing) {
            # Create key and set value by .NET API
            Invoke-WithRetry -Action {
                $regKey = $dotNetRoot.CreateSubKey($subPath)
                if ($null -eq $regKey) { throw "Unable to create/open .NET key: $subPath" }
                $regKey.SetValue($Name, $Value, $expectedKind)
                $regKey.Close()
                return $true
            } -OperationName "Create-And-Set-$subPath-$Name"

            Write-Output (Write-Result -changed $true -currentValue $Value -message "Value created")
            return $true
        }

        $currentValue = $existing.$Name

        # Get type by .NET API
        $regValueKind = Invoke-WithRetry -Action {
            $regKey = $dotNetRoot.OpenSubKey($subPath, $false)
            if ($null -eq $regKey) { throw "Unable to open .NET key for reading: $subPath" }
            $k = $regKey.GetValueKind($Name) 2>$null
            $regKey.Close()
            return $k
        } -OperationName "GetValueKind-$subPath-$Name"

        $normCurrent = Normalize $currentValue $regValueKind
        $normDesired = Normalize $Value $expectedKind

        $isEqual = $false
        if ($regValueKind -eq $expectedKind) {
            if ($expectedKind -eq [Microsoft.Win32.RegistryValueKind]::MultiString) {
                $isEqual = ((@($normCurrent) -join "|") -eq (@($normDesired) -join "|"))
            } elseif ($expectedKind -eq [Microsoft.Win32.RegistryValueKind]::Binary) {
                $isEqual = ($normCurrent -ceq $normDesired)
            } else {
                $isEqual = ($normCurrent -eq $normDesired)
            }
        }

        if ($isEqual) {
            Write-Output (Write-Result -changed $false -currentValue $currentValue -message 'NO change required; value and type already match')
            return $true
        }

        # Change value/type using .NET
        Invoke-WithRetry -Action {
            $regKey = $dotNetRoot.OpenSubKey($subPath, $true)
            if ($null -eq $regKey) { throw "Unable to open .NET key for writing: $subPath" }
            $regKey.SetValue($Name, $Value, $expectedKind)
            $regKey.Close()
            return $true
        } -OperationName "SetValue-$subPath-$Name"

        # Check
        $verifyResult = Invoke-WithRetry -Action {
            $verifyKey = $dotNetRoot.OpenSubKey($subPath, $false)
            if ($null -eq $verifyKey) { throw "Unable to open .NET key for checking: $subPath" }
            $verifyValue = $verifyKey.GetValue($Name)
            $verifyKind = $verifyKey.GetValueKind($Name)
            $verifyKey.Close()
            return @{ Value = $verifyValue; Kind = $verifyKind }
        } -OperationName "Verify-$subPath-$Name"

        $verifyValue = $verifyResult.Value
        $verifyKind = $verifyResult.Kind

        $normVerify = Normalize $verifyValue $verifyKind

        $success = $false
        if ($verifyKind -eq $expectedKind) {
            if ($verifyKind -eq [Microsoft.Win32.RegistryValueKind]::MultiString) {
                $success = ((@($normVerify) -join "|") -eq (@($normDesired) -join "|"))
            } elseif ($verifyKind -eq [Microsoft.Win32.RegistryValueKind]::Binary) {
                $success = ($normVerify -ceq $normDesired)
            } else {
                $success = ($normVerify -eq $normDesired)
            }
        }

        if ($success) {
            Write-Output (Write-Result -changed $true -currentValue $verifyValue -message 'Value update successfully')
            return $true
        } else {
            throw "Check failed after writing. Value read: $verifyValue (type: $verifyKind)"
        }

    } catch {
        $err = $_.Exception.Message
        Write-Output (Write-Result -changed $false -currentValue $null -message 'ERROR' -errorMessage $err)
        return $false
    }

}

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxAttempts = 5,
        [int]$InitialDelayMs = 200,
        [string]$OperationName = 'op'
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $start = Get-Date
            $result = & $Action
            Write-Host "[OK] $OperationName attempt $attempt succeeded (elapsed: $((Get-Date) - $start).TotalMilliseconds)ms"
            return $result
        } catch {
            $err = $_.Exception.Message
            Write-Warning "[WARN] $OperationName attempt $attempt failed: $err"
            if ($attempt -eq $MaxAttempts) {
                Write-Error "[ERR] $OperationName failed after $MaxAttempts attempts"
                throw
            }
            $delay = [int]($InitialDelayMs * [math]::Pow(2, $attempt - 1))
            Start-Sleep -Milliseconds $delay
        }
    }
}

function Write-Result {
    param($changed, $currentValue, $message, $errorMessage = $null)

    $obj = [PSCustomObject]@{
        Changed      = $changed
        CurrentValue = $currentValue
        Message      = $message
        Error        = $errorMessage
    }
    $obj | ConvertTo-Json -Depth 6
}

function Normalize($val, [Microsoft.Win32.RegistryValueKind]$kind) {
    if ($null -eq $val) { return $null }
    switch ($kind) {
        'MultiString' { return , @($val) }
        'Binary' { return , @($val) }
        default { return $val }
    }
}

Export-ModuleMember -Function Set-RegistryValue
