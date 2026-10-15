# Safer Agent for developers

These are settings and setup steps that limit what Claude Code can read, change and reach on your computer. For developers on macOS, Linux and Windows.

Requires Claude Code 2.1.285 or later. Check with `claude --version`.

## What you get

- Shell commands run in an OS sandbox. They write only in the project, a temp folder and the npm cache. They can't read home folders or mounted drives, except the project.
- Shell commands reach only the allowlisted development dependencies, package registries
  and operating-system repositories. Other hosts are refused.
- Claude's file tools can't read outside the project.
- SSH keys and cloud credentials are blocked. `.env` files are blocked for Claude's file tools and for commands like `cat`. Token variables are removed from shell commands.
- Claude can't change Claude Code's settings files or your personal instructions (`~/.claude/CLAUDE.md`, `~/.claude/rules/`).
- Claude asks before it retries a command outside the sandbox, before docker commands that run code (`run`, `exec`, `build`, `compose`), before commands that run code in a cluster or change one (`kubectl apply`, `helm install`, `kind create`, and the like), and before every `gh` command.
- Sessions start in auto mode: a classifier approves routine actions and blocks risky ones. Bypass mode is off.
- Verbose view shows every tool call in full.
- Claude Code's telemetry is off: no usage metrics, error reports, surveys or feedback uploads. [docs/data.md](docs/data.md) lists what is still sent.

[settings.jsonc](settings.jsonc) explains each setting.

## What it does not cover

- Code Claude writes runs with your full access when you run it yourself: tests, npm scripts, Makefiles, build steps. Review it before you run it.
- Hooks, MCP servers and plugins run with your full access. Install only what you trust.
- Settings in a repository's `.claude/` folder can switch the sandbox off, and the trust dialog doesn't show it. Read that folder before you trust a repository, or use [managed settings](docs/managed-settings.md).
- Claude's web tool (WebFetch) ignores the host list. In auto mode the classifier reviews fetches.
- Commands you approve outside the sandbox, the `docker`, `gh`, `kind`, `kubectl`, `helm`, `ct` and `cilium` commands, and commands you type after `!` run with your full access.
- Claude sends what it reads to Anthropic. See [docs/data.md](docs/data.md).

## Install

1. Prepare your system:
   - macOS: [docs/macos.md](docs/macos.md)
   - Linux: [docs/linux.md](docs/linux.md)
   - Windows: [docs/windows.md](docs/windows.md)
2. From this folder, install the settings and the instructions for Claude. Nothing applies until you do: Claude Code doesn't read `settings.jsonc` itself. `grep` removes the comment lines, because Claude Code reads strict JSON only:

   ```bash
   mkdir -p ~/.claude/rules
   [ -f ~/.claude/settings.json ] && [ ! -f ~/.claude/settings.json.bak ] && cp ~/.claude/settings.json ~/.claude/settings.json.bak
   grep -v '^[[:space:]]*//' settings.jsonc > ~/.claude/settings.json
   cp rules/sandbox.md ~/.claude/rules/
   ```

   The first install saves your old settings in `settings.json.bak`. Move your own keys from there into `settings.jsonc`. Make every later change in `settings.jsonc` and repeat this step, because it overwrites `~/.claude/settings.json`.

   [rules/sandbox.md](rules/sandbox.md) tells Claude how to write shell commands that work with these settings without extra prompts. Claude Code loads it in every session.
3. Run `claude doctor`. It must report no settings errors.

## Verify

Start Claude in a project folder: `claude`, or `sv-claude` on macOS with SandVault.

Run `/sandbox`. The Config tab must list `github.com` and the other allowed hosts. On Linux and WSL2, a Dependencies tab means a component is missing.

Then ask Claude to run each command:

| Command | Expected result |
| --- | --- |
| `touch ~/sandbox-probe` | `Operation not permitted` on macOS, `Read-only file system` on Linux and WSL2 |
| `curl --noproxy '*' https://example.com` | `Could not resolve host`: no direct connections |
| `curl -sS https://example.com` | Fails with `response 403`: the host is not on the list |
| `curl -sSI https://github.com` | `HTTP/2 200`: the host is on the list |
| `cat .env`, in a project with a `.env` file | Refused |
| `[ -z "${GITHUB_TOKEN-}" ] && echo removed`, if you export `GITHUB_TOKEN` | `removed` |

Last, ask Claude to read `~/.zshrc` or another file in your home folder. It must refuse.

If Claude asks to retry a test outside the sandbox, answer No. If `touch` succeeds, the sandbox is not running: delete `~/sandbox-probe` and fix the setup before you use Claude.

## Rules

- Start Claude in the project folder, never in your home folder.
- Before you trust a repository you didn't write, read everything in its `.claude/` folder, plus `.mcp.json` and `CLAUDE.md`.
- Read each prompt before you answer. `Ctrl+E` explains a command.
- Don't paste secrets into the chat.
- Review the diff before you run or commit Claude's work.

## Project settings (optional)

A project needs no settings of its own. The installed settings already let Claude read the project folder.

To let routine commands run without auto mode's check, list them in the project's `.claude/settings.json` and commit the file:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Bash(npm test)", "Bash(pytest)"]
  }
}
```

- Name exact commands. Auto mode drops broad rules such as `Bash(npm run *)`.
- Personal rules go in `.claude/settings.local.json`. When you answer "Yes, and don't ask again" on a prompt, Claude Code saves the rule there and keeps the file out of git.
- Under the installed settings, Claude Code ignores `allowRead`, `allowWrite` and `allowedDomains` in a project's settings.

## When something fails

| Problem | Fix |
| --- | --- |
| A host is refused | Add it to `sandbox.network.allowedDomains` in `settings.jsonc` and repeat the install. Repository settings can't add hosts. |
| A tool or cache in your home folder is missing or read-only (nvm, pyenv, cargo, pip) | Add its folder to `sandbox.filesystem.allowRead` in `settings.jsonc`, and to `allowWrite` if it writes there. Use `~/` paths. Repeat the install. |
| A tool can't read its login or config in your home folder, such as `gcloud` | Add it to `sandbox.excludedCommands` in `settings.jsonc`, for example `"gcloud *"`, and repeat the install. It then runs outside the sandbox with your full access, and auto mode reviews each call. To approve each call yourself, also add an ask rule such as `"Bash(gcloud *)"`. |
| `git push` or `git pull` fails | The sandbox hides your credentials. Approve the retry outside the sandbox, or run the command yourself. |
| A script or test can't write to `/tmp`, or `mktemp` fails with `Operation not permitted` | Sandboxed commands write only in the project, `$TMPDIR` and the npm cache. Make the script use `$TMPDIR`, as Python's `tempfile` and Node's `os.tmpdir()` do. On macOS, `mktemp` without a template doesn't use `$TMPDIR`: give it one, such as `mktemp "${TMPDIR:-/tmp}/name.XXXXXX"`. |
| A command can't reach a server on `localhost` | macOS: set `sandbox.network.allowLocalBinding` to `true`; this opens every local port. Linux and WSL2: add the command to `sandbox.excludedCommands`; it then runs with your full access. |
| Auto mode blocked an action you want | Run `/permissions`, open **Recently denied**, select the action and press `r`. |

Each OS page lists its own problems.

## More

- [docs/data.md](docs/data.md): what Claude Code sends to Anthropic
- [docs/managed-settings.md](docs/managed-settings.md): settings that repositories and Claude can't change
- [docs/unattended.md](docs/unattended.md): running Claude without prompts
