#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# new-skill.sh — Scaffold a new skill from the template
# Usage: bash scripts/new-skill.sh <skill-name> "<description>"
# Example: bash scripts/new-skill.sh google-workspace-cli "Google Workspace CLI automation"
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_ROOT/skills"
TEMPLATE_DIR="$SKILLS_DIR/_template"

SKILL_NAME="${1:?Usage: new-skill.sh <skill-name> \"<description>\"}"
DESCRIPTION="${2:?Please provide a skill description in quotes}"

# Validate skill name (lowercase, hyphens, alphanumeric)
if ! echo "$SKILL_NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
    echo "ERROR: Skill name must be lowercase, start with a letter, and contain only letters, digits, and hyphens."
    echo "  Got: '$SKILL_NAME'"
    exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

if [ -d "$SKILL_DIR" ]; then
    echo "ERROR: Skill '$SKILL_NAME' already exists at $SKILL_DIR"
    exit 1
fi

# --- Scaffold ---
echo "Creating skill: $SKILL_NAME"
echo "  Description: $DESCRIPTION"
echo ""

mkdir -p "$SKILL_DIR"

# Generate triggers from skill name
TRIGGER_WORDS=$(echo "$SKILL_NAME" | tr '-' ' ')

# Copy and fill template files
for template_file in "$TEMPLATE_DIR"/*.md; do
    filename=$(basename "$template_file")
    sed \
        -e "s|{{SKILL_NAME}}|$SKILL_NAME|g" \
        -e "s|{{DESCRIPTION}}|$DESCRIPTION|g" \
        -e "s|{{TRIGGER_1}}|${TRIGGER_WORDS}|g" \
        -e "s|{{TRIGGER_2}}|${SKILL_NAME}|g" \
        -e "s|{{USE_CASE_1}}|TODO: Describe use case 1|g" \
        -e "s|{{USE_CASE_2}}|TODO: Describe use case 2|g" \
        "$template_file" > "$SKILL_DIR/$filename"
done

echo "Skill scaffolded at: $SKILL_DIR"
echo ""
echo "Files created:"
ls -la "$SKILL_DIR/"
echo ""
echo "Next steps:"
echo "  1. Edit $SKILL_DIR/SKILL.md with your skill instructions"
echo "  2. Edit $SKILL_DIR/README.md with usage documentation"
echo "  3. Run 'npm run validate' to check your skill format"
echo "  4. Add any helper scripts or assets to $SKILL_DIR/"
