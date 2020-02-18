# bash-framework/UI.sh
# Functions
# function `UI::askToContinue`
> ***Public***

ask the user if he wishes to continue a process

**Input**: user input y or Y characters
 **Output**: displays message <pre>Are you sure, you want to continue (y or n)?</pre>
 **Exit**: with error code 1 if y or Y, other keys do nothing
# function `UI::askYesNo`
> ***Public***

ask the user a confirmation

**Arguments**:
* $1 - message that will be prepended to " (y or n)?"

**Input**: user input any characters

**Output**:
* displays message <pre>[msg arg $1] (y or n)?</pre>
* if characters entered different than [yYnN] displays "Invalid answer" and continue to ask

**Returns**:
* 0 if y or Y
* 1 if n or N
# function `UI::askToIgnoreOverwriteAbort`
> ***Public***

ask the user to ignore(i), overwrite(o) or abort(a)

**Input**: user input any characters

**Output**:
* displays message <pre>do you want to ignore(i), overwrite(o), abort(a) ?</pre>
* if characters entered different than [iIoOaA] displays "Invalid answer" and continue to ask

**Returns**:
* 0 if i or I
* 1 if o or O
 **Exit**:
* 1 if a or A
