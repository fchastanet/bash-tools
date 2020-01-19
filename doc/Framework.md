# bash-framework/Framework.sh
# Functions
# function `Framework::expectUser`
> ***Public***

exits with message if current user is not the expected one

**Arguments**:
* $1 expected user login

**Exit**: code 1 if current user is not the expected one
# function `Framework::expectNonRootUser`
> ***Public***

exits with message if current user is root

**Exit**: code 1 if current user is root
# function `Framework::expectGlobalVariables`
> ***Public***

exits with message if expected global variable is not set

**Arguments**:
* $1 expected global variable

**Exit**: code 1 if expected global variable is not set
# function `Framework::GetAbsolutePath`
> ***Public***

get absolute file from relative path

**Arguments**:
* $1 relative file path

**Output**: absolute path (can be $1 if $1 begins with /)
# function `Framework::WrapSource`
> ***Internal***

source given file or exits with message on error

**Arguments**:
* $1 file to source

**Exit**: code 1 if error while sourcing
# function `Framework::SourceFile`
> ***Internal***

source given file. Do not source it again if it has already been sourced.

**Arguments**:
* $1 file to source

**Exit**: code 1 if error while sourcing
# function `Framework::SourcePath`
> ***Internal***

source given file.
 Do not source it again if it has already been sourced.
 try to source relative path from each libpath

**Arguments**:
* $1 file to source

**Exit**: code 1 if error while sourcing
# function `Framework::ImportOne`
> ***Public***

source given file.
 Do not source it again if it has already been sourced.
 try to source relative path from each libpath in this order:
    * vendor/bash-framework
    * vendor
    * calling script path
    * absolute path

**Arguments**:
* $1 file to source

**Exit**: code 1 if error while sourcing
# function `Framework::Import`
> ***Public***

source given files using Framework::ImportOne.

**Arguments**:
* $@ files to source

**Exit**: code 1 if error while sourcing

