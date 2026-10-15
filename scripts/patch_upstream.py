"""Auditable text-only changes to the pinned official source, not an install script."""
from pathlib import Path
import sys

source = Path(sys.argv[1]) / 'internal/commands/commands.go'
text = source.read_text(encoding='utf-8')
lines = text.splitlines(keepends=True)
count = 0
for i, line in enumerate(lines):
    if 'worker.Enqueue(mediaJob{' in line:
        lines[i] = line[:len(line) - len(line.lstrip())] + '// My-agent: attachment downloads disabled in text-only build.\n'
        count += 1
if count != 2:
    raise SystemExit('Unexpected upstream source: expected exactly two media enqueue sites.')
text = ''.join(lines)
marker = '\t\tcase *events.Disconnected:\n'
if text.count(marker) != 1:
    raise SystemExit('Unexpected upstream connection event handling.')
text = text.replace(marker, '\t\tcase *events.LoggedOut:\n\t\t\tfmt.Fprintln(os.Stderr, "MY_AGENT_AUTHENTICATION_REQUIRED")\n\n' + marker)
source.write_text(text, encoding='utf-8')
print('Disabled both live and history media download paths; added logout signal.')

test = Path(sys.argv[1]) / 'internal/store/store_test.go'
test_text = test.read_text(encoding='utf-8')
marker = 'func TestNewMessageStoreCreatesPrivateDirectory(t *testing.T) {\n'
if test_text.count(marker) != 1:
    raise SystemExit('Unexpected upstream directory permission test.')
test_text = test_text.replace('"path/filepath"', '"path/filepath"\n\t"runtime"', 1)
test_text = test_text.replace(marker, marker + '\tif runtime.GOOS == "windows" {\n\t\tt.Skip("Unix mode bits do not represent Windows ACLs; verify the account directory ACL separately")\n\t}\n')
test.write_text(test_text, encoding='utf-8')
print('Made the Unix permission-mode assertion platform-aware; Windows ACL verification is separate.')

main = Path(sys.argv[1]) / 'main.go'
main_text = main.read_text(encoding='utf-8')
marker = '\tdefer cancel()\n'
if main_text.count(marker) != 1:
    raise SystemExit('Unexpected upstream cancellation setup.')
main_text = main_text.replace(marker, marker + '''
	// My-agent: graceful Windows shutdown without terminating a SQLite write.
	if command == "sync" {
		if stopFile := os.Getenv("MY_AGENT_STOP_FILE"); stopFile != "" {
			go func() {
				ticker := time.NewTicker(250 * time.Millisecond)
				defer ticker.Stop()
				for {
					select {
					case <-ctx.Done():
						return
					case <-ticker.C:
						if _, err := os.Stat(stopFile); err == nil {
							cancel()
							return
						}
					}
				}
			}()
		}
	}
''')
main.write_text(main_text, encoding='utf-8')
print('Added a local graceful-shutdown signal for Windows sync.')
