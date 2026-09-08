# Skills

Three skills, all authored here. They cover the three things this repository asks
you to write — a plan, an audit, a memory note — because a template shows the
shape and a skill carries the judgement.

| Skill | Invoked when |
|---|---|
| `plan-authoring` | starting a plan, or repairing one the gate rejected |
| `audit-authoring` | reporting measurements, or answering "how is X doing" with numbers |
| `memory-notes` | asked to remember something, or the knowledge linter reports findings |

## Frontend and motion skills

Not shipped here, on purpose. The best ones are already maintained upstream —
[emilkowalski/skills](https://github.com/emilkowalski/skills) (MIT) covers
animation craft, motion review and toast handling — and vendoring a copy means
inheriting the job of tracking its drift.

If you want them, install them from upstream and pin the commit:

```sh
git clone https://github.com/emilkowalski/skills /tmp/skills
git -C /tmp/skills rev-parse HEAD          # record this in your own VENDOR.md
cp -R /tmp/skills/<skill> .claude/skills/
```

Record the source, the pinned commit and the date. A vendored copy is a fork:
pinning it is right, forgetting that it is now yours to patch is not.
