# Verified installation

Environment inspected: Windows x64, version 10.0.28000, PowerShell 5.1. Python initially resolved only to an unusable Windows Store alias; Go and a C compiler were not installed. WSL is not installed. Git was installed during repository setup.

Reviewed upstream README, `docs/RELEASE.md`, release workflow and tagged `main.go`, `internal/client/client.go`, `internal/commands/commands.go`, `internal/store/store.go`. Provider: https://github.com/vicentereig/whatsapp-cli. It uses whatsmeow's unofficial WhatsApp Web protocol and SQLite.

Release reviewed first: [v1.3.3](https://github.com/vicentereig/whatsapp-cli/releases/tag/v1.3.3), source commit `98d322842aa8980e5adf728d92e04d2680715691`. Official Windows ZIP SHA-256: `f5b6fc9f4d76ed4f1084d1ce4b5f0a981112c9533ade55ce2fc9e2c116115d69`. The archive was checked against the published checksum file before execution; binary reports v1.3.3. Sigstore certificates/signatures are published, but cryptographic signature identity verification was not performed. Checksum matching verifies integrity, not an independent publisher signature.

Live linking rejected the release client with `Client outdated (405)`, version `2.3000.1035920091`. The source build now pins official upstream commit [`fee3f8a8184871ff6626d3ecc58cd0574853038c`](https://github.com/vicentereig/whatsapp-cli/tree/fee3f8a8184871ff6626d3ecc58cd0574853038c). Its reviewed July dependency upgrade uses whatsmeow `a2381054887e` and client version `2.3000.1043423438`; it also adds store presence/permission checks and LID resolution. This is a documented source build, not an official release binary. No provider was substituted.

Material differences from README claims: release sync automatically downloads media, saved authentication is not a live server check, and source enforces no 20-day session lifetime. The current README's Go 1.24 claim differs from the pinned go.mod's Go 1.25 requirement. The CLI exposes auth, sync, messages list/search, contacts search, chats list, send, media download and version. The wrapper exposes only the approved text operations. There is no logout command or media-download-disable flag.

To exclude attachments, `scripts/patch_upstream.py` removes exactly two media enqueue sites (live/history) and adds a logout event signal. It adds a local stop-file signal so Windows sync can cancel its context, close databases and disconnect gracefully; abrupt termination is only a timeout/crash fallback. It also skips the upstream Unix 0700 mode-bit assertion on Windows, where permissions are ACLs; the rest of the test suite remains enabled. `scripts/protect-data.ps1` separately sets and verifies the real data-directory ACL for the current user and SYSTEM only. The patch fails if expected source structure differs. The local build follows the documented source-build method and uses the pinned official upstream source. The built CLI reports `fee3f8a-my-agent-text-only`. Media metadata may still be stored, but attachment content is not downloaded. The verified original binary stays under ignored `.local/bin/` and is not the wrapper default.

Installed prerequisites are Python 3.13 (user scope), Go and WinLibs GCC. Python uses only its standard library. Go/GCC are necessary for upstream's CGO SQLite source build; they are not needed to run the resulting binary. No upstream installation script is executed.

Reproduction on Windows x64:

```powershell
winget install --id Git.Git --exact --source winget
winget install --id Python.Python.3.13 --exact --source winget --scope user
winget install --id GoLang.Go --exact --source winget
winget install --id BrechtSanders.WinLibs.POSIX.UCRT --exact --source winget --scope user
& 'C:/Program Files/Git/cmd/git.exe' clone https://github.com/vicentereig/whatsapp-cli.git .local/upstream
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\protect-data.ps1
```

The build script verifies the exact pinned commit, extracts a fresh source directory, applies reviewed changes, runs upstream tests and builds. It refuses to overwrite existing build sources; inspect them rather than silently discarding changes. Generated sources/binaries/module cache stay in ignored `.local/`. Defaults point to the text-only build and `%LOCALAPPDATA%\My-agent`.

Upstream stores account/session keys in `whatsapp.db`, messages/chats in `messages.db`, and (in an unmodified release) media under `store/media`. Wrapper reads use SQLite mode=ro and the verified tagged schema, avoiding initialization/schema writes from the CLI's read commands during sync. SQLite rollback-journal locking can briefly block reads. Never mix live account connections: stop sync before auth or send.
