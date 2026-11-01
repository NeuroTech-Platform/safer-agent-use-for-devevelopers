# Shell commands under the user's sandbox settings

- Put temporary files in `.claude/tmp/` in the project folder. Create it, and once per repository add it to git's exclude list: `grep -qsx '.claude/tmp/' .git/info/exclude || echo '.claude/tmp/' >> .git/info/exclude`. Don't use other places:
  - `/tmp`, `/var/tmp` and the home folder: sandboxed commands can't write there.
  - `$TMPDIR` and the scratchpad: Claude's file tools can't read most of it, and it's emptied at restarts.
  - macOS `mktemp` without a template writes outside the project and fails. Give it a template: `mktemp .claude/tmp/name.XXXXXX`.
- Don't `cd`. Name paths relative to the working directory, or as absolute paths. Claude Code can't check where a path after a `cd` leads, so the command can need the user's approval.
- `gh`, `docker`, `kind`, `kubectl`, `helm`, `ct` and `cilium` run outside the sandbox, but only when the call holds nothing else. Otherwise the call runs in the sandbox, where they fail; `gh` prints `failed to read configuration`. Run each as a call of its own: no `cd`, pipes, `;`, `&&`, file redirects or `$(...)`. A newline without `\` starts another command too. If one failed in the sandbox, run it again that way. Don't ask to run it outside the sandbox.
- A saved command output, under `~/.claude/projects/…/tool-results/`, is readable with the Read and Grep tools only. Don't ask for an unsandboxed `grep` on it; ask for less output instead.
- Explore and Plan agents don't load this file. When you start one, put these rules in its prompt.
