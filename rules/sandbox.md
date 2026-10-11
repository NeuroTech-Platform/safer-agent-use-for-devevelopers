# Shell commands under the user's sandbox settings

- Put temporary files in the scratchpad folder Claude Code gives you, and name it by its full path. Don't use other places:
  - `/tmp`, `/var/tmp` and the home folder: sandboxed commands can't write there.
  - The rest of `$TMPDIR`: Claude's file tools can't read it.
  - macOS `mktemp` without a template writes outside `$TMPDIR` and fails. Give it a template in the scratchpad: `mktemp <scratchpad>/name.XXXXXX`.
- Don't `cd`. Name paths relative to the working directory, or as absolute paths. Claude Code can't check where a path after a `cd` leads, so the command can need the user's approval.
- `gh`, `docker ps`, `docker logs` and `docker exec` run outside the sandbox, but only when the call holds nothing else. Otherwise the call runs in the sandbox, where they fail; `gh` prints `failed to read configuration`. Run each as a call of its own: no `cd`, pipes, `;`, `&&`, file redirects or `$(...)`. If one failed in the sandbox, run it again that way. Don't ask to run it outside the sandbox.
- Name the repository with `--repo owner/name`, or in the `gh api` path. Filter `gh` output with `--jq` instead of a pipe.
- The user approves each `gh` and `docker exec` call. Get what you need in as few calls as possible.
- Explore and Plan agents don't load this file. When you start one, put these rules in its prompt.
