#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# validate.sh — Validate all skills in the repository
# Usage: bash scripts/validate.sh [--fix]
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_ROOT/skills"

FIX_MODE=false
if [[ "${1:-}" == "--fix" ]]; then
    FIX_MODE=true
fi

ERRORS=0
WARNINGS=0
SKILLS_FOUND=0

echo "=== WorkMagicSkills Validator ==="
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")

    [ "$skill_name" = "_template" ] && continue

    SKILLS_FOUND=$((SKILLS_FOUND + 1))
    has_error=false

    echo "Checking: $skill_name"

    if [ ! -f "$skill_dir/SKILL.md" ]; then
        echo "  ERROR: Missing SKILL.md"
        ERRORS=$((ERRORS + 1))
        has_error=true
    else
        if ! head -5 "$skill_dir/SKILL.md" | grep -q "^---"; then
            echo "  ERROR: SKILL.md missing YAML frontmatter (---)"
            ERRORS=$((ERRORS + 1))
            has_error=true
        fi

        for field in "name:" "description:" "triggers:"; do
            if ! grep -q "$field" "$skill_dir/SKILL.md"; then
                echo "  ERROR: SKILL.md frontmatter missing '$field'"
                ERRORS=$((ERRORS + 1))
                has_error=true
            fi
        done

        if grep -q "{{" "$skill_dir/SKILL.md"; then
            echo "  WARNING: SKILL.md contains unfilled template placeholders ({{ ... }})"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    if [ ! -f "$skill_dir/README.md" ]; then
        echo "  WARNING: Missing README.md"
        WARNINGS=$((WARNINGS + 1))
    fi

    empty_count=$(find "$skill_dir" -type d -empty | wc -l)
    if [ "$empty_count" -gt 0 ]; then
        echo "  WARNING: Found $empty_count empty subdirectory(ies)"
        WARNINGS=$((WARNINGS + 1))
    fi

    if [ "$has_error" = false ]; then
        echo "  OK"
    fi
    echo ""
done

echo "=== Summary ==="
echo "  Skills checked: $SKILLS_FOUND"
echo "  Errors:         $ERRORS"
echo "  Warnings:       $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo "VALIDATION FAILED"
    exit 1
else
    echo "ALL CHECKS PASSED"
    exit 0
fi
