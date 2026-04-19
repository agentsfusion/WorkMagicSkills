# WorkMagicSkills

A monorepo of domain-specific agent skills for CLI tools and platforms.

## Structure

```
WorkMagicSkills/
├── skills/                          # All skills live here
│   ├── _template/                   # Template for creating new skills
│   │   ├── SKILL.md                 # Skill definition template
│   │   └── README.md                # Skill docs template
│   ├── google-workspace-cli/        # Google Workspace CLI skill
│   └── lark-cli/                    # Lark/Feishu CLI skill
├── scripts/
│   ├── new-skill.sh                 # Scaffold a new skill
│   └── validate.sh                  # Validate all skills
├── .editorconfig
├── .gitignore
├── LICENSE
├── package.json
└── README.md
```

## Quick Start

### Create a New Skill

```bash
bash scripts/new-skill.sh <skill-name> "<description>"
```

Example:

```bash
bash scripts/new-skill.sh notion-cli "Notion CLI for workspace automation"
```

### Validate Skills

```bash
bash scripts/validate.sh
```

### List Skills

```bash
npm run list
```

## Skill Anatomy

Each skill is a directory under `skills/` containing:

| File | Required | Description |
|------|----------|-------------|
| `SKILL.md` | Yes | Main skill definition with frontmatter and instructions |
| `README.md` | Recommended | Usage docs, installation, examples |
| `*.sh` / `*.js` | Optional | Helper scripts specific to the skill |
| `assets/` | Optional | Diagrams, templates, or reference files |

### SKILL.md Format

```yaml
---
name: my-skill
description: What this skill does
triggers:
  - trigger phrase 1
  - trigger phrase 2
---

# Skill Title

## When to Use
## Instructions
## Examples
## Troubleshooting
```

## Adding a Skill

1. Run `bash scripts/new-skill.sh <name> "<desc>"` to scaffold
2. Edit `skills/<name>/SKILL.md` with your instructions
3. Add helper scripts/assets as needed
4. Run `bash scripts/validate.sh` to verify
5. Commit and push

## License

MIT
