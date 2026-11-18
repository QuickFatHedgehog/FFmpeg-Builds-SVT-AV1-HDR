#!/bin/bash
#
# Pin scripts.d/50-svtav1.sh to a newer SVT-AV1-HDR commit.
#
# By default the tip of upstream main is used. Pass --ref to follow a
# different branch, tag, or full commit instead (e.g. --ref v4.3.0).
#
# Usage:
#   util/update_svtav1.sh [--ref <branch|tag|commit>] [--dry-run]
#
# When GITHUB_OUTPUT is set, changed/commit/version/repo are written there
# for the update-svt-av1-hdr workflow.

set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts.d/50-svtav1.sh"
REF=""
DRY_RUN=0

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ref)
            REF="${2:?--ref needs a value}"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

REPO="$(sed -n 's/^SCRIPT_REPO="\(.*\)"$/\1/p' "$SCRIPT")"
CURRENT="$(sed -n 's/^SCRIPT_COMMIT="\(.*\)"$/\1/p' "$SCRIPT")"
[[ -n "$REPO" ]] || { echo "error: no SCRIPT_REPO in $SCRIPT" >&2; exit 1; }
[[ -n "$CURRENT" ]] || { echo "error: no SCRIPT_COMMIT in $SCRIPT" >&2; exit 1; }

# Resolve a branch, tag, or full commit to a commit SHA.
resolve_commit() {
    local ref="$1" out
    if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
        printf '%s\n' "$ref"
        return 0
    fi
    out="$(git ls-remote "$REPO" "$ref" 2>/dev/null || true)"
    if [[ -z "$out" ]]; then
        out="$(git ls-remote "$REPO" "refs/heads/$ref" "refs/tags/$ref" 2>/dev/null || true)"
    fi
    [[ -n "$out" ]] || return 1
    # Annotated tags list both the tag object and its peeled commit.
    if grep -q '\^{}$' <<<"$out"; then
        awk '/\^\{\}$/ { print $1; exit }' <<<"$out"
    else
        awk 'NR == 1 { print $1 }' <<<"$out"
    fi
}

if [[ -z "$REF" ]]; then
    REF="main"
    echo "Following upstream main"
fi

COMMIT="$(resolve_commit "$REF")" || { echo "error: cannot resolve $REF in $REPO" >&2; exit 1; }

if [[ "$REF" =~ ^v[0-9] ]]; then
    VERSION="$REF"
elif [[ "$REF" =~ ^[0-9a-f]{40}$ ]]; then
    VERSION="${COMMIT:0:12}"
else
    VERSION="${REF}@${COMMIT:0:12}"
fi

echo "Repository: $REPO"
echo "Ref:        $REF"
echo "Commit:     $COMMIT"
echo "Current:    $CURRENT"

CHANGED=false
if [[ "$COMMIT" != "$CURRENT" ]]; then
    CHANGED=true
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "Would update $SCRIPT to $COMMIT"
    else
        tmp="$(mktemp)"
        sed "s/^SCRIPT_COMMIT=.*/SCRIPT_COMMIT=\"$COMMIT\"/" "$SCRIPT" >"$tmp"
        cat "$tmp" >"$SCRIPT"
        rm -f "$tmp"
        echo "Updated $SCRIPT"
    fi
else
    echo "Already up to date"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
        echo "changed=$CHANGED"
        echo "commit=$COMMIT"
        echo "version=$VERSION"
        echo "repo=$REPO"
    } >>"$GITHUB_OUTPUT"
fi
