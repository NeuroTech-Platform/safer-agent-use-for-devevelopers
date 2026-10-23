# macOS

Claude Code's sandbox uses Seatbelt, which is built into macOS. There is nothing to install for it.

On top of it, Claude Code runs inside [SandVault](https://github.com/webcoyote/sandvault), as a separate macOS account.

## What SandVault adds

Claude Code's sandbox covers shell commands only. SandVault runs all of Claude Code as a separate account, so what the sandbox doesn't cover is still kept out of your home folder:

- Claude's file edits, hooks, MCP servers and plugins can't reach your home folder: your other projects, SSH keys, cloud credentials and browser data.
- Commands that run outside Claude Code's sandbox, such as approved retries, `docker` and `gh`, run as that account, not as you.
- The account has its own keychain. It can't read yours.
- The account has no admin rights.

Limits:

- SandVault doesn't limit the network. Claude Code's sandbox does that, for shell commands.
- Remote Control and claude.ai connectors don't work in SandVault. Claude logs in there with a token that can only make model requests ([step 3](#3-log-in)).

## 1. Install SandVault

> [!IMPORTANT]
> **Daily account without admin rights?** Skip to [Daily account without admin rights](#daily-account-without-admin-rights).

```bash
brew install sandvault
sv build
```

`sv build` creates the account `sandvault-$USER` and the shared folder `/Users/Shared/sv-$USER`. It asks for your password.

SandVault's account runs Claude Code from Homebrew, which doesn't update it automatically. Keep it current:

```bash
brew upgrade claude-code
```

Continue with [2. Install the settings](#2-install-the-settings).

### Daily account without admin rights

SandVault's build needs admin rights, and its files belong to the admin account that installed it. So the admin account builds SandVault for the daily account. The build adds sudo rules that let the daily account run only what `sv` needs, so daily use needs no admin rights.

**a. Admin account, once.** Install SandVault and Claude Code. Create SandVault's group for the daily account and join it, so the build can write into the daily account's shared folder. Replace `jdoe` with the daily account's short name:

```bash
DEV=jdoe
brew install sandvault claude-code
sudo dseditgroup -o create "sandvault-$DEV"
sudo dseditgroup -o edit -a "$USER" -t user "sandvault-$DEV"
```

**b. Admin account, in a new Terminal window. Repeat after each `brew upgrade sandvault`.** Build SandVault for the daily account, then give that account SandVault's SSH key and install marker:

```bash
DEV=jdoe
SVHOME="$HOME/sandvault-for-$DEV"
mkdir -p "$SVHOME"
env USER="$DEV" HOME="$SVHOME" GIT_CONFIG_GLOBAL="/Users/$DEV/.gitconfig" sv --rebuild build

KEYS="$(brew --prefix sandvault)/libexec/guest/home/.ssh"
chmod 755 "$KEYS" && chmod 644 "$KEYS/authorized_keys"
sudo install -d -o "$DEV" -g staff -m 700 "/Users/$DEV/.ssh"
sudo install -o "$DEV" -g staff -m 600 "$SVHOME/.ssh/id_ed25519_sandvault" "/Users/$DEV/.ssh/"
sudo install -o "$DEV" -g staff -m 644 "$SVHOME/.ssh/id_ed25519_sandvault.pub" "/Users/$DEV/.ssh/"
sudo -u "$DEV" mkdir -p "/Users/$DEV/.config/codeofhonor/sandvault"
sudo -u "$DEV" touch "/Users/$DEV/.config/codeofhonor/sandvault/install"
```

- `USER` makes the build target the daily account.
- `HOME` keeps the build's key and state in their own folder.
- `GIT_CONFIG_GLOBAL` passes the daily account's git name and email to SandVault's account.
- `sv` compares SandVault's key file on every start, so the daily account must be able to read it.

**c. Daily account, once.** On Apple silicon, add Homebrew to your PATH:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

The admin account runs the updates. SandVault's account runs the admin's Homebrew copy of Claude Code, so `brew upgrade claude-code` reaches it at its next start. After `brew upgrade sandvault`, repeat step b.

These steps are written for SandVault 1.32.0.

## 2. Install the settings

SandVault's account has its own home folder, so your `~/.claude` folder doesn't reach it. At each start, SandVault copies `/Users/Shared/sv-$USER/user/` into that home folder. In your daily account, from this repository's folder:

```bash
mkdir -p "/Users/Shared/sv-$USER/user/.claude/rules" ~/.claude/rules
grep -v '^[[:space:]]*//' settings.jsonc > "/Users/Shared/sv-$USER/user/.claude/settings.json"
cp rules/*.md "/Users/Shared/sv-$USER/user/.claude/rules/"
cp rules/commands.md ~/.claude/rules/
```

SandVault gets the settings and all three rules files, `sandvault.md` among them, which covers git in the synced copy. Your own account gets `commands.md`, whose rules hold without the sandbox. Repeat this after every change to `settings.jsonc` or a file in `rules/`.

> [!NOTE]
> Claude Code in VS Code, in the Claude Desktop app, or started with `claude` in a terminal, runs as you, outside SandVault, with no sandbox unless you install the settings in your own account too: [README](../README.md#install), step 2. That step also installs `sandbox.md` there, which only makes sense under the sandbox, and not `sandvault.md`.

## 3. Log in

Claude Code can't save a login in SandVault's account: the keychain write fails with `Couldn't save your login`. Give the account a login token instead. In your daily account, run:

```bash
claude setup-token
```

It opens your browser, then prints a token that is valid for one year. Run these two lines, paste the token at the empty prompt, and press Enter:

```bash
read -rs TOKEN
echo "export CLAUDE_CODE_OAUTH_TOKEN='$TOKEN'" >> "/Users/Shared/sv-$USER/user/.zshenv"
```

SandVault's account loads that file at every start. The settings hide the token from Claude's shell commands. When the token expires, repeat this step.

The token uses your subscription but can only make model requests. In SandVault, claude.ai connectors and Remote Control don't work. MCP servers you configure yourself still do.

`claude setup-token` needs a claude.ai account. With a Console account, put `export ANTHROPIC_API_KEY='your-key'` in that file instead.

## 4. Install `sv-claude`

[`bin/sv-claude`](../bin/sv-claude) runs Claude in SandVault on a copy of your repository, and keeps your folder and the copy in sync while it runs. Install it in your daily account, from this repository's folder:

```bash
mkdir -p ~/.local/bin
install -m 755 bin/sv-claude ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
```

Open a new terminal. To update `sv-claude`, run the `install` line again. The settings stop Claude from changing `sv-claude`, so update it yourself. [`tests/sv-claude.sh`](../tests/sv-claude.sh) tests it against a fake SandVault, in about two minutes.

## 5. Start Claude

In VS Code's terminal, in your repository's top folder, or in a folder whose subfolders are repositories, such as your workspace folder:

```bash
sv-claude
```

It refuses your home folder. Options go to Claude, for example `sv-claude --continue` or `sv-claude --resume`. Each folder keeps the same copy path, so earlier conversations stay available.

- `sv-claude` starts SandVault with `-x`, which turns off SandVault's own sandbox. macOS can't run one sandbox inside another, so without `-x` Claude Code's sandbox can't start. The separate account still keeps your home folder out of reach.
- SandVault starts Claude with `--dangerously-skip-permissions`. The settings refuse that flag, so the session runs in auto mode.
- Sessions start on Opus 5.5 at high effort. A `/model` or `/effort` change lasts one session, because SandVault restores the settings at every start. To change the default, edit `settings.jsonc` and repeat [step 2](#2-install-the-settings).
- Don't start Claude with `sv` from your own folder. SandVault's account can't read it, so the session silently starts in `/Users/Shared/sv-$USER`, which holds the settings SandVault copies in. Claude could change them there.
- Don't open the copy in VS Code, or run git in it from your own account. SandVault's account can change its `.git/config` so that git runs commands as you.

### Sync

While a session runs, `sv-claude` syncs your folder and its copy in `/Users/Shared/sv-$USER/work/`, both ways, every 3 seconds. Your account never reads or writes the copy. Everything in the copy runs as SandVault's account, through `sudo`.

- Synced: files git sees, tracked or untracked. Not synced: files `.gitignore` excludes, such as `node_modules` and build output. Install dependencies in SandVault with `sv-claude shell npm install`.
- In a folder of repositories, the repositories and the files beside them are synced, including a repository or worktree you add during the session. A repository Claude creates there stays in the copy.
- Never synced: `.env` and `.env.*`, except `.env.example`.
- From your folder to the copy only: files that tools run code from on their own, such as `.vscode`, `.envrc`, `.claude` and package-manager settings. [`bin/sv-claude`](../bin/sv-claude) lists them.
- In the copy only: links that point out of the repository, and submodules.
- Same lines changed on both sides between two syncs: your version is kept on both sides. You get a notification. `~/Library/Caches/sv-claude/<folder>/sync.log` gives the command that shows Claude's version.
- More than 20 deletions, or 300 changed files, from Claude within 60 seconds: not applied to your folder. You get a notification. `sv-claude sync` shows the changes and asks.
- Your folder and the copy are one working tree, on one branch: yours. A switch, commit or pull in your folder is one in the copy within seconds, and Claude's uncommitted edits stay, as they would in your folder. For your own work on another branch during a session, use a second clone outside the synced folder. For Claude's work on another branch at the same time, add a worktree beside the repository, `git -C chorus-tre worktree add ../chorus-tre-fix fix/x`: it is synced like a repository from the next cycle, on its own branch. `git worktree remove` ends its sync; its copy stays. `rules/sandvault.md` tells Claude to ask you for one. In a session started in a single repository, put the worktree inside it, `git worktree add .worktrees/fix-x fix/x`, and add `.worktrees/` to `.git/info/exclude`; a worktree outside the folder isn't synced.
- A checkout, reset, rebase, merge or pull by Claude in the copy, during a session or between two: the changed files are not applied to your folder. You get a notification naming the copy's branch. `sv-claude sync` shows the changes, and the `git switch` line that puts your folder on the same branch first. After that switch, the hold ends by itself.
- Claude's changes are in your folder within seconds. Dev servers, test watchers and VS Code extensions can run them at once. Review them in Source Control before you commit.
- The copy's repository gets your branches, tags, remote-tracking branches and `origin` URL, without credentials. A `git fetch` in your folder shows in the copy within seconds. Your git config and hooks are not copied. A commit by Claude in the copy doesn't reach your folder; its files do, as edits. When your branch moves, the copy's branch follows yours and Claude's commit is set aside, its files kept.
- The sync runs `sudo -n -H -u sandvault-$USER /usr/bin/env …`. SandVault's `/etc/sudoers.d/50-nopasswd-for-sandvault-$USER` allows your account to run `/usr/bin/env`, with any arguments, as `sandvault-$USER`, without a password. It allows nothing as root or as another account. `-n` fails instead of asking for a password. `-H` sets the home folder to `sandvault-$USER`'s. These commands get `/dev/null` as stdin and stderr, so they can't reach your terminal or your files. Each call is in the system log.

To hold all of Claude's changes, start with `SV_CLAUDE_REVIEW=1 sv-claude`. Your edits still reach the copy. To apply Claude's changes, run in a second terminal, in the same folder:

```bash
sv-claude sync
```

It lists the files that would change and asks. `d` opens the full diff in VS Code.

### Use other software in SandVault

To run other software as SandVault's account on the same copy, for example to install dependencies or run the project yourself, open a SandVault shell instead of Claude:

```bash
sv-claude shell
```

To run one command instead, such as `sv-claude shell npm install`, put it after `shell`.

The sync also runs during `sv-claude shell`. Commands you type there run as SandVault's account, so they can't reach your home folder. Claude Code's sandbox and its network limits don't apply to them.

### Tools in SandVault

Programs from Homebrew work: SandVault's account can read `/opt/homebrew`. What lives in your home folder doesn't carry over, because that account has its own:

- **Configs and logins**, such as `~/.kube/config`, `~/.npmrc` or a `gh` token: put a copy in `/Users/Shared/sv-$USER/user/`, at the same path under it. SandVault copies that folder into its account's home at each start. Give them the least rights that work: Claude can read them there.
- **Daemons**, such as Docker's: that account needs its own. See below.
- **`open`, `osascript` and browsers**: don't work. The account has no GUI session.
- **`brew install`**: the admin account does it.
- **Ports**: a server started in the copy is reachable from your browser at `localhost`, if `sandbox.network.allowLocalBinding` is `true` in `settings.jsonc`.

#### Docker in this setup

Your own Docker VM, Colima or Docker Desktop, mounts your home folder. Sharing it with SandVault's account would give Claude your files. Instead, give that account its own Colima VM, once, from any project folder. The first line creates it with only the shared folder mounted, so containers can't read that account's home folder and its login token. The second line gives it `docker compose`:

```bash
sv-claude shell colima start --mount "/Users/Shared/sv-$USER:w"
sv-claude shell sh -c 'mkdir -p ~/.docker/cli-plugins && ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose'
```

For `kind` clusters, add `--cpu 4 --memory 6` to the first line: Colima's default of 2 GB is too small. The VM keeps running after sessions; `sv-claude shell colima stop` stops it, and after a restart of the Mac, `sv-claude shell colima start` brings it back. To log in to a registry, run `sv-claude shell docker login …` with a pull-only token: the credential is stored, readable, in that account's `~/.docker/config.json`. `docker buildx` isn't installed with Homebrew's `docker`: the admin runs `brew install docker-buildx`, then you link `docker-buildx` like `docker-compose` above. The settings run every `docker` command outside Claude's sandbox, and ask you before `run`, `exec`, `build`, `buildx build` and `compose`. `kind`, `kubectl`, `helm`, `ct` and `cilium` run outside it too, and ask before they run code in a cluster or change one.

## 6. Verify

In a session started with `sv-claude`, run the checks in the [README](../README.md#verify).

## What `-x` costs

SandVault's sandbox also blocks external drives (`/Volumes`) and world-writable files. Without it, Claude's file edits, hooks and MCP servers can reach them. Shell commands are still blocked by Claude Code's sandbox.

## When something fails

| Problem | Fix |
| --- | --- |
| `sv-claude: command not found` | Open a new terminal after [step 4](#4-install-sv-claude). |
| `Couldn't save your login` | SandVault's account can't save a login. Give it a token: [step 3](#3-log-in). |
| Every command fails with `sandbox_apply: Operation not permitted` | You started without `-x`. Quit and run `sv-claude`. |
| A keychain password popup, or `Permission denied` in the shared folder | Files there have the wrong permissions. Run `sv --rebuild build`. On a daily account, the admin repeats [step b](#daily-account-without-admin-rights). |
| Daily account: `sv` asks for a password, or fails with `Permission denied` on `guest/home/.ssh` | The admin repeats [step b](#daily-account-without-admin-rights), for example after a SandVault upgrade. |
| `gcloud` or `terraform` fail TLS verification | Add the tool to `sandbox.excludedCommands` in `settings.jsonc`, as the settings do for `gh`, and repeat step 2. |
| `open` or `osascript` fail with error `-600` | The sandbox blocks Apple Events. Approve the retry outside the sandbox. |
| A command in SandVault can't find `node_modules`, a virtual environment or another ignored folder | Ignored files aren't synced. Create them in SandVault, for example with `sv-claude shell npm install`. |
| `sv-claude can't run commands as sandvault-…` | SandVault's sudo rule is missing. Run `sv --rebuild build`. On a daily account, the admin repeats [step b](#daily-account-without-admin-rights). |
| `sv-claude needs a newer git` | Run `brew install git`, then open a new terminal. On a daily account without admin rights, the admin account runs it. |
| `SandVault's account needs a newer git` | Update the Xcode Command Line Tools in System Settings, Software Update. On a daily account without admin rights, the admin account does it. |
