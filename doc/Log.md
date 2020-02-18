# bash-framework/Log.sh
# Functions
# function `__logMessage`
> ***Internal***

common log message

**Arguments**:
* $1 - message's level description
* $2 - messsage
 **Output**:
 if levelMsg empty

* [date] - message else

* [date] - [levelMsg] - message

**Examples**:
 <pre>
 2020-01-19 19:20:21 - ERROR   - log message
 </pre>
# function `__displayError`
> ***Public***

display error message on stderr

**Arguments**:
* $1 - messsage
 **Output**: using error color

* ERROR - message
# function `__displayWarning`
> ***Public***

display warning message on stderr

**Arguments**:
* $1 - messsage
 **Output**: using warning color

* WARN - message
# function `__displayInfo`
> ***Public***

display info message on stderr

**Arguments**:
* $1 - messsage
 **Output**: using info color

* INFO - message
# function `__displayDebug`
> ***Public***

display debug message on stderr

**Arguments**:
* $1 - messsage
 **Output**: using debug color

* DEBUG - message
# function `__displaySuccess`
> ***Public***

display success message on stderr

**Arguments**:
* $1 - messsage
 **Output**: using success color
 message
