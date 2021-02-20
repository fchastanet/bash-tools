# bash-framework/File.sh

## Functions

### Function `File::garbageCollect`

> ***Public***

delete files older than n days

**Arguments**:
* $1 path
* $2 modfication time
    eg: +1 match files that have been accessed at least two days ago (rounding effect)
 @see man find atime

**Exit**: code 1 if the command failed
