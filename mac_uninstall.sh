#!/bin/sh


App=$1

if test "$#" -ne 1; then
    echo "must past the name of the app to delete as argument"
    exit 1
fi

echo "Trying to delete ${App}"

Path_To_App=$(system_profiler SPApplicationsDataType | sed  "s/[[:space:]]*Location:[[:space:]]//" | grep '^/Applications\|^Users/.*/Applications' | grep "${App}" | head -n 1 )

if [ ! "${Path_To_App}" ]; then
    echo "App not found"
    exit 1
fi

echo "Deleting ${Path_To_App}"

rm -rf "${Path_To_App}"

exit $?  