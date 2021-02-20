# bash-framework/Version.sh

## Functions

### Function `Version::checkMinimal`

> ***Public***

ensure that command exists with expected version

**Arguments**:
* $1 command name
* $2 the command to execute to retrieve the version
* $3 the expected command version

**Output**:
* Warning message : ${commandName} version is ${version} greater than ${minimalVersion}, OK let's continue
* Error message : ${commandName} minimal version is ${minimalVersion}, your version is ${version}

**Exit**:
* code 2 and error message if command exists but current version is less than expected minimal version

### Function `Version::compare`

> ***Public***

compare version

**Arguments**:
* $1 ersion 1
* $2 version 2

**Return**:
* 0 if equal
* 1 if version1 > version2
* 2 else
