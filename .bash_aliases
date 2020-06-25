# https://stackoverflow.com/a/17843908/3045926
alias git-show-parent_branches=git show-branch -a 2>/dev/null | grep '\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'
# https://stackoverflow.com/a/43585658/3045926
alias git-reverse-tree='git log --graph --decorate --simplify-by-decoration --oneline'

# or use git show-branch
