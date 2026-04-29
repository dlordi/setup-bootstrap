<#
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "Import-Module .\Set-RemoteDesktop.psm1; Set-RemoteDesktop $true"
#>

function Set-RemoteDesktop {
    param([bool]$enable)

    try {
        $rdpKey = 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server'
        if (-not (Test-Path "Registry::$rdpKey")) {
            Write-Warning 'Remote Desktop registry key not found; feature may not be supported on this edition.'
            return
        }
        # fDenyTSConnections: 0 = allow RDP, 1 = deny RDP
        Set-ItemProperty -Path "Registry::$rdpKey" -Name 'fDenyTSConnections' -Value ([int](-not $enable)) -ErrorAction Stop

        # Firewall rules: attempt to enable/disable built-in Remote Desktop rules
        if (Get-Command 'Get-NetFirewallRule' -ErrorAction SilentlyContinue) {
            $rules = Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
            $enumVal = if ($enable) {
                'True'
            } else {
                'False'
            }
            # $enumVal = if ($enable) {
            #     [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Enabled]::Enabled
            # } else {
            #     [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Enabled]::Disabled
            # }
            if ($rules) {
                $rules | Set-NetFirewallRule -Enabled $enumVal -ErrorAction SilentlyContinue
            } else {
                # fallback to common rule names
                $common = @('RemoteDesktop-UserMode-In-TCP', 'RemoteDesktop-UserMode-In-TCP-NoScope')
                foreach ($n in $common) {
                    if (Get-NetFirewallRule -Name $n -ErrorAction SilentlyContinue) {
                        try {
                            Set-NetFirewallRule -Name $n -Enabled $enumVal -ErrorAction Stop
                            Write-Verbose "Firewall rule '$n' set to $enumVal"
                        } catch {
                            Write-Warning "Unable to update firewall rule '$n': $_"
                        }
                    }
                }
            }
        } else {
            Write-Warning 'NetFirewall cmdlets not available; firewall rules not modified.'
        }

        # Ensure TermService exists; if enabling, set to Automatic and start
        $term = Get-Service -Name 'TermService' -ErrorAction SilentlyContinue
        if (-not $term) {
            Write-Warning 'Terminal Services (TermService) not found; Remote Desktop may not be supported.'
        } else {
            if ($enable) {
                try {
                    Set-Service -Name 'TermService' -StartupType 'Automatic' -ErrorAction Stop
                    Start-Service -Name 'TermService' -ErrorAction Stop
                    Write-Verbose 'TermService set to Automatic and started.'
                } catch {
                    Write-Warning "Unable to start TermService: $_"
                }
            } else {
                try {
                    # reload service status before stopping
                    $term = Get-Service -Name 'TermService' -ErrorAction Stop
                    if ($term.Status -ne 'Stopped') {
                        Stop-Service -Name 'TermService' -Force -ErrorAction Stop
                        Write-Verbose 'TermService stopped.'
                    }
                    Set-Service -Name 'TermService' -StartupType 'Disabled' -ErrorAction Stop
                    Write-Verbose 'TermService set to Disabled.'
                } catch {
                    Write-Warning "Unable to disable/stop TermService: $_"
                }
            }
        }

        Write-Output "Remote Desktop $(if ($enable) { 'enabled' } else { 'disabled' }) (computer name: $env:COMPUTERNAME)."
    } catch {
        Write-Warning "Failed to modify Remote Desktop settings: $_"
    }
}

Export-ModuleMember -Function Set-RemoteDesktop
