# setup-bootstrap

## operazioni da eseguire durante l'installazione interattiva/attended

- collegarsi all'hotspot dello smartphone
  - la password va digitata a mano...
  - scegliere di **NON** collegarsi automaticamente al wifi/hotspot
  - scegliere di essere visibili all'interno della rete

- **CREARE ACCOUNT LOCALE (WINDOWS 11)**
  - alla richiesta di creare un account online, premere `Shift+F10`
  - nel prompt dei comandi che si apre eseguire
    ```bat
    start ms-cxh:localonly
    ```
  - si apre la classica finestra in cui si può creare un account locale senza doverne fare uno online

## operazioni da eseguire dopo che Windows ha finito l'installazione

- per cambiare il nome del PC eseguire questo comando **IN POWERSHELL COME AMMINISTRATORE**:

  ```ps1
  # hostname # comando per visualizzare il nome attuale del PC
  Rename-Computer -NewName 'nuovo-nome-PC' # BISOGNA RIAVVIARE IL PC!!
  ```

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
  $ProgressPreference = 'SilentlyContinue'
  Add-AppxPackage -Path 'https://github.com/microsoft/winget-cli/releases/download/v1.28.220/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'

  # se il comando di cui sopra va in errore perché mancano delle dipendenze eseguire questi comandi e provare di nuovo
  # Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/download/v1.28.240/DesktopAppInstaller_Dependencies.zip -OutFile "$env:USERPROFILE\Downloads\DesktopAppInstaller_Dependencies.zip"
  # Expand-Archive "$env:USERPROFILE\Downloads\DesktopAppInstaller_Dependencies.zip" -DestinationPath "$env:USERPROFILE\Downloads\DesktopAppInstaller_Dependencies"
  # Add-AppxPackage -Path "$env:USERPROFILE\Downloads\DesktopAppInstaller_Dependencies\x64\*.appx"
  #
  # sito alternativo (non ufficiale) da cui poter scaricare parte delle dipendenze richieste se i comandi precedenti non dovessero funzionare
  # https://github.com/M1k3G0/Win10_LTSC_VP9_Installer
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
