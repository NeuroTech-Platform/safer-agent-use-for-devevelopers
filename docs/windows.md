# Windows

Claude Code's sandbox doesn't run on native Windows. With these settings, Claude Code won't start there. Use WSL2, the Linux environment built into Windows.

## Install WSL2

In PowerShell, run as administrator:

```powershell
wsl --install
```

Restart Windows. Then check the version:

```powershell
wsl -l -v
```

The `VERSION` column must show `2`. WSL1 has no sandbox.

## Set up inside WSL

Open the WSL terminal (Ubuntu by default) and do everything there:

1. Follow [linux.md](linux.md): components, Claude Code, check.
2. Install the settings ([README](../README.md#install), step 2). They go in your WSL home folder, not in `C:\Users\...`.

Start `claude` from the WSL terminal, not from PowerShell or CMD.

The seccomp filter matters most here: without it, sandboxed commands can start Windows programs, such as `cmd.exe`, outside the sandbox.

## When something fails

| Problem | Fix |
| --- | --- |
| Every command fails with a `bwrap` error about `/mnt/c` | `~/.ssh` or `~/.aws` is probably a symlink to your Windows folder. Replace the symlink with a copy. |
