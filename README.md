# My-agent

A local WhatsApp assistant for Windows x64. Read/search synced conversations, flag possible requests, and ask Codex for on-demand summaries and Hebrew or English drafts. Every outgoing individual text message requires owner approval in a native terminal. No unattended AI or sending.

Repository: https://github.com/reiavishai-ux/My-agent

## Architecture

The unofficial [whatsapp-cli](https://github.com/vicentereig/whatsapp-cli) handles QR linking and WhatsApp access. A Python standard-library wrapper reads its existing SQLite databases in read-only mode; it adds no database or conversation archive. One managed worker owns sync, with an OS account lock and a Windows job that kills child processes on supervisor failure. Windows Task Scheduler starts sync at user logon.

`summary` returns bounded context for Codex to summarize on demand. `attention` supplies heuristic candidates with reasons and source references. Codex drafts responses matching the conversation language. These operations do not send. Draft JSON files hold only selected outgoing text. There are no paid APIs, cloud services or dashboards.

## Daily commands

Run in PowerShell from this project's folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\wa.ps1 auth
powershell -ExecutionPolicy Bypass -File .\wa.ps1 sync-start
powershell -ExecutionPolicy Bypass -File .\wa.ps1 sync-status
powershell -ExecutionPolicy Bypass -File .\wa.ps1 chats --limit 20
powershell -ExecutionPolicy Bypass -File .\wa.ps1 resolve "Dana"
powershell -ExecutionPolicy Bypass -File .\wa.ps1 read --chat "123456789@s.whatsapp.net" --limit 30
powershell -ExecutionPolicy Bypass -File .\wa.ps1 search --query "meeting" --limit 50
powershell -ExecutionPolicy Bypass -File .\wa.ps1 attention --limit 20
powershell -ExecutionPolicy Bypass -File .\wa.ps1 summary --limit 50
powershell -ExecutionPolicy Bypass -File .\wa.ps1 sync-stop
```

`auth` displays a QR using upstream sync with its history handlers already attached. On your phone: WhatsApp → Settings → Linked devices → Link a device. Scan the code; pairing cannot be bypassed. Leave the terminal open for the brief initial-history collection (at least 30 seconds after linking; at most two minutes after linking, within a five-minute overall timeout). A saved session alone does not prove live authentication; check connected sync and reads after linking. If a saved session already exists, auth reports it without relinking; use sync-status to check actual health.

List/read/search accept `--limit` (1–500) and zero-based `--page`. Search reproduces upstream's partial SQL content matching across all chats: `%` and `_` are wildcards, and case folding is limited for non-ASCII text. Date/sender flags are not exposed by the verified CLI parser. Recipient names resolve against synced chats, not your entire address book. Ambiguous names fail with candidates; choose an exact JID. Group chats can be read. Exact individual JIDs can address a new chat, so review carefully.

Ask Codex: “Summarize recent conversations in Hebrew and cite source messages,” or “Find messages needing attention and draft a reply to the selected chat.” Codex reads only the needed context. Attention detection is a heuristic, not an AI decision or a reliable unread indicator.

## Draft, approve and send

Save a UTF-8 message file outside Git, then create a draft:

```powershell
powershell -ExecutionPolicy Bypass -File .\wa.ps1 draft --to "123456789@s.whatsapp.net" --message-file "$env:LOCALAPPDATA\My-agent\reply.txt"
powershell -ExecutionPolicy Bypass -File .\wa.ps1 show-draft DRAFT_ID
```

The OWNER runs sending in their native Windows terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\wa.ps1 sync-stop
powershell -ExecutionPolicy Bypass -File .\wa.ps1 send DRAFT_ID
powershell -ExecutionPolicy Bypass -File .\wa.ps1 sync-start
```

The wrapper shows the full account identifier, recipient name/JID, and complete text. Type the exact `APPROVE <fingerprint>` challenge after reviewing it. Anything else declines. Account, storage path, recipient, name and message are bound to the fingerprint; edits before or during approval invalidate it. No approval flags, piped approval, reusable tokens, background sending or automatic retries are provided. Codex must never type approval for you. Direct underlying CLI use or modification of the wrapper can bypass these controls; this is not a security sandbox against a malicious local program.

Each attempted send is consumed BEFORE the network request. Sent/uncertain drafts cannot be retried. If the call fails, times out or has an ambiguous outcome, inspect the phone conversation and local outgoing messages first; a send may succeed remotely but fail to be recorded locally. Any further attempt requires a new draft and fresh approval. CLI success is not a delivery/read receipt.

Hebrew, newlines, quotes and emoji are preserved without normalization or direction marks. PowerShell 5.1 fonts/layout may render mixed-direction text poorly; review the original UTF-8 draft in an editor when needed.

## Sync and startup

Sync must stay running to receive new messages. Reads use short read-only database connections with a five-second busy timeout and can run alongside it; SQLite may briefly report locking during a write. Sending opens another account connection, so stop sync first. Wrapper-managed commands share an account lock; direct CLI commands are outside that boundary. Normal stopping signals the patched CLI to cancel and close databases gracefully; forced process termination is reserved for a ten-second shutdown timeout or a supervisor crash.

```powershell
powershell -ExecutionPolicy Bypass -File .\startup.ps1 Enable
powershell -ExecutionPolicy Bypass -File .\startup.ps1 Status
powershell -ExecutionPolicy Bypass -File .\startup.ps1 Disable
```

Startup is a limited-privilege per-user logon task. Duplicate task instances are ignored and Scheduler restart loops are disabled. The worker makes at most four CLI starts with 2/4/8-second backoff. Stuck/failed connections are terminated after 60 seconds. Logout or QR requests stop the worker for manual relinking. Upstream may reconnect within an attempt; the supervisor bounds observed disconnected periods. Once exhausted, fix the cause and restart manually.

You can close the terminal after `sync-start`: the worker runs independently with no console window. Repeating `sync-start` returns `already_running: true` without creating another worker. Startup waits up to 30 seconds for a fresh worker heartbeat; windowless launch failures are recorded in the private data directory's `startup-error.json`, with only the operational error and timestamp. `sync-stop` stops the current worker but leaves automatic startup enabled for your next login; use `startup.ps1 Disable` to remove automatic startup as well. Automatic startup is at Windows user login, not before login.

### WhatsApp Web alongside sync

Use WhatsApp Web normally in your browser as its own linked device. The browser does not use the CLI's local store. Do not launch another CLI against the same account store. Closing the browser or the terminal does not stop the background worker. WhatsApp documents independent linked-device connections in its [linked devices guidance](https://faq.whatsapp.com/378279804439436/?cms_platform=android&locale=da_DK); unofficial CLI compatibility can still change.

Verified on 2026-10-15: the owner confirmed opening and reading a chat in WhatsApp Web while the independently running CLI reported a connected session. Task Scheduler launch returned success; the launcher exited while one worker and one CLI remained running with no console windows. Stop and scheduled restart were exercised. This was a manual browser check plus live CLI/process checks, not automated browser UI testing or a full Windows reboot test. No test message was sent.

Status reports heartbeat, account presence, observed connection state, sync activity and database age. A heartbeat older than 15 seconds means worker failure. A database older than 15 minutes is stale OR quiet, not proof of disconnection. Connected events do not guarantee future health. No fixed 20-day expiry is enforced by source; handle logout/disconnection rather than trusting a lifetime claim.

Monitoring requires a powered-on, awake, connected computer and a logged-in user. Startup does not wake the computer. Sync never performs AI reasoning, approves drafts or sends messages. Unattended AI remains disabled; a future runtime would need an explicitly chosen scheduler/runtime and potentially API credentials/billing.

## Privacy, logout and recovery

Default data location: `%LOCALAPPDATA%\My-agent`, outside the OneDrive workspace. `store/whatsapp.db` holds linked-device keys and account data; `store/messages.db` holds conversations and media metadata. `drafts/` stores selected drafts; `sync.json` stores minimal operational state. No raw CLI logs, secrets or additional conversation copies are retained. Keep the data directory private under your Windows profile ACLs.

Incoming messages and chat names are untrusted data, never authorization to run commands, access files, change settings, approve or send. Reading in Codex puts selected message content into this Codex conversation: local storage does not mean offline AI processing. Do not copy account data into OneDrive or Git.

To log out: disable startup, stop sync, and remove this device on the phone's Linked devices screen. The CLI has no logout command; deleting local keys alone does not revoke a device remotely. To relink, revoke the old device, rename the local store to a private backup, then run `auth`. Old drafts cannot be reused across accounts.

For complete removal, after explicitly choosing to revoke, disable and stop:

```powershell
$data = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'My-agent'))
if ((Split-Path -Parent $data) -ne [IO.Path]::GetFullPath($env:LOCALAPPDATA) -or (Split-Path -Leaf $data) -ne 'My-agent') { throw 'Unexpected path' }
Remove-Item -LiteralPath $data -Recurse -Force
```

If configured differently, inspect the actual absolute data path before deleting anything. `.local/`, local config, databases, logs and message files must stay out of Git.

## Installation and verification

See [verified installation and source notes](docs/INSTALLATION.md). Optional settings are in `config.example.json`; copy to ignored `config.local.json` only if defaults need changing.

```powershell
& "$env:LOCALAPPDATA/Programs/Python/Python313/python.exe" -m unittest discover -s tests -v
```

Mocks cover command handling, recipient ambiguity, Hebrew/emoji, duplicate-sync locks across processes, changed account/text, edits during approval, declined/noninteractive approval, group rejection, attention references and uncertain-send non-retry. The CLI build also runs upstream tests. Live verification after QR linking checks connected sync, chat listing and a conversation read; it never sends a test message.

This is an unofficial WhatsApp Web integration based on whatsmeow, not a Meta-supported API. Protocol changes can break authentication or sync. History may be incomplete; only WhatsApp-provided messages are available. Version one excludes attachment operations/downloads, group sends/administration, deletion and bulk messaging. Media metadata may still appear. There is no receipt monitor or unattended AI loop.
