#!/usr/bin/env bash
#
# Deletes all local branches that were squashed and merged
# Adapted from https://github.com/not-an-aardvark/git-delete-squashed
#
VERBOSE=0
POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
        --verbose|-v) VERBOSE=1 ;;
        *) POSITIONAL+=("$arg") ;;
    esac
done

TARGET=${POSITIONAL[0]:-$(git main-branch)}

echo "Pruning local branches that were squashed and merged onto $TARGET..."

git checkout -q $TARGET && git for-each-ref refs/heads/ "--format=%(refname:short)" |
    while read branch; do
        [[ $VERBOSE -eq 1 ]] && echo "Checking $branch ..."
        mergeBase=$(git merge-base $TARGET "$branch")

        if [[ $(git cherry $TARGET $(git commit-tree -p "$mergeBase" -m _ $(git rev-parse "$branch^{tree}"))) == "-"* ]]; then
            git branch -D "$branch"
        fi
    done