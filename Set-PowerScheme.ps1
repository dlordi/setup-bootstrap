if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Script must be run as Administrator.'
}

$planName = 'Caffeine'
$planGuid = $null

# GUID dictionary
$GUIDs = @{
    SUB_SLEEP     = '238C9FA8-0AAD-41ED-83F4-97BE242C8F20'
    SLEEP_IDLE    = '29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA'
    HIBERNATE     = '9D7815A6-7EE4-497E-8888-515A05F02364'
    SUB_DISK      = '0012EE47-9041-4B5D-9B77-535FBA8B1442'
    DISKIDLE      = '6738E2C4-E8A5-4A42-B16A-E040E769756E'
    SUB_PROCESSOR = '54533251-82BE-4824-96C1-47B60B740D00'
    PROC_MIN      = '893DEE8E-2BEF-41E0-89C6-B55D0929964C'
    PROC_MAX      = 'BC5038F7-23E0-4960-96DA-33ABAF5935EC'
}

function Invoke-PowerCfg {
    param([string[]] $params)

    $out = & powercfg @params 2>&1
    if ($LASTEXITCODE -ne 0) { throw "powercfg $($params -join ' ') failed: $out" }
    return $out
}

function Set-Setting {
    param(
        [Parameter(Mandatory)][string] $schemeGuid,
        [Parameter(Mandatory)][string] $subGroupGuid,
        [Parameter(Mandatory)][string] $settingGuid,
        [Parameter()][string] $acValue,
        [Parameter()][string] $dcValue
    )

    if ($null -ne $acValue) {
        Invoke-PowerCfg @('/SETACVALUEINDEX', $schemeGuid, $subGroupGuid, $settingGuid, $acValue)
    }
    if ($null -ne $dcValue) {
        Invoke-PowerCfg @('/SETDCVALUEINDEX', $schemeGuid, $subGroupGuid, $settingGuid, $dcValue)
    }
}

try {
    if (-not (Get-Command powercfg -ErrorAction SilentlyContinue)) { throw 'powercfg not found in PATH.' }

    # detect currently active power configuration scheme
    $listOut = Invoke-PowerCfg @('/LIST')
    $activeLines = @($listOut -split [Environment]::NewLine | Where-Object { $_ -match '[0-9a-fA-F\-]{36}.*\*' })
    if ($activeLines.Count -eq 0) { throw "Unable to find an active power scheme line marked with '*'." }
    if ($activeLines.Count -gt 1) { throw "Multiple lines marked with '*'. Aborting to avoid ambiguity." }
    $activeLine = $activeLines[0]

    # extract GUID from active scheme
    if ($activeLine -match '([0-9a-fA-F\-]{36})') {
        $baseGuid = $matches[1]
    } else { throw "Unable to extract the GUID from the active line: $activeLine" }

    # duplicate active scheme using different name
    $dupOut = Invoke-PowerCfg @('/DUPLICATESCHEME', $baseGuid)
    if ($dupOut -match '([0-9a-fA-F\-]{36})') {
        $planGuid = $matches[1]
    } else {
        throw "Unable to duplicate the base power scheme: $dupOut"
    }
    Invoke-PowerCfg @('/CHANGENAME', $planGuid, $planName)

    # customize new schema
    # - never sleep/hibernate
    Set-Setting $planGuid $GUIDs.SUB_SLEEP $GUIDs.SLEEP_IDLE 0 0
    Set-Setting $planGuid $GUIDs.SUB_SLEEP $GUIDs.HIBERNATE 0 0
    # - never turn off disk
    Set-Setting $planGuid $GUIDs.SUB_DISK $GUIDs.DISKIDLE 0 0
    # - set processor always at 100%
    Set-Setting $planGuid $GUIDs.SUB_PROCESSOR $GUIDs.PROC_MIN 100 100
    Set-Setting $planGuid $GUIDs.SUB_PROCESSOR $GUIDs.PROC_MAX 100 100

    # apply the new plan
    Invoke-PowerCfg @('/SETACTIVE', $planGuid)

    Write-Output "Power plan '$planName' applied"
} catch {
    Write-Error "ERROR: $($_.Exception.Message)"
    exit 1
}
