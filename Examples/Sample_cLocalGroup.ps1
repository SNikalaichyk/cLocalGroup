
configuration Sample_cLocalGroup
{
    Import-DscResource -ModuleName cLocalGroup

    cLocalGroup LocalGroup1
    {
        Ensure = 'Present'
        GroupName = 'Group-1'
        Description = 'Created by the cLocalGroup DSC resource'
        Members = 'IIS APPPOOL\DefaultAppPool', 'NT AUTHORITY\IUSR'
    }

    cLocalGroup LocalGroup2
    {
        Ensure = 'Present'
        GroupName = 'Group-2'
        Description = 'Created by the cLocalGroup DSC resource'
        MembersToExclude = "$Env:UserDomain\Domain Users", 'Guest'
        MembersToInclude = "$Env:UserDomain\$Env:UserName", 'BUILTIN\Administrators'
    }
}

Sample_cLocalGroup -OutputPath "$Env:SystemDrive\Sample_cLocalGroup"

Start-DscConfiguration -Path "$Env:SystemDrive\Sample_cLocalGroup" -Force -Verbose -Wait

Get-DscConfiguration

