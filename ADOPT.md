# ADOPT - pulling this onto any codebase

Order matters. Each layer assumes the one below it.

## Layer 0 - Ledger and hygiene (day 1)

- [ ] Everything in git, nothing durable on a laptop.
- [ ] Durable state (baselines, checkpoints, archives) in object storage, boxes disposable.
- [ ] Secrets in a vault or env file with 600 perms - never in the repo, never in logs, never in prompts. Agents source the env file; they never see the values.
- [ ] Issue-first: no work without an issue; PRs start with `Closes #n`.

## Layer 1 - CI you control (day 1-2)

- [ ] Self-hosted runner on a box you own, confined to a cgroup slice with a memory ceiling.
- [ ] KillMode=mixed on the runner unit.
- [ ] Merge-on-green rule written down; staging before prod; ancestor-verify after merges.
- [ ] /tmp policy: tmpfs is RAM; big scratch goes to disk.

## Layer 2 - Agents in lanes (week 1)

- [ ] Driver/executor split; lanes in worktrees with owned-file lists.
- [ ] Lane prompt template (see templates/lane-prompt.md).
- [ ] Adversarial review gate before every non-trivial push; verdict line required.
- [ ] Status files so any lane can cold-resume.
- [ ] Kill-safety: PIDs captured at launch, no name-based kills.

## Layer 3 - Timers and the sweep (week 2)

- [ ] Each recurring job is a systemd user timer with a log file.
- [ ] Alert-on-delta contract: baseline file, exit 10, NEW FINDINGS marker.
- [ ] One nightly/periodic sweep reads all logs and reports deltas only.
- [ ] Mirror job feeds all readers.

## Layer 4 - Audit fleet and twin (week 3+)

- [ ] Stand up the audit loops in this order: 1 (mirrors), 4 (secrets), 10 (access), 6 (CI health), then the rest.
- [ ] Add the twin box when the primary sweats; identical units; spill labels.
- [ ] Quarterly: restore drill from backups, DR drill in a throwaway VPC.

## What to copy from templates/

- `templates/memguard.service` + `templates/memguard.sh` - the memory watchdog
- `templates/audit-loop.sh` - the baseline/diff/exit-10 skeleton
- `templates/example.timer` + `templates/example.service` - the timer pair
- `templates/lane-prompt.md` - the lane prompt skeleton
- `templates/review-brief.md` - the adversarial review brief skeleton
