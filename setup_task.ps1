# Verify \IT\ exist
if (!(Test-Path "C:\IT\")) {mkdir "C:\IT\"} 

# Move the files
if (Test-Path "C:\archive.tar.gz") {
   Move-Item "C:\archive.tar.gz" "C:\IT\archive.tar.gz"
   tar -xvzf "C:\IT\archive.tar.gz" -C "C:\IT\"
   Remove-Item "C:\IT\archive.tar.gz"
} else {
    Write-Output "File absent"
    exit 1
}

# Create the task
schtasks /Create /xml "C:\IT\restore\Restore_Ncentral.xml" /tn Restore_Ncentral

