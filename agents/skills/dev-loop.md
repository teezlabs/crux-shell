# Dev Loop

Read this before relaunching crux for any reason.

Crux is the live desktop. Every relaunch takes down the user's real bar, notifications and lock screen, so:

- One confirmed change at a time. Never batch several unconfirmed features into one boot test
- Each step is its own commit, so a bad one reverts cleanly
- Never `pkill qs` broadly. Kill only `qs -c crux` (other configs, like `qs -c overview`, also run)

## Restart

QuickShell's instance registry is flaky when kill and relaunch are chained in one command. The old instance id gets reused and the log stays stale. Run each step as a **separate tool call**:

```bash
# 1. Kill
for p in $(pgrep -f "qs -c crux"); do kill -9 "$p"; done

# 2. Verify dead (expect no output)
ps aux | grep "qs -c crux" | grep -v grep

# 3. Launch
rm -f /tmp/crux-boot.log
nohup qs -c crux >/tmp/crux-boot.log 2>&1 &
disown

# 4. After a couple of seconds, check the log and process
cat /tmp/crux-boot.log
ps aux | grep "qs -c crux" | grep -v grep
```

## Reading the boot log

- A clean boot ends at `Configuration Loaded` with **no** `WARN` lines. Treat any warning as a bug to fix before calling the change done
- Some warnings only appear after load (IPC target collisions on a monitor focus change), so re-check the log after exercising the change
- `An instance of this configuration is already running` means the kill didn't land. Look for a leftover `instance.lock`/`ipc.sock` in `/run/user/1000/quickshell/by-shell/<hash>/`
- For debug output, `console.log` with a `crux-debug` prefix and `grep crux-debug /tmp/crux-boot.log`. The `.qslog` file is binary

## When a relaunch fails

Fix it or revert it right away. The user has no shell until crux boots again. `git stash` or `git revert` the last step, relaunch, and only then investigate.
