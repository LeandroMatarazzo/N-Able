#!/bin/sh



echo "Listing installed applications"

Path_To_App=$(system_profiler SPApplicationsDataType | sed  "s/[[:space:]]*Location:[[:space:]]//" | grep '^/Applications\|^Users/.*/Applications' | sed "s/.*\///")

if [ ! "${Path_To_App}" ]; then
    echo "No applications found"
    exit 1
fi

echo "${Path_To_App}"


exit 0 