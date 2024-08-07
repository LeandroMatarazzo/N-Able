#!/bin/sh  
OPTSTRING=":a"
while getopts ${OPTSTRING} opt; do
    case ${opt} in
        a)
            Admin=1
            ;;
            
    esac
done



if [ -n "$Admin" ]; then
    if test "$#" -ne 4; then
        echo "Must give Username and password"
        exit 1
    fi
    sysadminctl -addUser "$2" -fullName "$3"  -password "$4"  -admin 
else
    if test "$#" -ne 3; then
        echo "Must give Username and password"
        exit 1
    fi
    sysadminctl -addUser "$1" -fullName "$2"  -password "$3" 
fi