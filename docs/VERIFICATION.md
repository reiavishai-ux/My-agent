# Verification record

Setup began 2026-10-14; live checks completed 2026-10-15 (Asia/Jerusalem).

## Completed

- Inspected Windows x64 / PowerShell 5.1 and available dependencies.
- Configured origin as `https://github.com/reiavishai-ux/My-agent.git`; remote access succeeded and no branches existed at that check.
- Reviewed the integration's README, release documentation/workflow, tagged source and storage/authentication/sync behavior.
- Downloaded official v1.3.3 Windows archive and verified published SHA-256 before running its version command.
- Installed Python 3.13.15, Go 1.27.0, and WinLibs GCC 16.2.0 for the local wrapper/text-only source build.
- Built pinned v1.3.3 with both media-download enqueue sites removed and explicit logout signaling. Built binary smoke test reports `v1.3.3-my-agent-text-only`.
- All upstream Go test packages passed: root CLI, client, commands, output and store. Types package has no tests.
- All 20 wrapper tests passed. These include command handling, ambiguous recipients, Hebrew/emoji, account/recipient/text changes, edits during approval, declined/noninteractive approval, cross-process sync locking, uncertain-send consumption, group-send rejection, incoming instructions remaining data, attention source references, bounded restarts, logout handling, sanitized state, Windows job cleanup on supervisor crash, history handlers attached before QR linking, and progress counters remaining distinct from authentication errors.
- Registered and verified Windows Task Scheduler task `My-agent WhatsApp Sync` (Ready), running windowless Python as the current user at logon with limited privileges.
- Opened a native terminal for owner QR linking. No real send command was invoked.

## Live verification completed

- Owner confirmed scanning the corrected linking QR; saved account and live Connected event verified.
- Managed worker stayed running with a fresh heartbeat and observed sync activity; local message database updated.
- Nonempty chat listing verified, including Hebrew chat names.
- Read 500 recent message records locally; 438 contained nonempty text at that sample. No message bodies were printed or copied into this verification document.
- Read three messages from a selected conversation and verified text search returned its source message.
- Graceful stop succeeded, read-only database access succeeded after stopping, and managed sync restarted successfully.
- Account data ACL verified protected from inherited access; only current Windows user and SYSTEM are granted access.
- No setup blockers remain. Future availability depends on the unofficial protocol, connectivity and account linking; incomplete history and quiet-account freshness remain limitations.

## Live issue and recovery

The initial release-based linking attempt failed with WhatsApp `Client outdated (405)`, advertised client `2.3000.1035920091`. The account remained unlinked; no real message was sent. Reviewed current upstream's dependency/client/store differences and changed the build pin to `fee3f8a8184871ff6626d3ecc58cd0574853038c`, which uses a newer July 2026 whatsmeow version. The same text-only modifications remain applied. Live linking must be repeated before claiming completion.

The newer source's functional packages passed; its Unix 0700 permission assertion failed on Windows. Made that one assertion platform-aware (skipped on Windows), reran all packages successfully, and separately verified the actual private Windows account-directory ACL for the current user and SYSTEM. Removed inherited sandbox-group access. Built binary reports `fee3f8a-my-agent-text-only`. Reopened linking with the new executable.

The newer client saved a linked account and the managed worker reported a real Connected event. Chat listing remained empty; no conversation read could be verified. A later check found the account logged out and the worker stopped with authentication_required. No fixed authentication lifetime can be inferred from this.

Changed the wrapper's interactive auth flow to pair through upstream sync, which installs history handlers before connecting/pairing, rather than standalone auth, which can miss initial history. The manual linking process stays alive briefly to collect available history and cannot send user messages. Corrected monitoring so a numeric message counter such as 401 is not treated as an authentication code. Added graceful stop-file cancellation to the CLI's sync context for Windows shutdown. Reran all Go packages successfully (one Unix-only mode assertion skipped on Windows with separate real ACL verification) and all 20 wrapper tests passed. The corrected flow and live read/search/stop/restart checks succeeded as recorded above.

## Terminal independence and WhatsApp Web follow-up

- Owner confirmed WhatsApp Web could open and read chats; background sync remained connected alongside it.
- Exercised graceful stop followed by actual `Start-ScheduledTask`, using the installed user-logon task. First scheduled attempt returned failure; added minimal private startup diagnostics, extended worker startup readiness to 30 seconds, and required a fresh heartbeat rather than accepting prior state. Subsequent scheduled launches succeeded (`LastTaskResult = 0`). No precise cause is claimed for the first transient failure.
- Verified the scheduled Python launcher had exited while a windowless pythonw worker and exactly one CLI remained alive; both had MainWindowHandle = 0.
- Made repeated start idempotent for a healthy existing worker; live repeated-start returned already_running with the same worker PID.
- Added two startup regression tests. All 22 wrapper tests passed. No test messages sent. Full reboot/user-logoff testing was not performed; the logon trigger and actual Scheduler execution were verified.

## Boundaries

- No real test messages were sent.
- Account data, generated upstream source, binaries and build caches are excluded from Git; only project source, tests, configuration examples and documentation are published.
- Release archive checksum was checked; Sigstore cryptographic identity verification was not performed. The executable used by the wrapper is locally built from reviewed pinned source, not claimed to be the byte-identical official executable.
- AI reasoning remains on-demand in Codex. No unattended AI runtime or billing credentials were configured.
