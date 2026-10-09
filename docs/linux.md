# Linux

Claude Code's sandbox on Linux uses these components:

| Component | Purpose | Source |
| --- | --- | --- |
| `bubblewrap` | Limits the files each command can see and change | Install below |
| `socat` | Passes network traffic to Claude Code's proxy, which enforces the host list | Install below |
| seccomp filter | Blocks Unix sockets, such as Docker's | Included in Claude Code |
| ripgrep | File search | Included in Claude Code |

## Install

```bash
# Debian, Ubuntu
sudo apt-get install bubblewrap socat
# Red Hat, Fedora, Rocky, Alma
sudo dnf install bubblewrap socat
```

bubblewrap 0.4.0 or later is supported.

Install Claude Code:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Ubuntu 24.04 and later

AppArmor stops bubblewrap from creating user namespaces. Check:

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns
```

If it prints `1`, allow bubblewrap:

```bash
sudo tee /etc/apparmor.d/bwrap > /dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,
  include if exists <local/bwrap>
}
EOF
sudo systemctl reload apparmor
```

If it prints `0` or `No such file or directory`, skip this step.

## Check

Start `claude` and run `/sandbox`. A Dependencies tab lists missing components. Install them and restart Claude Code.

If the seccomp filter is listed, install it with npm:

```bash
# Debian, Ubuntu
sudo apt-get install nodejs npm
# Red Hat, Fedora, Rocky, Alma
sudo dnf install nodejs npm
# Both
sudo npm install -g @anthropic-ai/sandbox-runtime
```

Without the seccomp filter, sandboxed commands can use any Unix socket. Docker's socket, for example, gives control of the host.

Then install the settings: [README](../README.md#install), step 2.

## When something fails

| Problem | Fix |
| --- | --- |
| git ignores your configuration | A git config file that is a symlink, as dotfile managers create, can stay unreadable in the sandbox. Replace the symlink with the file. |
