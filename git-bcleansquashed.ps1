#
# Deletes all local branches that were squashed and merged
# Adapted from https://github.com/not-an-aardvark/git-delete-squashed
# PowerShell port of git-bcleansquashed.sh
#
$Verbose = $false
$Positional = @()
foreach ($arg in $args) {
    switch ($arg) {
        { $_ -in '--verbose', '-v' } { $Verbose = $true }
        default { $Positional += $arg }
    }
}

$Target = if ($Positional.Count -gt 0) { $Positional[0] } else { (git main-branch) }

Write-Output "Pruning local branches that were squashed and merged onto $Target..."

git checkout -q $Target
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

foreach ($branch in (git for-each-ref refs/heads/ "--format=%(refname:short)")) {
    if ($Verbose) { Write-Output "Checking $branch ..." }
    $mergeBase = git merge-base $Target $branch
    $tree = git rev-parse "$branch^{tree}"
    $commit = git commit-tree -p $mergeBase -m _ $tree

    if ((git cherry $Target $commit) -like '-*') {
        $worktree = $null
        $path = $null
        foreach ($line in (git worktree list --porcelain)) {
            if ($line.StartsWith('worktree ')) { $path = $line.Substring(9) }
            elseif ($line -eq "branch refs/heads/$branch") { $worktree = $path; break }
        }
        if ($worktree) {
            if ($Verbose) { Write-Output "Removing worktree $worktree for $branch ..." }
            git worktree remove $worktree
            if ($LASTEXITCODE -ne 0) { continue }
        }
        git branch -D $branch
    }
}
