# Shell commands under the user's sandbox settings

- Put temporary files in the scratchpad folder Claude Code gives you, and name it by its full path. Don't use other places:
  - `/tmp`, `/var/tmp` and the home folder: sandboxed commands can't write there.
  - The rest of `$TMPDIR`: Claude's file tools can't read it.
  - macOS `mktemp` without a template writes outside `$TMPDIR` and fails. Give it a template in the scratchpad: `mktemp <scratchpad>/name.XXXXXX`.
- Don't `cd`. Name paths relative to the working directory, or as absolute paths. Claude Code can't check where a path after a `cd` leads, so the command can need the user's approval.
- `gh`, `docker`, `kind`, `kubectl`, `helm`, `ct` and `cilium` run outside the sandbox, but only when the call holds nothing else. Otherwise the call runs in the sandbox, where they fail; `gh` prints `failed to read configuration`. Run each as a call of its own: no `cd`, pipes, `;`, `&&`, file redirects or `$(...)`. If one failed in the sandbox, run it again that way. Don't ask to run it outside the sandbox.
- Name the repository with `--repo owner/name`, or in the `gh api` path. Filter `gh` output with `--jq` instead of a pipe.
- The user approves each `gh` call, each `docker run`, `exec`, `build`, `buildx build` and `compose` call, and each command that runs code in a cluster or changes one: `kubectl apply`, `create`, `run`, `exec`, `delete`, `helm install`, `upgrade`, `uninstall`, `kind create`, `delete`, `ct install`, `cilium install`. Get what you need in as few calls as possible.
- Make every command legible to the user: one action per call, long option names, nothing the task doesn't need. Put a command on several lines, one option per line and each line but the last ending with ` \`, when one line would be hard to read, and always when the command needs the user's approval. Keep it one command: a newline without `\` starts another command, and the call then stays in the sandbox.
- A saved command output, under `~/.claude/projects/…/tool-results/`, is readable with the Read and Grep tools only. Don't ask for an unsandboxed `grep` on it; ask for less output instead.
- Explore and Plan agents don't load this file. When you start one, put these rules in its prompt.
