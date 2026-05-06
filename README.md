# setup-bootstrap

- collegarsi all'hotspot dello smartphone
  - la password va digitata a mano...
  - scegliere di **NON** collegarsi automaticamente al wifi/hotspot
  - scegliere di essere visibili all'interno della rete
- per disabilitare la telemetria di Windows, scaricare [questo script](./Set-RegistryValue.psm1) che va eseguito **IN POWERSHELL COME AMMINISTRATORE** con questi comandi:
  ```ps1
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  Import-Module "$env:USERPROFILE\Downloads\Set-RegistryValue.psm1"
  Set-RegistryValue -FullPath HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection -Name AllowTelemetry -Type DWord -Value 0
  ```
- per applicare la configurazione di risparmio energetico che evita di andare in standby, scaricare [questo script](./Set-PowerScheme.psm1) che va eseguito **IN POWERSHELL COME AMMINISTRATORE** con questi comandi:
  ```ps1
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  Import-Module "$env:USERPROFILE\Downloads\Set-PowerScheme.psm1"
  Set-PowerScheme
  ```
- se si vuole continuare la configurazione da una sessione di desktop remoto, abilitarla con [questo script](./Set-RemoteDesktop.psm1) che va eseguito **IN POWERSHELL COME AMMINISTRATORE** con questi comandi:
  ```ps1
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  Import-Module "$env:USERPROFILE\Downloads\Set-RemoteDesktop.psm1"
  Set-RemoteDesktop $true
  ```
- se `winget` non fosse disponibile, installarlo eseguendo **IN POWERSHELL COME AMMINISTRATORE** questi comandi (ed eventualmente facendo un riavvio)
  ```ps1
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  Add-AppxPackage -Path 'https://github.com/microsoft/winget-cli/releases/download/v1.28.220/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'

  # se il comando di cui sopra va in errore perché manca Windows App Runtime eseguire questi comandi e provare nuovamente
  # Invoke-WebRequest -Uri https://aka.ms/windowsappsdk/1.8/latest/windowsappruntimeinstall-x64.exe -OutFile "$env:USERPROFILE\Downloads\windowsappruntimeinstall-x64.exe"
  # Start-Process "$env:USERPROFILE\Downloads\windowsappruntimeinstall-x64.exe" -ArgumentList '--quiet' -Wait -Verb RunAs
  ```
- installare keepass con il comando
  ```bat
  winget install --source winget --interactive --exact --id DominikReichl.KeePass
  ```
- inserire la chiavetta USB e rinominarla in `J:` (usare il comando `diskmgmt.msc`)
- aprire il file delle password presente nella chiavetta USB
- [accedere a github](https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fdlordi) con una **finestra anonima/inprivate** di edge
  - bisogna accedere anche a gmail per inserire il codice di convalida di github
- continuare l'installazione tramite la [guida](https://github.com/dlordi/how-to/blob/main/win-setup/README.md) presente nel repo [`how-to`](https://github.com/dlordi/how-to)
- applicare le configurazioni del repo [`config`](https://github.com/dlordi/config)
