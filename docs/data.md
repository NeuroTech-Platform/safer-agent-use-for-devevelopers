# Data sent to Anthropic

Claude Code runs on your computer, but the model runs at Anthropic. Your prompts and everything Claude reads (files, command output) go to Anthropic's API, encrypted in transit. Don't let Claude read data that your plan or your employer doesn't allow you to share with Anthropic.

## Training and retention

| Plan | Used for training | Kept for |
| --- | --- | --- |
| Free, Pro, Max | Only if you allow it in [privacy settings](https://claude.ai/settings/data-privacy-controls) | 30 days, or 5 years if you allow training |
| Team, Enterprise, API | No | 30 days. Zero data retention is available for qualified Claude for Enterprise accounts |

## Telemetry

The settings turn off Claude Code's telemetry:

- usage metrics (`DISABLE_TELEMETRY`)
- session surveys (also covered by `DISABLE_TELEMETRY`)
- error reports (`DISABLE_ERROR_REPORTING`)
- `/feedback`, `/bug` and `/share` (`DISABLE_FEEDBACK_COMMAND`), which upload the conversation, including code, and keep it for 5 years

This also turns off feature flags, so Remote Control and a few extras stop working.

Still sent:

- Before each WebFetch, the hostname (not the full URL) goes to Anthropic for a safety check. `"skipWebFetchPreflight": true` turns this off, and the protection with it.
- Update checks, release notes and status checks. `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` stops these too, including automatic updates. You then update by hand with `claude update`.


## On your computer

Claude Code stores session transcripts in plain text under `~/.claude/projects/` for 30 days. Change the period with `cleanupPeriodDays`.
