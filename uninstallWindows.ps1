Param(
    [switch]$ListApp,
    [string]$uninstall
    
)

#App list code from https://xkln.net/blog/please-stop-using-win32product-to-find-installed-software-alternatives-inside/
function Get-InstalledApplications() {
    [cmdletbinding(DefaultParameterSetName = 'GlobalAndAllUsers')]

    Param (
        [Parameter(ParameterSetName="Global")]
        [switch]$Global,
        [Parameter(ParameterSetName="GlobalAndCurrentUser")]
        [switch]$GlobalAndCurrentUser,
        [Parameter(ParameterSetName="GlobalAndAllUsers")]
        [switch]$GlobalAndAllUsers,
        [Parameter(ParameterSetName="CurrentUser")]
        [switch]$CurrentUser,
        [Parameter(ParameterSetName="AllUsers")]
        [switch]$AllUsers
    )

    # Excplicitly set default param to True if used to allow conditionals to work
    if ($PSCmdlet.ParameterSetName -eq "GlobalAndAllUsers") {
        $GlobalAndAllUsers = $true
    }

    # Check if running with Administrative privileges if required
    if ($GlobalAndAllUsers -or $AllUsers) {
        $RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($RunningAsAdmin -eq $false) {
            Write-Error "Finding all user applications requires administrative privileges"
            break
        }
    }

    # Empty array to store applications
    $Apps = @()
    $32BitPath = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $64BitPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    # Retreive globally insatlled applications
    if ($Global -or $GlobalAndAllUsers -or $GlobalAndCurrentUser) {
        Write-Host "Processing global hive"
        $Apps += Get-ItemProperty "HKLM:\$32BitPath"
        $Apps += Get-ItemProperty "HKLM:\$64BitPath"
    }

    if ($CurrentUser -or $GlobalAndCurrentUser) {
        Write-Host "Processing current user hive"
        $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$32BitPath"
        $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$64BitPath"
    }

    if ($AllUsers -or $GlobalAndAllUsers) {
        Write-Host "Collecting hive data for all users"
        $AllProfiles = Get-CimInstance Win32_UserProfile | Select LocalPath, SID, Loaded, Special | Where {$_.SID -like "S-1-5-21-*"}
        $MountedProfiles = $AllProfiles | Where {$_.Loaded -eq $true}
        $UnmountedProfiles = $AllProfiles | Where {$_.Loaded -eq $false}

        Write-Host "Processing mounted hives"
        $MountedProfiles | % {
            $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$32BitPath"
            $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$64BitPath"
        }

        Write-Host "Processing unmounted hives"
        $UnmountedProfiles | % {

            $Hive = "$($_.LocalPath)\NTUSER.DAT"
            Write-Host " -> Mounting hive at $Hive"

            if (Test-Path $Hive) {
            
                REG LOAD HKU\temp $Hive

                $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$32BitPath"
                $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$64BitPath"

                # Run manual GC to allow hive to be unmounted
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            
                REG UNLOAD HKU\temp

            } else {
                Write-Warning "Unable to access registry hive at $Hive"
            }
        }
    }


    #write-Output $Apps

    #extract relevent information
    $AppDetail = ""
    $Name = ""
     foreach ($lines in $Apps){
        if (-not [string]::IsNullOrEmpty($lines.DisplayName)){

            
            $AppDetail = $lines.DisplayName + "`n"
        
            $AppDetail += "install source : " 
            $AppDetail +=  $lines.InstallSource
            $AppDetail += "`n"
        

            $AppDetail += "install location : " 
            $AppDetail += $lines.InstallLocation
            $AppDetail += "`n"
        

            $AppDetail += "uninstall string : " 
            $AppDetail +=  $lines.UninstallString
            $AppDetail += "`n"

            $AppDetail += "quiet uninstall string : "
            $AppDetail += $lines.QuietUninstallString
            $AppDetail += "`n"

            $AppDetail += Get-Uninstallmethod($lines)
            $AppDetail += "`n"
            if ($ListApp){
                write-Output $AppDetail
            }
        }
        
        
    }
    
}

function MsiUninstall($MsiString){
    #we change the form of the uninstall string so it works

    $MsiString = $MsiString -replace "/I", "/X"
    $MsiString += " /quiet REBOOT=ReallySuppress"

    Start-Process -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/c $MsiString" 
}

function QuietUninstall($QuietString){
    Start-Process -NoNewWindow -FilePath "cmd.exe" -ArgumentList $QuietString
}

function FileRemove($DirPath){
    rm $DirPath -r -fo
}

function Get-Uninstallmethod($detail){
    if (-not [string]::IsNullOrEmpty($detail.QuietUninstallString)){
        if($detail.DisplayName -match $uninstall -And $uninstall){
            QuietUninstall($detail.QuietUninstallString)
        }
        return "Quiet"
    }
    elseif ($detail -match "MsiExec"){
        if($detail.DisplayName -match $uninstall -And $uninstall){
            MsiUninstall($detail.UninstallString)
        }
        return "Msi"
    }
    elseif(-not [string]::IsNullOrEmpty($detail.InstallLocation)) {
        if($detail.DisplayName -match $uninstall -And $uninstall){
            FileRemove($detail.InstallLocation)
        }
        return "Remove file"
    }
    else {
        if($detail.DisplayName -match $uninstall -And $uninstall){
            Write-Error "No method found to uninstall"
            exit 1
        }
        return "No method"
    }
}

Get-InstalledApplications