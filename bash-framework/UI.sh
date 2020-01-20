#!/usr/bin/env bash

# Public: ask the user if he wishes to continue a process
#
# **Input**: user input y or Y characters
# **Output**: displays message <pre>Are you sure, you want to continue (y or n)?</pre>
# **Exit**: with error code 1 if y or Y, other keys do nothing
UI::askToContinue() {
    read -p "Are you sure, you want to continue (y or n)? " -n 1 -r
    echo    # move to a new line
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        # answer is other than y or Y
        exit 1
    fi
}

# Public: ask the user a confirmation
#
# **Arguments**:
# * $1 - message that will be prepended to " (y or n)?"
#
# **Input**: user input any characters
#
# **Output**:
# * displays message <pre>[msg arg $1] (y or n)?</pre>
# * if characters entered different than [yYnN] displays "Invalid answer" and continue to ask
#
# **Returns**:
# * 0 if y or Y
# * 1 if n or N
UI::askYesNo() {
    while true; do
        read -p "$1 (y or n)? " -n 1 -r
        echo    # move to a new line
        case ${REPLY} in
            [yY]) return 0;;
            [nN]) return 1;;
            *)
                read -r -N 10000000 -t '0.01' ||true; # empty stdin in case of control characters
                # \\r to go back to the beginning of the line
                Log::displayError "\\r invalid answer                                                          "
        esac
    done
}

readonly __bash_framework__choice_ignore=0
readonly __bash_framework__choice_overwrite=1

# Public: ask the user to ignore(i), overwrite(o) or abort(a)
#
# **Input**: user input any characters
#
# **Output**:
# * displays message <pre>do you want to ignore(i), overwrite(o), abort(a) ?</pre>
# * if characters entered different than [iIoOaA] displays "Invalid answer" and continue to ask
#
# **Returns**:
# * 0 if i or I
# * 1 if o or O
# **Exit**:
# * 1 if a or A
UI::askToIgnoreOverwriteAbort() {
    while true
    do
        read -p "do you want to ignore(i), overwrite(o), abort(a) ? " -n 1 -r
        echo    # move to a new line
        case ${REPLY} in
            [iI]) return ${__bash_framework__choice_ignore} ;;
            [oO]) return ${__bash_framework__choice_overwrite} ;;
            [aA]) exit 1 ;;
            *)
                read -r -N 10000000 -t '0.01' ||true; # empty stdin in case of control characters
                # \\r to go back to the beginning of the line
                Log::displayError "\\r invalid answer                                                          "
        esac
    done
    # we can't arrive here
}
