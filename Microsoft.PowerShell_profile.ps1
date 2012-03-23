#Configuring for your environment
#   Home directory you want (d:\scratch)
#   Location of visual studion (C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC)
#    Note, the SP environment setup was based on script that SP runs from command prompt found 
#     on JHP machine here "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\CONFIG\POWERSHELL\Registration\SharePoint.ps1"


$defaultStartupDirectory = "c:\scratch"
$developerStartupDirectory = "c:\dev"
$sharePointStartupDirectory = "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14"
$localVisualStudioDirectory ="C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC"
$homeDirectory = "c:\users\john"
$gitBinPath ="C:\utils\Git\bin"

$startupDirectory = $defaultStartupDirectory

Remove-Variable -Force HOME
Set-Variable HOME $homeDirectory 

Function EnableGit {

    # Load posh-git module from current directory
    Import-Module $home\Documents\WindowsPowerShell\Modules\posh-git

    # If module is installed in a default location ($env:PSModulePath),
    # use this instead (see about_Modules for more information):
    # Import-Module posh-git

    Enable-GitColors

    Pop-Location

    Start-SshAgent -Quiet

}

Function EnableVisualStudio {
#Set environment variables for Visual Studio Command Prompt
# Info from here http://allen-mack.blogspot.com/2008/03/replace-visual-studio-command-prompt.html
    pushd $localVisualStudioDirectory 
    cmd /c “vcvarsall.bat&set” |
    foreach { 
        if ($_ -match “=”) 
        {    
            $v = $_.split(“=”); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
        }
    }
    popd
}

Function EnableSharePoint {
#Set environment variables for Visual Studio Command Prompt
# Info from here http://allen-mack.blogspot.com/2008/03/replace-visual-studio-command-prompt.html

    $a = Get-PSSnapin -registered | Select-String -pattern "Microsoft.SharePoint.PowerShell"

    if ($a -eq $null) {
        Write-Host "SharePoint is not presenet"
    }
    else {
        $ver = $host | select version
        if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
        Add-PsSnapin Microsoft.SharePoint.PowerShell

    }
}

Function Set-Prompt
{
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Default","EndUser","Developer","SharePoint","Admin")]
        $Action
    )


        if ($global:IsAdmin) {
             $GLOBAL:PromptTrail = "$"
        }
        else {
             $GLOBAL:PromptTrail = ">"
        }

}

Function Set-Titlebar
{
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Default","EndUser","Developer","SharePoint","Admin")]
        $Action
    )

     $adminMode = ''
     
     if ($global:IsAdmin) {
        $adminMode = " ADMINISTRATOR CREDENTIALS"
     }
     
    switch ($Action)
    {
        "Admin" {
           $computer = gc env:computername
           $host.ui.rawui.WindowTitle =  $computer + " [" + $CurrentUser.Name + "] Admin" + $adminMode
        
        }
        
        "EndUser"
        {
           $computer = gc env:computername
           $host.ui.rawui.WindowTitle =  $computer + " [" + $CurrentUser.Name + "] End User"+ $adminMode

        }
        "SharePoint"
        {
           $computer = gc env:computername
           $host.ui.rawui.WindowTitle =  $computer + " [" + $CurrentUser.Name + "] SharePoint"+ $adminMode
        }
        "Developer"
        {
           $computer = gc env:computername
           $host.ui.rawui.WindowTitle =  $computer + " [" + $CurrentUser.Name + "] Developer"+ $adminMode

        }
        
        default
        {
            $host.ui.rawui.WindowTitle =  $host.ui.rawui.WindowTitle + $adminMode
        }
    }
}

Function Set-UI
{
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Default","EndUser","Developer","SharePoint","Admin")]
        $Action
    )

    switch ($Action)
    {
        "Admin" {
          
           Set-Prompt Admin
           Set-Titlebar Admin
           Set-ScreenColor Admin
        }
        
        "Developer"
        {
           Set-Prompt Developer
           Set-Titlebar Developer
           Set-ScreenColor Developer
        }
        
        "EndUser"
        {
           Set-Prompt EndUser
           Set-Titlebar EndUser
           Set-ScreenColor EndUser
        }
        
        "SharePoint"
        {
           Set-Prompt SharePoint
           Set-Titlebar SharePoint
           Set-ScreenColor SharePoint
        }
        
        default
        {
           Set-Prompt Default
           Set-Titlebar Default
           Set-ScreenColor Default
        }
    }
    Clear-Host
    Set-Location $home 
}

Function Set-Environment
{
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Default","EndUser","Developer","SharePoint","Admin")]
        $Action
    )

    switch ($Action)
    {
        "Admin" {
           $global:IsGitPrompt = $false
           $startupDirectory = $home
           Set-UI Admin
           EnableVisualStudio 
           EnableSharePoint
        }
        
        "EndUser"
        {
           $global:IsGitPrompt = $false
           $startupDirectory = $defaultStartupDirectory
           Set-UI EndUser
        }
        
        "Developer"
        {
           $global:IsGitPrompt = $true
           $startupDirectory = $developerStartupDirectory
           Set-UI Developer
           EnableVisualStudio 
           EnableGit

        }
        "SharePoint"
        {
           $global:IsGitPrompt = $false
           $startupDirectory = $sharePointStartupDirectory 
           Set-UI SharePoint
           EnableSharePoint
        }
        
        default
        {
           $global:IsGitPrompt = $false
           $startupDirectory = $defaultStartupDirectory
           Set-UI Default
        }
    }

    Set-Location $startupDirectory
}

Function Set-ScreenColor
{
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Default","EndUser","Developer","SharePoint","Admin")]
        $Action
    )
    
    switch ($Action)
    {
        "Admin" {
            (Get-Host).UI.RawUI.BackgroundColor = "darkred"
            (Get-Host).UI.RawUI.ForegroundColor = "white"
        }
        
        "EndUser"
        {
            (Get-Host).UI.RawUI.BackgroundColor = "darkmagenta"
            (Get-Host).UI.RawUI.ForegroundColor = "white"

        }
        "SharePoint"
        {
            (Get-Host).UI.RawUI.BackgroundColor = "darkgreen"
            (Get-Host).UI.RawUI.ForegroundColor = "white"
        }
        "Developer"
        {
            (Get-Host).UI.RawUI.BackgroundColor = "black"
            (Get-Host).UI.RawUI.ForegroundColor = "white"
        }
        
        default
        {
           Set-Prompt Default
           Set-Titlebar Default
        }
    }
}

Function Prompt
{
    if ( $global:IsGitPrompt) {
        $realLASTEXITCODE = $LASTEXITCODE

        # Reset color, which can be messed up by Enable-GitColors
        $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

        Write-Host($pwd ) -nonewline

        Write-VcsStatus

        $LASTEXITCODE = $realLASTEXITCODE
        return $GLOBAL:PromptTrail 
    }
    else {
        Write-Output $("PS "+ $(Get-Location) + $GLOBAL:PromptTrail + " ") #-NoNewline
     }



}



#Start script

$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()


[bool] $global:IsAdmin = $false
[bool] $global:IsGitPrompt = $false
$env:path += ";" + $gitBinPath 
Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

If($True -eq ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $global:IsAdmin = $true
    Set-Environment Admin
}
else {
      Set-Environment Default

}

    #Clear-Host
    if ($global:IsAdmin) {
        Write-Output ""
        Write-Output "CAUTION: PowerShell is running with administrator credentials!"
        Write-Output ""
        Write-Output ""
    }
    
Set-Location $startupDirectory

