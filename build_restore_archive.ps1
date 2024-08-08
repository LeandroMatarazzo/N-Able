
#Usage : give path to agent as argument

#create and populate a new folder
mkdir $PSScriptRoot/res
Copy-Item $PSScriptRoot/restore_src/* $PSScriptRoot/res
Copy-Item "$args[0]" $PSScriptRoot/res/Agent.exe 
#archive the folder
tar -czvf $PSScriptRoot/archive.tar.gz $PSScriptRoot/res
#delete the new folder
Remove-Item -r -force res
