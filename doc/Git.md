# bash-framework/Git.sh
# Functions
# function `Git::ShallowClone`
> ***Public***

shallow clone a repository at specific commit sha, tag or branch
 or update repo if already exists

**Arguments**:
* $1 repository
* $2 Install dir
* $3 revision commit sha, tag or branch
* $4 put 1 to force directory deletion if directory exists and it's not a git repository (default: 0)
      USE THIS OPTION WITH CAUTION !!! as the directory will be deleted without any prompt

**Return**:
* code !=0 if git failure or directory not writable
* code=1 if destination dir already exists and force option is not 1
