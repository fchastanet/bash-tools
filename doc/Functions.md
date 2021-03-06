# bash-framework/Functions.sh

## Functions

### Function `Functions::checkCommandExists`

> ***Public***

check if command specified exists or exits
 with error and message if not

**Arguments**:
* $1 commandName on which existence must be checked
* $2 helpIfNotExists a help command to display if the command does not exist

**Exit**: code 1 if the command specified does not exist

### Function `Functions::isWindows`

> ***Public***

determine if the script is executed under windows
 <pre>
 uname GitBash windows (with wsl) => MINGW64_NT-10.0 ZOXFL-6619QN2 2.10.0(0.325/5/3) 2018-06-13 23:34 x86_64 Msys
 uname GitBash windows (wo wsl)   => MINGW64_NT-10.0 frsa02-j5cbkc2 2.9.0(0.318/5/3) 2018-01-12 23:37 x86_64 Msys
 uname wsl => Linux ZOXFL-6619QN2 4.4.0-17134-Microsoft #112-Microsoft Thu Jun 07 22:57:00 PST 2018 x86_64 x86_64 x86_64 GNU/Linux
 </pre>

**Echo**: "1" if windows, else "0"

### Function `Functions::quote`

> ***Public***

quote a string
 replace ' with '

**Arguments**:
* $1 the string to quote

**Output**: the string quoted

### Function `Functions::getList`

> ***Public***

list files of dir with given extension and display it as a list one by line

**Arguments**:
* $1 the directory to list
* $2 the extension (default: sh)
* $3 the indentation ('       - ' by default) can be any string compatible with sed not containing any /
 **Output**: list of files without extension/directory
 eg:
        - default.local
        - default.remote
        - localhost-root

### Function `Functions::loadConf`

> ***Public***

get absolute file from name deduced using these rules
    * using absolute/relative <conf> file (ignores <confFolder> and <extension>
    * from home/.bash-tools/<confFolder>/<conf><extension> file
    * from framework conf/<conf><extension> file

**Arguments**:
* $1 confFolder to use below bash-tools conf folder
* $2 conf file to use without extension
* $3 file extension to use (default: sh)

Returns 1 if file not found or error during file loading

### Function `Functions::getConfMergedList`

> ***Public***

list the conf files list available in bash-tools/conf/<conf> folder
 and those overriden in $HOME/.bash-tools/<conf> folder
 **Arguments**:
* $1 confFolder the directory name (not the path) to list
* $2 the extension (sh by default)
* $3 the indentation ('       - ' by default) can be any string compatible with sed not containing any /

**Output**: list of files without extension/directory
 eg:
        - default.local
        - default.remote
        - localhost-root

### Function `Functions::getAbsoluteConfFile`

> ***Public***

get absolute conf file from specified conf folder deduced using these rules
    * from absolute file (ignores <confFolder> and <extension>)
    * relative to where script is executed (ignores <confFolder> and <extension>)
    * from home/.bash-tools/<confFolder>
    * from framework conf/<confFolder>

**Arguments**:
* $1 confFolder the directory name (not the path) to list
* $2 conf file to use without extension
* $3 the extension (sh by default)

Returns absolute conf filename

### Function `Functions::trapAdd`

appends a command to a trap

- 1st arg:  code to add
 - remaining args:  names of traps to modify

### Function `extract_trap_cmd`

helper fn to get existing trap command from output
 of trap -p

### Function `Functions::run`

*Public*: run command and store data in following global variables :
* bash_framework_status the exit status of the command
* bash_framework_duration the duration of the command
* bash_framework_output the output of the command
 redirecting error output to stdout is not supported, you can instead redirect stderr to a file if needed
 **Arguments**:
* $@ command with arguments to execute

## Variables

### Variable `bash_framework_status`

global variables used by Functions:run
