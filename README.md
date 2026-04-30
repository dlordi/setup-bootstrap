# setup-bootstrap

- collegarsi all'hotspot dello smartphone
  - la password va digitata a mano...
  - scegliere di **NON** collegarsi automaticamente al wifi/hotspot
  - scegliere di essere visibili all'interno della rete
- per applicare la configurazione di risparmio energetico che evita di andare in standby, scaricare [questo script](./Set-PowerScheme.ps1) che va eseguito **COME AMMINISTRATORE** con questo comando:
  ```bat
  powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command 'Import-Module "$env:USERPROFILE\Downloads\Set-PowerScheme.psm1"; Set-PowerScheme'
  ```
- se si vuole continuare la configurazione da una sessione di desktop remoto, abilitarla con [questo script](./Set-RemoteDesktop.psm1) che va eseguito **COME AMMINISTRATORE** con questo comando:
  ```bat
  powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command 'Import-Module "$env:USERPROFILE\Downloads\Set-RemoteDesktop.psm1"; Set-RemoteDesktop $true'
  ```
- installare keepass con il comando `winget install --source winget --interactive --exact --id DominikReichl.KeePass`
  - se il comando `winget` non è disponibile, installarlo eseguendo in powershell **come amministratore** questo comando `Add-AppxPackage -Path 'https://github.com/microsoft/winget-cli/releases/download/v1.28.220/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'`
    - fare installazione solo per l'utente
    - **BISOGNA FARE UN RIAVVIO** per avere il comando a disposizione nel prompt dei comandi
- inserire la chiavetta USB e rinominarla in `J:` (usare il comando `diskmgmt.msc`)
- aprire il file delle password presente nella chiavetta USB
- [accedere a github](https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fdlordi) con una **finestra anonima/inprivate** di edge
  - bisogna accedere anche a gmail per inserire il codice di convalida di github
- continuare l'installazione tramite la [guida](https://github.com/dlordi/how-to/blob/main/win-setup/README.md) presente nel repo [`how-to`](https://github.com/dlordi/how-to)
- applicare le configurazioni del repo [`config`](https://github.com/dlordi/config)
