# setup-bootstrap

- collegarsi all'hotspot del telefono
  - la password va digitata a mano...
- installare keepass con il comando `winget install --source winget --interactive --exact --id DominikReichl.KeePass`
  - se il comando `winget` non è disponibile, installarlo eseguendo in powershell **come amministratore** questo comando `Add-AppxPackage -Path 'https://github.com/microsoft/winget-cli/releases/download/v1.28.220/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'`
    - fare installazione solo per l'utente
    - **BISOGNA FARE UN RIAVVIO** per avere il comando a disposizione nel prompt dei comandi
- inserire la chiavetta USB e rinominarla in `J:`
  - per rinominarla, cercare "Crea e formatta le partizioni del disco rigido" oppure "Gestione dischi" nel menu start
- aprire il file delle password presente nella chiavetta USB
- [accedere a github](https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fdlordi) con una **finestra anonima/inprivate** di edge
  - bisogna accedere anche a gmail per inserire il codice di convalida di github
- continuare l'installazione tramite la [guida](https://github.com/dlordi/how-to/blob/main/win-setup/README.md) presente nel repo [`how-to`](https://github.com/dlordi/how-to)
