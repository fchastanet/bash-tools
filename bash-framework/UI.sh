#!/usr/bin/env bash

UI::askToContinue() {
    read -p "Are you sure, you want to continue (y or n)? " -n 1 -r
    echo    # move to a new line
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        # answer is other than y or Y
        exit 1
    fi
}

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
