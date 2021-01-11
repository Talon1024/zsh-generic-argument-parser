#!/usr/bin/env zsh
# This script parses arguments and stores them in variables
# Follows standard Linux/Unix conventions for arguments
# You will need to "source" this script in order to use the variables
# Licensed under MIT License © 2021 Kevin Caccamo

(){ # Begin main anonymous function
setopt extendedglob

defined_flags=()

main(){
    while [[ -n $1 ]]; do
        print " $1"
        if [[ $1 == (#i)flags:* ]]; then
            parse_flagdefs $1
        elif [[ $1 == \-\-[[:alnum:]-=]## ]]; then
            # Long flag or param
            parse_long $1
        elif [[ $1 == \-[[:alnum:]]## ]]; then
            # Short flag
            parse_short_flags $1
        fi
        shift
    done
}

parse_flagdefs(){
    # Parse a flag definition. Flag definition syntax:
    # flag: <flagname>[|<letter>]
    # flags: flag[:flag]...
    # example: flags:clean|c:no_asan|a
    # You need to quote the flags string in order for the script to parse
    # it properly.
    # If a flag is seen, a variable with its long name will be set to 1.
    local pos=6
    local len=1
    while [[ $((pos+len)) -lt ${#1} ]]; do
        ((len++))
        local curchar=${1[$((pos+len))]}
        if [[ $curchar == ":" ]]; then
            defined_flags+="${1:$pos:$((len-1))}"
            ((pos+=len))
            local len=1
        elif [[ $curchar == "-" ]]; then
            print "Invalid character '-' in flag definition! Use an underscore '_' instead"
            exit 1
        fi
    done
    defined_flags+="${1:$pos:$((len))}"
}

parse_long(){
    local pos=2
    local len=0
    local isparam=0
    [[ -n "${1[(r)=]}" ]] && local isparam=1
    for ((i=1;i<=${#defined_flags};i++)) do
        if [[ ${${1:2}/-/_} == ${defined_flags[i][1,-3]} ]]; then
            typeset -g ${defined_flags[i][1,-3]}=1
            return 0
        fi
    done
    if ((isparam)); then
        while [[ $((pos+len)) -lt ${#1} ]]; do
            # Assuming only one equals sign is used...
            if [[ ${1[$((pos+len))]} == '=' ]]; then
                local pk=${1:$pos:$((len - 1))}
                ((pos+=len))
                len=1
            fi
            ((len++))
        done
        local pv=${1:$pos}
    fi
    typeset -g $pk=$pv
    return 0
}

parse_short_flags(){
    local pos=1
    local len=0
    while [[ $((pos+len)) -lt ${#1} ]]; do
        ((len++))
        for ((i=1;i<=${#defined_flags};i++)) do
            if [[ -z ${defined_flags[i][(r)|]} ]]; then
                continue
            elif [[ "${1[$((pos+len))]}" == "${defined_flags[i][-1]}" ]]; then
                typeset -g ${defined_flags[i][1,-3]}=1
                break
            fi
        done
    done
    return 0
}

main $@
} $@ # End main anonymous function