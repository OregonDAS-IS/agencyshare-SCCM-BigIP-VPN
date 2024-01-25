<#
.SYNOPSIS
    Creates a new entry in user or system F5 configuration files to enable a new hostname
.PARAMETER Action
    Set Action to "monitor" or "remediate". Split into two actions to allow for monitoring of configration outside of remedation
.PARAMETER Run_As
    Set to specify if the file is being run as "user" or "system". Files exist for both the system and in local profiles.
.EXAMPLE
    .\F5-Reconfigure-Host.ps1 -action 'monitor' -ProfileName 'user'
    Monitors the configuration for users
.EXAMPLE
   .\F5-Reconfigure-Host.ps1 -action 'remediate' -ProfileName 'system'
    Reconfigures the configuration for the system
.DESCRIPTION
    This script will create an Always On VPN user or device tunnel on supported Windows 10 devices.
.NOTES
    Version:            1.0
    Creation Date:      March 29 2023
    Last Updated:       March 29 2023
    Special Note:       This script adapted from guidance originally published by Microsoft. 
    Author:             Daniel Zinck
    Organization:       DAS-IT
    Contact:            daniel.b.zinck@das.oregon.gov
#>



# //
# // set varibles used in config file to specify the hostname and alias that displays in the client
# //
$f5_vpn_hostname = "ra.oregon.gov"
$f5_vpn_alias = "Oregon Remote Access"


# //
# // function to check for the presence of the VPN hostname in a file
# //

function check_vpn_config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$fileName
    )

    # // Check to see if file exists
    if (-not(Test-Path -Path $fileName -PathType Leaf)) {
        Write-Warning "File does not exist - $fileName"
        return "no-file"
    }


    # // Check to see if hostname is present in file
    if (Select-String -Path $fileName -Pattern $f5_vpn_hostname -SimpleMatch -Quiet) {
        Write-Output "Configuration Exists - $fileName"
        return "configured"
    }
    else
    {
        Write-Warning "Configuration Missing - $fileName"
        return "missing"
    }
}


# //
# // function to modify user config. user settings are slightly different than system settings
# //
function modify_user_vpn_config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$fileName
    )
    $xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName);
    $xmlDoc.PROFILE.SERVERS | Foreach-Object {
        $newNode = $xmlDoc.CreateElement("SITEM")

        # // create ADDRESS value
        $newAddress = $xmlDoc.CreateElement("ADDRESS")
        $newAddress.InnerText = $f5_vpn_hostname
        $newNode.AppendChild($newAddress)

        # // create USER value
        $newUser = $xmlDoc.CreateElement("USER")
        $newNode.AppendChild($newUser)

        # // create ALIAS value
        $newAlias = $xmlDoc.CreateElement("ALIAS")
        $newAlias.InnerText = $f5_vpn_alias
        $newNode.AppendChild($newAlias)

        # // create ORIGIN value
        $newOrigin = $xmlDoc.CreateElement("ORIGIN")
        $newNode.AppendChild($newOrigin)

        # // create SSL_CERT_AUTOLOGIN value
        $newCertAutoLogin = $xmlDoc.CreateElement("SSL_CERT_AUTOLOGIN")
        $newCertAutoLogin.InnerText = '0'
        $newNode.AppendChild($newCertAutoLogin)

        # // create SSL_CERT_LOGIN_TO_WEBTOP value
        $newCertLoginWebTop = $xmlDoc.CreateElement("SSL_CERT_LOGIN_TO_WEBTOP")
        $newCertLoginWebTop.InnerText = '0'
        $newNode.AppendChild($newCertLoginWebTop)

        # // create PASSWORD value
        $newPassword = $xmlDoc.CreateElement("PASSWORD")
        $newNode.AppendChild($newPassword)

        # // create OPTIONAL_FIELD value
        $newOptional = $xmlDoc.CreateElement("OPTIONAL_FIELD")
        $newNode.AppendChild($newOptional)

        # // create SAVEPASSWORDS value
        $newSavePasswords = $xmlDoc.CreateElement("SAVEPASSWORDS")
        $newSavePasswords.InnerText = 'YES'
        $newNode.AppendChild($newSavePasswords)


        $_.PrependChild($newNode)
    }
    #// save the xml document
    Try{$xmlDoc.Save($fileName)} Catch {Write-Error "Unable to write to output file $fileName"; exit 1};
}


# //
# // function to modify system config. system settings are slightly different than system settings
# //
function modify_system_vpn_config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$fileName
    )
    $xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName);
    $xmlDoc.PROFILE.SERVERS | Foreach-Object {
        $newNode = $xmlDoc.CreateElement("SITEM")

        #create ADDRESS value
        $newAddress = $xmlDoc.CreateElement("ADDRESS")
        $newAddress.InnerText = $f5_vpn_hostname
        $newNode.AppendChild($newAddress)


        #create ALIAS value
        $newAlias = $xmlDoc.CreateElement("ALIAS")
        $newAlias.InnerText = $f5_vpn_alias
        $newNode.AppendChild($newAlias)

        #create SAVEPASSWORDS value
        $newSavePasswords = $xmlDoc.CreateElement("SAVEPASSWORDS")
        $newSavePasswords.InnerText = 'YES'
        $newNode.AppendChild($newSavePasswords)


        $_.PrependChild($newNode)
    }
    #// save the xml document
    Try{$xmlDoc.Save($fileName)} Catch {Write-Error "Unable to write to output file $fileName";exit 1};
}


# //
# // main f5_config function
# //

function set_f5_config {
[CmdletBinding()]
param(
        [Parameter(Mandatory, HelpMessage = 'Specify audit for prescence of configuration or to fix the configuration. Value can be "monitor" or "remediate" ')]
        [ValidateSet('monitor','remediate')]
        [string]$Action,

        [Parameter(Mandatory, HelpMessage = 'Enter to determin if this is running as a user or the system')]
        [ValidateSet('system','user')]
        [string]$Run_As
    )

# // check for the presence of the user configuration file.
if ($Run_As -eq "user"){
    $user_file_name = "$env:APPDATA\F5 Networks\VPN\client.f5c"
    $user_file_status = check_vpn_config -fileName $user_file_name 
        
    # // configuration present. no action required
    if($user_file_status -eq 'configured' -or $user_file_status -eq 'no-file') { write-host "Configuration Present or No File Present"; return 0}


    # // configuration missing. monitor mode set, no action required
    if($user_file_status -eq 'missing'  -and $Action -eq 'monitor') { write-host "Configuration Missing"; return 1}


    # // configuration missing. monitor mode set, no action required
    if($user_file_status -eq 'missing'  -and $Action -eq 'remediate') { 


    # // check to make sure f5 client isnt running. exit if running. F5 client will just override changes          
    $ProcessActive = Get-Process f5fpclientW -ErrorAction SilentlyContinue
    if($ProcessActive -ne $null)
        {
            Write-host "F5 VPN Process running - exiting script"
            return 1
        }
        
     # // modify user configuration
     try { 
        modify_user_vpn_config -fileName $user_file_name
        Write-Output "Fixing - $user_file_name"
        }
     catch {return "error"}
     }
}


    # //
    # // check for the presence of the system configuration files.
    # //
if ($Run_As -eq "system"){
    # // check for file in program files
    $programfiles_name = "${Env:ProgramFiles(x86)}\F5 VPN\config.f5c"
    $programfiles_name_status = check_vpn_config -fileName $programfiles_name

    # // check for file in programdata
    $programdata_name = "$env:ProgramData\F5 Networks\Secure Access Client\config.f5c"
    $programdata_name_status = check_vpn_config -fileName $programdata_name


     # // configuration present. no action required
     if($programfiles_name_status -eq 'configured' -and $programdata_name_status -eq 'configured') { write-host "Configuration Present"; return 0}


     # // configuration missing. monitor mode set, no action required
     if($programfiles_name_status -eq 'missing' -and $Action -eq 'monitor') { Write-Warning "Configuration Missing - $programfiles_name"; return 1}
     if($programdata_name_status -eq 'missing' -and $Action -eq 'monitor') { Write-Warning "Configuration Missing - $programdata_name"; return 1}


     # // configuration missing. action set to remediate
     if($programfiles_name_status -eq 'missing' -and $Action -eq 'remediate') {
        modify_system_vpn_config -fileName $programfiles_name
        Write-Output "Fixing - $programfiles_name"
        return 0
     }
        
     # // configuration missing. action set to remediate
     if($programdata_name_status -eq 'missing' -and $Action -eq 'remediate') {
        modify_system_vpn_config -fileName $programdata_name
        Write-Output "Fixing - $programdata_name"
        return 0
        }

     # // no configuration files present. no action required
     if($programfiles_name_status -eq 'no-file' -or $programdata_name_status -eq 'no-file') { Write-Warning "No File Present"; return 0}

 }
}

$output = set_f5_config -Action remediate -Run_As user

return $output